import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/surah.dart';
import '../services/notification_service.dart';
import '../services/foreground_service.dart';
import 'content_provider.dart';

// Conditional imports for native platforms
import 'download_provider_stub.dart'
    if (dart.library.io) 'download_provider_io.dart';

class DownloadItem {
  final String surahId;
  final String localPath;
  final double progress;
  final bool isCompleted;
  final bool isPaused;
  final bool isPreparing;
  final int downloadedBytes;
  final double speed; // KB/s
  final String? url;
  final String? category;
  final String? surahName;

  DownloadItem({
    required this.surahId,
    required this.localPath,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isPaused = false,
    this.isPreparing = false,
    this.downloadedBytes = 0,
    this.speed = 0.0,
    this.url,
    this.category,
    this.surahName,
  });

  Map<String, dynamic> toMap() {
    return {
      'surahId': surahId,
      'localPath': localPath,
      'isCompleted': isCompleted,
      'isPaused': isPaused,
      'isPreparing': isPreparing,
      'progress': progress,
      'downloadedBytes': downloadedBytes,
      'url': url,
      'category': category,
      'surahName': surahName,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      surahId: map['surahId'],
      localPath: map['localPath'],
      isCompleted: map['isCompleted'] ?? false,
      isPaused: map['isPaused'] ?? false,
      isPreparing: map['isPreparing'] ?? false,
      progress: (map['progress'] ?? 0.0).toDouble(),
      downloadedBytes: map['downloadedBytes'] ?? 0,
      url: map['url'],
      category: map['category'],
      surahName: map['surahName'],
    );
  }

  DownloadItem copyWith({
    double? progress,
    bool? isCompleted,
    bool? isPaused,
    bool? isPreparing,
    int? downloadedBytes,
    double? speed,
    String? url,
    String? category,
    String? eta,
    String? surahName,
    String? localPath,
  }) {
    return DownloadItem(
      surahId: surahId,
      localPath: localPath ?? this.localPath,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isPaused: isPaused ?? this.isPaused,
      isPreparing: isPreparing ?? this.isPreparing,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speed: speed ?? this.speed,
      url: url ?? this.url,
      category: category ?? this.category,
      surahName: surahName ?? this.surahName,
    );
  }
}

class DownloadIsolateArgs {
  final String url;
  final String localPath;
  final int startBytes;
  final SendPort sendPort;

  DownloadIsolateArgs({
    required this.url,
    required this.localPath,
    required this.startBytes,
    required this.sendPort,
  });
}

void _downloadIsolateTask(DownloadIsolateArgs args) async {
  final receivePort = ReceivePort();
  args.sendPort.send({'type': 'init', 'sendPort': receivePort.sendPort});

  final cancelToken = CancelToken();
  receivePort.listen((message) {
    if (message == 'cancel') {
      cancelToken.cancel();
      receivePort.close();
    }
  });

  try {    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.receiveDataWhenStatusError = true;

    final headers = <String, dynamic>{};
    if (args.startBytes > 0) {
      headers['range'] = 'bytes=${args.startBytes}-';
    }

    final response = await dio.get<ResponseBody>(
      args.url,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );

    final String? contentRange = response.headers.value('content-range');
    int realTotal = -1;
    if (contentRange != null && contentRange.contains('/')) {
      final parts = contentRange.split('/');
      if (parts.length == 2) realTotal = int.tryParse(parts[1]) ?? -1;
    } else {
      realTotal = int.tryParse(response.headers.value('content-length') ?? '-1') ?? -1;
      if (args.startBytes > 0 && realTotal != -1) {
        realTotal += args.startBytes;
      }
    }

    final file = File(args.localPath);
    // Use append mode if we have startBytes, otherwise write
    IOSink sink = file.openWrite(mode: args.startBytes > 0 ? FileMode.append : FileMode.write);
    int currentReceived = args.startBytes;
    
    DateTime lastTime = DateTime.now();
    int lastReceived = 0;

    await for (final chunk in (response.data as ResponseBody).stream) {
      sink.add(chunk);
      currentReceived += chunk.length;

      final now = DateTime.now();
      final diff = now.difference(lastTime).inMilliseconds;

      // Throttle isolate messages to 500ms to reduce overhead
      if (diff >= 500) {
        final bytesInSec = currentReceived - lastReceived - (lastReceived == 0 ? args.startBytes : 0);
        double speedBps = bytesInSec / (diff / 1000);
        double speedKBps = speedBps / 1024;
        
        lastTime = now;
        lastReceived = currentReceived - args.startBytes;

        args.sendPort.send({
          'type': 'progress',
          'currentReceived': currentReceived,
          'realTotal': realTotal,
          'speedKBps': speedKBps,
        });
      }
    }
    await sink.flush();
    await sink.close();
    args.sendPort.send({'type': 'done'});
  } catch (e) {
    final isCancel = e is DioException && CancelToken.isCancel(e);
    args.sendPort.send({'type': 'error', 'error': e.toString(), 'isCancel': isCancel});
  } finally {
    receivePort.close();
  }
}

class GlobalDownloadState {
  final Map<String, DownloadItem> items;
  final double currentSpeed; // KB/s
  final int totalInQueue;
  final int remainingInQueue;
  final bool isPausedAll;
  final String globalEta;
  final bool isInitialLoad;

  GlobalDownloadState({
    required this.items,
    this.currentSpeed = 0.0,
    this.totalInQueue = 0,
    this.remainingInQueue = 0,
    this.isPausedAll = false,
    this.globalEta = '',
    this.isInitialLoad = true,
  });

  GlobalDownloadState copyWith({
    Map<String, DownloadItem>? items,
    double? currentSpeed,
    int? totalInQueue,
    int? remainingInQueue,
    bool? isPausedAll,
    String? globalEta,
    bool? isInitialLoad,
  }) {
    return GlobalDownloadState(
      items: items ?? this.items,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      totalInQueue: totalInQueue ?? this.totalInQueue,
      remainingInQueue: remainingInQueue ?? this.remainingInQueue,
      isPausedAll: isPausedAll ?? this.isPausedAll,
      globalEta: globalEta ?? this.globalEta,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }
}

class DownloadNotifier extends StateNotifier<GlobalDownloadState> {
  static const _key = '@quran_downloads';
  final Dio _dio = Dio();
  final Map<String, CancelToken> _tokens = {};
  
  // Stream for real-time UI updates
  final _progressController = StreamController<GlobalDownloadState>.broadcast();
  Stream<GlobalDownloadState> get progressStream => _progressController.stream;

  // For Throttling Updates
  DateTime? _lastNotificationTime;
  DateTime? _lastUiUpdateTime;

  final List<Map<String, dynamic>> _queue = [];
  bool _isProcessingQueue = false;

  DownloadNotifier(Ref ref) : super(GlobalDownloadState(items: {})) {
    _load();
    _initForegroundTask();
    _listenToForegroundData();
    
    _dio.options.receiveTimeout = const Duration(minutes: 15);
    _dio.options.sendTimeout = const Duration(minutes: 15);
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 5;
    _dio.options.validateStatus = (status) => status != null && status < 500;
    _dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Connection': 'keep-alive',
      'Accept-Encoding': 'identity',
    };
  }

  void _listenToForegroundData() {
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data == 'stop_all_downloads') {
        clearAllDownloads();
      }
    });
  }

  Future<void> _initForegroundTask() async {
    if (kIsWeb || !Platform.isAndroid) return;

    // --- START: FIX FOR SYSTEM NOTIFICATION MESSAGE ---
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'download_channel_v4',
        channelName: 'Download Service',
        channelDescription: 'Maintains downloads in the background',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.HIGH,
        onlyAlertOnce: true,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        stopWithTask: true, // يضمن تنظيف الإشعار عند إغلاق التطبيق
      ),
    );
    // --- END: FIX ---
  }

  Future<void> _startForegroundService({String? title, String? text}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        serviceId: 888,
        notificationTitle: title ?? 'جاري تحميل السورة...',
        notificationText: text ?? 'جاري البدء...',
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.pravera.flutter_foreground_task.notification_icon',
        ),
        notificationButtons: [
          const NotificationButton(id: 'stop_download', text: 'إلغاء'),
        ],
        callback: startCallback,
      );
    }
  }

  Future<void> _stopForegroundService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  void updateForegroundNotification({required String title, required String text}) {
    if (kIsWeb || !Platform.isAndroid) return;
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.pravera.flutter_foreground_task.notification_icon',
      ),
      notificationButtons: [
        const NotificationButton(id: 'stop_download', text: 'إلغاء'),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _resolveSurahName(String id) {
    try {
      return surahList.firstWhere((s) => s.id == id).name;
    } catch (_) {
      return "تلاوة";
    }
  }

  void _requestBatteryOptimizationExclusion() {
    // handled by WakelockPlus.enable()
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final Map<String, DownloadItem> items = {};
      bool migrated = false;

      for (var entry in decoded.entries) {
        var item = DownloadItem.fromMap(entry.value);
        
        // Migration to new folder structure
        if (!kIsWeb && item.isCompleted && !item.localPath.contains('Hamza_Medbouh')) {
          final oldFile = File(item.localPath);
          if (await oldFile.exists()) {
            final newPath = await resolveLocalPath(item.surahId, item.category ?? 'تلاوات متنوعة', surahName: item.surahName);
            try {
              await oldFile.rename(newPath);
              item = item.copyWith(localPath: newPath);
              migrated = true;
            } catch (_) {
              // Ignore rename errors
            }
          }
        }
        items[entry.key] = item;
      }

      state = state.copyWith(items: items, isInitialLoad: false);
      if (migrated) _save();
    } else {
      state = state.copyWith(isInitialLoad: false);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.items.map((key, value) => MapEntry(key, value.toMap())));
    await prefs.setString(_key, data);
  }

  Future<void> downloadSurah(String surahId, String url, {String? surahName, String? category, String? lrcUrl, Function(String)? onComplete}) async {
    // Smart guard: only skip if the file actually exists on disk.
    // If the user deleted the file, allow re-downloading even if isCompleted was true.
    final existingCompleted = state.items[surahId];
    if (existingCompleted?.isCompleted ?? false) {
      final lp = existingCompleted!.localPath;
      if (lp.isNotEmpty && await File(lp).exists()) return; // file intact
      // File was deleted — reset and fall through to re-download
      final resetItems = {...state.items};
      resetItems[surahId] = existingCompleted.copyWith(
          isCompleted: false, progress: 0.0, isPaused: false);
      state = state.copyWith(items: resetItems);
      _save();
    }

    // --- START: FIX FOR UNDEFINED updatedItems ---
    final actualCategory = category ?? state.items[surahId]?.category ?? 'تلاوات متنوعة';
    final activeSurahName = surahName ?? state.items[surahId]?.surahName ?? _resolveSurahName(surahId);
    // --- END: FIX ---

    // Provide instant visual feedback before doing disk checks
    if (!kIsWeb) {
      final instantItems = {...state.items};
      instantItems[surahId] = DownloadItem(
        surahId: surahId, localPath: '', progress: 0.0, isPreparing: true, url: url, category: actualCategory, surahName: activeSurahName
      );
      state = state.copyWith(items: instantItems);
      _progressController.add(state); // INSTANT FEEDBACK
    }

    if (kIsWeb) {
      final updatedItems = {...state.items};
      updatedItems[surahId] = DownloadItem(
        surahId: surahId,
        localPath: url,
        isCompleted: true,
        url: url,
        category: actualCategory,
        surahName: activeSurahName,
      );
      state = state.copyWith(items: updatedItems);
      _save();
      if (onComplete != null) onComplete(surahId);
      return;
    }

    // Offload the rest of the preparation to avoid freezing the UI thread
    Future.microtask(() async {
      final localPath = await resolveLocalPath(surahId, actualCategory, surahName: activeSurahName);

      final updatedItems = {...state.items};
      // FIX: always pass localPath so File('') is never used
      updatedItems[surahId] = updatedItems[surahId]?.copyWith(
        isPaused: false,
        isPreparing: false,
        isCompleted: false,   // Always reset so re-downloads work
        progress: 0.0,        // Reset progress for clean restart
        url: url,
        category: actualCategory,
        surahName: activeSurahName,
        localPath: localPath,
      ) ?? DownloadItem(
        surahId: surahId,
        localPath: localPath,
        progress: 0.0,
        isPreparing: false,
        url: url,
        category: actualCategory,
        surahName: activeSurahName,
      );

      int total = state.totalInQueue;
      int remaining = state.remainingInQueue;
      if (!_isProcessingQueue) {
        total++;
        remaining++;
      } else if (_isProcessingQueue && total == 0) {
        total = 1;
        remaining = 1;
      } else {
        total++;
        remaining++;
      }
      
      state = state.copyWith(items: updatedItems, totalInQueue: total, remainingInQueue: remaining);
      _save();

      _queue.add({
        'surahId': surahId,
        'url': url,
        'surahName': activeSurahName,
        'category': actualCategory,
        'lrcUrl': lrcUrl,
        'onComplete': onComplete,
      });

      _processQueue();
    });
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_queue.isNotEmpty && !state.isPausedAll) {
        final req = _queue.first;
        final surahId = req['surahId'];

        if (state.items[surahId]?.isPaused ?? false) {
          _queue.removeAt(0);
          continue;
        }
        if (state.items[surahId]?.isCompleted ?? false) {
          _queue.removeAt(0);
          continue;
        }

        try {
          await _performDownload(
            surahId: surahId,
            url: req['url'],
            activeSurahName: req['surahName'],
            actualCategory: req['category'],
            onComplete: req['onComplete'],
          );
        } catch (e) {
          // Safety net: mark item as paused on unexpected error
          final items = {...state.items};
          if (items.containsKey(surahId)) {
            items[surahId] = items[surahId]!.copyWith(isPaused: true, speed: 0);
            state = state.copyWith(items: items);
            _save();
          }
        }

        if (_queue.isNotEmpty) {
          _queue.removeAt(0);
        }
      }
    } finally {
      // Always reset so future downloads can start
      _isProcessingQueue = false;

      if (_queue.isEmpty || state.isPausedAll) {
        state = state.copyWith(totalInQueue: 0, remainingInQueue: 0, currentSpeed: 0.0, globalEta: '');
        _stopForegroundService();
        WakelockPlus.disable();
        NotificationService.cancel(NotificationService.activeDownloadId);
        NotificationService.cancel(889); // Always clear the progress bar notification
      }
    }
  }

  Future<void> _performDownload({
    required String surahId,
    required String url,
    required String activeSurahName,
    required String actualCategory,
    Function(String)? onComplete,
  }) async {
    final localPath = state.items[surahId]!.localPath;
    final file = File(localPath);

    int startBytes = 0;
    if (await file.exists()) {
      startBytes = await file.length();
    }

    final token = CancelToken();
    _tokens[surahId] = token;

    _lastNotificationTime = null;
    _lastUiUpdateTime = null;

    final int initRemaining = state.remainingInQueue;
    final int initTotal = state.totalInQueue;

    // Do not await to avoid delaying the download isolate
    _startForegroundService(
      title: "تحميل ($initRemaining/$initTotal) - $activeSurahName", 
      text: "جاري البدء..."
    );

    WakelockPlus.enable();
    _requestBatteryOptimizationExclusion();

    int retryCount = 0;
    const int maxRetries = 10;

    while (retryCount < maxRetries) {
      if (state.items[surahId]?.isPaused ?? false) break;
      if (state.isPausedAll) break;

      try {
        final receivePort = ReceivePort();
        final isolate = await Isolate.spawn(_downloadIsolateTask, DownloadIsolateArgs(
          url: url,
          localPath: localPath,
          startBytes: startBytes,
          sendPort: receivePort.sendPort,
        ));

        SendPort? isolateSendPort;
        final completer = Completer<bool>();

        // Link main isolate cancellation to background isolate
        bool isCancelledLocally = false;
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (token.isCancelled) {
            isCancelledLocally = true;
            isolateSendPort?.send('cancel');
            timer.cancel();
          }
          if (completer.isCompleted) timer.cancel();
        });

        receivePort.listen((message) {
          if (message is Map) {
            final type = message['type'];
            if (type == 'init') {
              isolateSendPort = message['sendPort'];
            } else if (type == 'progress') {
              final currentReceived = message['currentReceived'] as int;
              final realTotal = message['realTotal'] as int;
              final speedKBps = message['speedKBps'] as double;

              final now = DateTime.now();
              if (_lastUiUpdateTime == null || now.difference(_lastUiUpdateTime!).inMilliseconds > 300) {
                _lastUiUpdateTime = now;
                String etaStr = "";
                if (speedKBps > 0 && realTotal != -1) {
                  final remaining = realTotal - currentReceived;
                  final etaSeconds = (remaining / (speedKBps * 1024)).round();
                  etaStr = _formatDuration(Duration(seconds: etaSeconds));
                }

                final progress = realTotal != -1 ? (currentReceived / realTotal).clamp(0.0, 1.0) : 0.0;
                
                final upItems = {...state.items};
                if (upItems.containsKey(surahId)) {
                  upItems[surahId] = upItems[surahId]!.copyWith(
                    progress: progress,
                    downloadedBytes: currentReceived,
                    speed: speedKBps,
                  );
                  
                  state = state.copyWith(
                    items: upItems,
                    currentSpeed: speedKBps,
                    globalEta: etaStr,
                  );
                  _progressController.add(state);
                }

                if (_lastNotificationTime == null || now.difference(_lastNotificationTime!).inMilliseconds > 800) {
                  _lastNotificationTime = now;
                  final String speedText = speedKBps > 1024
                      ? "${(speedKBps / 1024).toStringAsFixed(2)} MB/s"
                      : "${speedKBps.toStringAsFixed(1)} KB/s";
                  final int remainingCount = state.remainingInQueue;
                  final int totalCount = state.totalInQueue;
                  final int progressPercent = (progress * 100).toInt();
                  final String notifTitle = "⬇ تحميل الملف $remainingCount من $totalCount";
                  final String notifBody = "$activeSurahName  •  $progressPercent%  •  $speedText";

                  // Foreground service notification (keeps download alive)
                  updateForegroundNotification(
                    title: notifTitle,
                    text: notifBody,
                  );

                  // Separate rich progress-bar notification
                  NotificationService.showDownloadProgress(
                    id: 889,
                    title: notifTitle,
                    body: notifBody,
                    progress: progressPercent,
                    maxProgress: 100,
                  );
                }
              }
            } else if (type == 'done') {
               if (!completer.isCompleted) completer.complete(true);
            } else if (type == 'error') {
               final errorStr = message['error'] as String;
               final isCancel = message['isCancel'] as bool;
               if (!completer.isCompleted) {
                 if (isCancel || isCancelledLocally) {
                   completer.completeError(DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.cancel));
                 } else {
                   completer.completeError(Exception(errorStr));
                 }
               }
            }
          }
        });

        await completer.future;
        receivePort.close();
        isolate.kill();

        await writeAudioMetadata(
          localPath,
          title: activeSurahName,
          artist: "القارئ حمزة مدبوح",
          album: actualCategory,
        );

        final finalItems = {...state.items};
        finalItems[surahId] = finalItems[surahId]!.copyWith(progress: 1.0, isCompleted: true, isPaused: false, speed: 0);
        int remaining = state.remainingInQueue > 0 ? state.remainingInQueue - 1 : 0;
        
        state = state.copyWith(
          items: finalItems, 
          currentSpeed: 0.0, 
          globalEta: '',
          remainingInQueue: remaining,
        );
        
        _progressController.add(state);
        _tokens.remove(surahId);
        _save();

        NotificationService.showDownloadComplete(
          id: surahId.hashCode.abs(),
          title: "تم اكتمال التحميل",
          body: "تم تحميل: $activeSurahName بنجاح",
          payload: "play_$surahId",
          syncType: 'lrc', // Default to LRC, can be enhanced later based on surah metadata
        );
        // Cancel the progress bar notification for THIS download immediately
        NotificationService.cancel(889);

        if (onComplete != null) onComplete(surahId);
        break;

      } catch (e) {
        // Safe cancel check — no force-cast
        final isCancelError = (e is DioException && CancelToken.isCancel(e))
            || (e is DioException && e.type == DioExceptionType.cancel);
        if (isCancelError) break;
        retryCount++;
        if (retryCount >= maxRetries) {
          final items = {...state.items};
          if (items.containsKey(surahId)) {
            items[surahId] = items[surahId]!.copyWith(isPaused: true, speed: 0);
          }
          state = state.copyWith(items: items, currentSpeed: 0.0);
          _save();
          break;
        }
        // Exponential back-off capped at 10s
        await Future.delayed(Duration(seconds: (2 * retryCount).clamp(1, 10)));
        if (await file.exists()) startBytes = await file.length();
      }
    }
  }

  void cancelDownload(String surahId) {
    _queue.removeWhere((item) => item['surahId'] == surahId);
    _tokens[surahId]?.cancel("Cancelled by user");
    _tokens.remove(surahId);
    final updatedItems = {...state.items};
    if (updatedItems.containsKey(surahId)) {
      final item = updatedItems[surahId]!;
      deleteLocalFile(item.localPath);
      updatedItems.remove(surahId);
      int remaining = state.remainingInQueue > 0 ? state.remainingInQueue - 1 : 0;
      state = state.copyWith(items: updatedItems, remainingInQueue: remaining);
      _progressController.add(state);
      _save();
    }
  }

  Future<void> restartDownload(String surahId, String url, {String? surahName, String? category}) async {
    _tokens[surahId]?.cancel();
    _tokens.remove(surahId);
    final item = state.items[surahId];
    if (item != null) {
      await deleteLocalFile(item.localPath);
      final updatedItems = {...state.items};
      updatedItems[surahId] = item.copyWith(progress: 0, downloadedBytes: 0, isCompleted: false, isPaused: false, speed: 0);
      state = state.copyWith(items: updatedItems);
      downloadSurah(surahId, url, surahName: surahName, category: category);
    }
  }

  Future<void> downloadAll(List<Surah> surahs, {String? category}) async {
    final toDownload = surahs.where((s) => !(state.items[s.id]?.isCompleted ?? false)).toList();
    if (toDownload.isEmpty) return;

    state = state.copyWith(
      totalInQueue: state.totalInQueue + toDownload.length,
      remainingInQueue: state.remainingInQueue + toDownload.length,
      isPausedAll: false,
    );

    for (var surah in toDownload) {
      final actualCategory = category == 'General' ? 'تلاوات متنوعة' : (category ?? 'تلاوات متنوعة');
      final activeSurahName = surah.name;
      final localPath = await resolveLocalPath(surah.id, actualCategory, surahName: activeSurahName);
      
      final updatedItems = {...state.items};
      // FIX: always pass localPath + reset isCompleted so re-downloads work
      updatedItems[surah.id] = updatedItems[surah.id]?.copyWith(
        isPaused: false,
        isCompleted: false,   // reset
        progress: 0.0,        // reset
        url: surah.url,
        category: actualCategory,
        surahName: activeSurahName,
        localPath: localPath,
      ) ?? DownloadItem(
        surahId: surah.id,
        localPath: localPath,
        progress: 0.0,
        url: surah.url,
        category: actualCategory,
        surahName: activeSurahName,
      );
      state = state.copyWith(items: updatedItems);
      
      _queue.add({
        'surahId': surah.id,
        'url': surah.url,
        'surahName': activeSurahName,
        'category': actualCategory,
        'lrcUrl': surah.lrcUrl,
        'onComplete': null,
      });
    }
    _save();
    _processQueue();
  }

  void pauseAllDownloads() {
    state = state.copyWith(isPausedAll: true, currentSpeed: 0.0);
    _isProcessingQueue = false;
    for (var token in _tokens.values) {
      if (!token.isCancelled) token.cancel("Paused by user");
    }
    _tokens.clear();
    final updatedItems = {...state.items};
    int pausedCount = 0;
    for (var key in updatedItems.keys) {
      if (!updatedItems[key]!.isCompleted) {
        updatedItems[key] = updatedItems[key]!.copyWith(isPaused: true);
        pausedCount++;
      }
    }
    state = state.copyWith(items: updatedItems, remainingInQueue: pausedCount, totalInQueue: pausedCount);
    _save();

    if (pausedCount > 0) {
      updateForegroundNotification(
        title: "توقف مؤقت..",
        text: "متبقي $pausedCount ملفات",
      );
    }
  }

  void resumeAllDownloads(List<Surah> allSurahs) {
    final updatedItems = {...state.items};
    bool foundPaused = false;
    for (var key in updatedItems.keys) {
      if (!updatedItems[key]!.isCompleted && updatedItems[key]!.isPaused) {
        updatedItems[key] = updatedItems[key]!.copyWith(isPaused: false);
        foundPaused = true;
      }
    }
    if (!foundPaused) return;
    state = state.copyWith(items: updatedItems, isPausedAll: false);
    _save();
    final toResume = allSurahs.where((s) => state.items.containsKey(s.id) && !state.items[s.id]!.isCompleted).toList();
    if (toResume.isNotEmpty) downloadAll(toResume);
  }

  void pauseDownload(String surahId) {
    _tokens[surahId]?.cancel();
    _tokens.remove(surahId);
    if (state.items.containsKey(surahId)) {
      final items = {...state.items};
      items[surahId] = items[surahId]!.copyWith(isPaused: true, speed: 0);
      state = state.copyWith(items: items, currentSpeed: 0.0);
      _progressController.add(state);
      _save();

      final active = activeDownload;
      if (active == null) {
        final remaining = items.values.where((i) => !i.isCompleted).length;
        if (remaining > 0) {
          updateForegroundNotification(
            title: "توقف مؤقت..",
            text: "متبقي $remaining ملفات",
          );
        }
      }
    }
  }

  void resumeDownload(String surahId, String url, {Function(String)? onComplete}) {
    if (state.items.containsKey(surahId)) {
      final items = {...state.items};
      items[surahId] = items[surahId]!.copyWith(isPaused: false);
      state = state.copyWith(items: items);
      downloadSurah(surahId, url, onComplete: onComplete);
    }
  }

  Future<void> deleteDownloadedSurah(String surahId) async {
    final item = state.items[surahId];
    if (item != null) {
      if (!kIsWeb) {
        await deleteLocalFile(item.localPath);
        final lrcPath = item.localPath.replaceAll('.mp3', '.lrc');
        await deleteLocalFile(lrcPath);
      }
      final items = {...state.items};
      items.remove(surahId);
      state = state.copyWith(items: items);
      _save();
    }
  }

  Future<void> clearAllDownloads() async {
    _queue.clear();
    pauseAllDownloads();
    for (var item in state.items.values) {
      if (!kIsWeb) {
        await deleteLocalFile(item.localPath);
        final lrcPath = item.localPath.replaceAll('.mp3', '.lrc');
        await deleteLocalFile(lrcPath);
      }
    }
    state = state.copyWith(items: {}, totalInQueue: 0, remainingInQueue: 0);
    _save();
  }

  DownloadItem? get activeDownload {
    try {
      return state.items.values.firstWhere((item) => !item.isCompleted && !item.isPaused);
    } catch (_) {
      return null;
    }
  }

  String resolveSurahName(String id) {
    final quranMatch = surahList.where((s) => s.id == id).firstOrNull;
    if (quranMatch != null) return quranMatch.name;
    try {
      if (id.contains('_')) {
        final parts = id.split('_');
        return parts.last;
      }
    } catch (_) {}
    return "مقطع صوتي";
  }

  Future<void> refresh() async {
    if (kIsWeb) return;
    final items = {...state.items};
    bool changed = false;
    for (var entry in items.entries) {
      final item = entry.value;
      final file = File(item.localPath);
      final exists = await file.exists();
      if (exists) {
        final size = await file.length();
        if (size > 1024 * 5 && !item.isCompleted) {
          items[entry.key] = item.copyWith(isCompleted: true, progress: 1.0, downloadedBytes: size);
          changed = true;
        }
      } else {
        if (item.isCompleted) {
          items[entry.key] = item.copyWith(isCompleted: false, progress: 0.0, downloadedBytes: 0);
          changed = true;
        }
      }
    }
    if (changed) {
      state = state.copyWith(items: items);
      _save();
      _progressController.add(state);
    }
  }

  Future<void> requestUnrestrictedBattery() async {
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    }
  }

  Future<void> requestBatteryOptimizationExclusion() async {
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) await Permission.ignoreBatteryOptimizations.request();
    }
  }
}

final downloadProvider = StateNotifierProvider<DownloadNotifier, GlobalDownloadState>((ref) {
  return DownloadNotifier(ref);
});

final downloadProgressStreamProvider = StreamProvider<GlobalDownloadState>((ref) {
  return ref.watch(downloadProvider.notifier).progressStream;
});

final groupedDownloadsProvider = Provider<Map<String, List<Surah>>>((ref) {
  final downloads = ref.watch(downloadProvider);
  final content = ref.watch(contentProvider);
  final List<Surah> allPossibleSurahs = [
    ...surahList,
    ...content.telawat2026,
    ...content.telawat2025,
    ...content.telawat2024,
    ...content.telawat2023,
    ...content.telawat2022,
    ...content.telawat2020,
    ...content.telawat2018,
    ...content.azkar,
    ...content.doae,
    ...content.remoteGithubList,
    ...content.quranKareemRemote,
    ...content.githubList,
    ...content.youtubeRecitationsList,
  ];
  final List<Surah> allSurahs = allPossibleSurahs.where((s) => downloads.items.containsKey(s.id)).toList();
  for (var id in downloads.items.keys) {
    if (!allSurahs.any((s) => s.id == id)) {
      final item = downloads.items[id]!;
      allSurahs.add(Surah(
        id: id,
        name: item.surahName ?? item.surahId.split('_').last,
        url: item.url ?? '',
        estimatedDuration: Duration.zero,
        isMakki: true,
      ));
    }
  }
  allSurahs.sort((a, b) {
    final aComp = downloads.items[a.id]?.isCompleted ?? false;
    final bComp = downloads.items[b.id]?.isCompleted ?? false;
    if (aComp && !bComp) return 1;
    if (!aComp && bComp) return -1;
    return 0;
  });
  final Map<String, List<Surah>> groupedSurahs = {};
  for (var surah in allSurahs) {
    final item = downloads.items[surah.id];
    if (item != null) {
      final category = item.category ?? 'General';
      if (!groupedSurahs.containsKey(category)) groupedSurahs[category] = [];
      groupedSurahs[category]!.add(surah);
    }
  }
  return groupedSurahs;
});
