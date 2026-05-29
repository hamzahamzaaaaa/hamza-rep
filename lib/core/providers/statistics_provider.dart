import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsState {
  final int totalListeningSeconds;
  final Map<String, int> playCounts;
  
  final Map<String, int> hourlyListening; 
  final Map<String, int> dailyListening;  
  final Map<String, int> monthlyListening; 
  
  final int currentStreak;
  final int longestStreak;
  final String lastListeningDate;
  final List<String> unlockedBadges;

  StatisticsState({
    required this.totalListeningSeconds,
    required this.playCounts,
    this.hourlyListening = const {},
    this.dailyListening = const {},
    this.monthlyListening = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastListeningDate = '',
    this.unlockedBadges = const [],
  });

  StatisticsState copyWith({
    int? totalListeningSeconds,
    Map<String, int>? playCounts,
    Map<String, int>? hourlyListening,
    Map<String, int>? dailyListening,
    Map<String, int>? monthlyListening,
    int? currentStreak,
    int? longestStreak,
    String? lastListeningDate,
    List<String>? unlockedBadges,
  }) {
    return StatisticsState(
      totalListeningSeconds: totalListeningSeconds ?? this.totalListeningSeconds,
      playCounts: playCounts ?? this.playCounts,
      hourlyListening: hourlyListening ?? this.hourlyListening,
      dailyListening: dailyListening ?? this.dailyListening,
      monthlyListening: monthlyListening ?? this.monthlyListening,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastListeningDate: lastListeningDate ?? this.lastListeningDate,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalListeningSeconds': totalListeningSeconds,
      'playCounts': playCounts,
      'hourlyListening': hourlyListening,
      'dailyListening': dailyListening,
      'monthlyListening': monthlyListening,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastListeningDate': lastListeningDate,
      'unlockedBadges': unlockedBadges,
    };
  }

  factory StatisticsState.fromMap(Map<String, dynamic> map) {
    return StatisticsState(
      totalListeningSeconds: map['totalListeningSeconds'] ?? 0,
      playCounts: Map<String, int>.from(map['playCounts'] ?? {}),
      hourlyListening: Map<String, int>.from(map['hourlyListening'] ?? {}),
      dailyListening: Map<String, int>.from(map['dailyListening'] ?? {}),
      monthlyListening: Map<String, int>.from(map['monthlyListening'] ?? {}),
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastListeningDate: map['lastListeningDate'] ?? '',
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? []),
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  static const _key = '@quran_listening_statistics';

  StatisticsNotifier() : super(StatisticsState(totalListeningSeconds: 0, playCounts: {})) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data != null) {
        final Map<String, dynamic> decoded = jsonDecode(data);
        state = StatisticsState.fromMap(decoded);
      }
    } catch (e) {
      print("Error loading statistics: $e");
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(state.toMap());
      await prefs.setString(_key, data);
    } catch (e) {
      print("Error saving statistics: $e");
    }
  }

  void incrementPlayCount(String surahId) {
    final updatedCounts = Map<String, int>.from(state.playCounts);
    updatedCounts[surahId] = (updatedCounts[surahId] ?? 0) + 1;
    state = state.copyWith(playCounts: updatedCounts);
    _save();
  }

  void incrementListeningDuration(int seconds) {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final hourKey = '${now.hour}';

    final updatedHourly = Map<String, int>.from(state.hourlyListening);
    updatedHourly[hourKey] = (updatedHourly[hourKey] ?? 0) + seconds;

    final updatedDaily = Map<String, int>.from(state.dailyListening);
    updatedDaily[dateKey] = (updatedDaily[dateKey] ?? 0) + seconds;

    final updatedMonthly = Map<String, int>.from(state.monthlyListening);
    updatedMonthly[monthKey] = (updatedMonthly[monthKey] ?? 0) + seconds;

    int newStreak = state.currentStreak;
    int newLongest = state.longestStreak;
    String newLastDate = state.lastListeningDate;

    if (newLastDate != dateKey) {
      if (newLastDate.isNotEmpty) {
        try {
          final lastDate = DateTime.parse(newLastDate);
          final diff = DateTime(now.year, now.month, now.day).difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
          if (diff == 1) {
            newStreak += 1;
          } else if (diff > 1) {
            newStreak = 1;
          }
        } catch (_) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
      newLastDate = dateKey;
      if (newStreak > newLongest) {
        newLongest = newStreak;
      }
    }

    final newTotal = state.totalListeningSeconds + seconds;
    
    // Check badges
    final newBadges = List<String>.from(state.unlockedBadges);
    if (newTotal >= 60 && !newBadges.contains('first_step')) newBadges.add('first_step');
    if (newTotal >= 3600 && !newBadges.contains('devoted')) newBadges.add('devoted');
    if (newTotal >= 36000 && !newBadges.contains('guardian')) newBadges.add('guardian');
    if (newStreak >= 3 && !newBadges.contains('consistent')) newBadges.add('consistent');
    if (newStreak >= 7 && !newBadges.contains('habit_builder')) newBadges.add('habit_builder');
    
    if ((now.hour >= 22 || now.hour < 4) && !newBadges.contains('night_owl')) newBadges.add('night_owl');
    if ((now.hour >= 4 && now.hour < 7) && !newBadges.contains('dawn_seeker')) newBadges.add('dawn_seeker');

    state = state.copyWith(
      totalListeningSeconds: newTotal,
      hourlyListening: updatedHourly,
      dailyListening: updatedDaily,
      monthlyListening: updatedMonthly,
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastListeningDate: newLastDate,
      unlockedBadges: newBadges,
    );
    _save();
  }

  void resetStatistics() {
    state = StatisticsState(totalListeningSeconds: 0, playCounts: {});
    _save();
  }
}

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier();
});
