import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import '../services/database_service.dart';

import '../data/telawat_2018.dart';
import '../data/telawat_2019.dart';
import '../data/telawat_2020.dart';
import '../data/telawat_2022.dart';
import '../data/telawat_2023.dart';
import '../data/telawat_2024.dart';
import '../data/telawat_2025.dart';
import '../data/telawat_2026_local.dart';
import '../data/anashid_2018.dart';
import '../data/anashid_2019.dart';
import '../data/anashid_2020.dart';
import '../data/anashid_2022.dart';
import '../data/anashid_2023.dart';
import '../data/anashid_2024.dart';

class ContentState {
  final List<Surah> telawat2026;
  final List<Surah> telawat2018;
  final List<Surah> telawat2019;
  final List<Surah> telawat2020;
  final List<Surah> telawat2022;
  final List<Surah> telawat2023;
  final List<Surah> telawat2024;
  final List<Surah> telawat2025;
  final List<Surah> telawat2026Local;
  final List<Surah> anashid2018;
  final List<Surah> anashid2019;
  final List<Surah> anashid2020;
  final List<Surah> anashid2022;
  final List<Surah> anashid2023;
  final List<Surah> anashid2024;
  final List<Surah> azkar;
  final List<Surah> doae;
  final List<Surah> githubList;
  final List<Surah> youtubeRecitationsList;
  final List<Surah> remoteGithubList;
  final List<Surah> quranKareemRemote;
  final bool isLoading;

  ContentState({
    this.telawat2026 = const [],
    this.telawat2018 = const [],
    this.telawat2019 = const [],
    this.telawat2020 = const [],
    this.telawat2022 = const [],
    this.telawat2023 = const [],
    this.telawat2024 = const [],
    this.telawat2025 = const [],
    this.telawat2026Local = const [],
    this.anashid2018 = const [],
    this.anashid2019 = const [],
    this.anashid2020 = const [],
    this.anashid2022 = const [],
    this.anashid2023 = const [],
    this.anashid2024 = const [],
    this.azkar = const [],
    this.doae = const [],
    this.githubList = const [],
    this.youtubeRecitationsList = const [],
    this.remoteGithubList = const [],
    this.quranKareemRemote = const [],
    this.isLoading = false,
  });

  ContentState copyWith({
    List<Surah>? telawat2026,
    List<Surah>? telawat2018,
    List<Surah>? telawat2019,
    List<Surah>? telawat2020,
    List<Surah>? telawat2022,
    List<Surah>? telawat2023,
    List<Surah>? telawat2024,
    List<Surah>? telawat2025,
    List<Surah>? telawat2026Local,
    List<Surah>? anashid2018,
    List<Surah>? anashid2019,
    List<Surah>? anashid2020,
    List<Surah>? anashid2022,
    List<Surah>? anashid2023,
    List<Surah>? anashid2024,
    List<Surah>? azkar,
    List<Surah>? doae,
    List<Surah>? githubList,
    List<Surah>? youtubeRecitationsList,
    List<Surah>? remoteGithubList,
    List<Surah>? quranKareemRemote,
    bool? isLoading,
  }) {
    return ContentState(
      telawat2026: telawat2026 ?? this.telawat2026,
      telawat2018: telawat2018 ?? this.telawat2018,
      telawat2019: telawat2019 ?? this.telawat2019,
      telawat2020: telawat2020 ?? this.telawat2020,
      telawat2022: telawat2022 ?? this.telawat2022,
      telawat2023: telawat2023 ?? this.telawat2023,
      telawat2024: telawat2024 ?? this.telawat2024,
      telawat2025: telawat2025 ?? this.telawat2025,
      telawat2026Local: telawat2026Local ?? this.telawat2026Local,
      anashid2018: anashid2018 ?? this.anashid2018,
      anashid2019: anashid2019 ?? this.anashid2019,
      anashid2020: anashid2020 ?? this.anashid2020,
      anashid2022: anashid2022 ?? this.anashid2022,
      anashid2023: anashid2023 ?? this.anashid2023,
      anashid2024: anashid2024 ?? this.anashid2024,
      azkar: azkar ?? this.azkar,
      doae: doae ?? this.doae,
      githubList: githubList ?? this.githubList,
      youtubeRecitationsList: youtubeRecitationsList ?? this.youtubeRecitationsList,
      remoteGithubList: remoteGithubList ?? this.remoteGithubList,
      quranKareemRemote: quranKareemRemote ?? this.quranKareemRemote,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ContentNotifier extends StateNotifier<ContentState> {
  final Dio _dio = Dio();
  final AudioPlayer _durationPlayer = AudioPlayer();

  ContentNotifier() : super(ContentState()) {
    loadAllContent();
  }

  List<Surah> _sort(List<Surah> list) {
    list.sort((a, b) => a.mushafIndex.compareTo(b.mushafIndex));
    return list;
  }

  Future<void> loadAllContent() async {
    state = state.copyWith(
      telawat2018: _sort(telawat2018List.map((s) => _ensureCategory(s, 'تلاوات 2018')).toList()),
      telawat2019: _sort(telawat2019List.map((s) => _ensureCategory(s, 'تلاوات 2019')).toList()),
      telawat2020: _sort(telawat2020List.map((s) => _ensureCategory(s, 'تلاوات 2020')).toList()),
      telawat2022: _sort(telawat2022List.map((s) => _ensureCategory(s, 'تلاوات 2022')).toList()),
      telawat2023: _sort(telawat2023List.map((s) => _ensureCategory(s, 'تلاوات 2023')).toList()),
      telawat2024: _sort(telawat2024List.map((s) => _ensureCategory(s, 'تلاوات 2024')).toList()),
      telawat2025: _sort(telawat2025List.map((s) => _ensureCategory(s, 'تلاوات 2025')).toList()),
      telawat2026Local: _sort(telawat2026LocalList.map((s) => _ensureCategory(s, 'تلاوات 2026 محلي')).toList()),
      anashid2018: _sort(anashid2018List.map((s) => _ensureCategory(s, 'أناشيد 2018')).toList()),
      anashid2019: _sort(anashid2019List.map((s) => _ensureCategory(s, 'أناشيد 2019')).toList()),
      anashid2020: _sort(anashid2020List.map((s) => _ensureCategory(s, 'أناشيد 2020')).toList()),
      anashid2022: _sort(anashid2022List.map((s) => _ensureCategory(s, 'أناشيد 2022')).toList()),
      anashid2023: _sort(anashid2023List.map((s) => _ensureCategory(s, 'أناشيد 2023')).toList()),
      anashid2024: _sort(anashid2024List.map((s) => _ensureCategory(s, 'أناشيد 2024')).toList()),
      isLoading: true,
    );
    try {
      await Future.wait([
        _loadLocalJson(),
      ]);
      _loadQuranKareemRemote();

      // Lazily fetch real durations in background
      _fetchAllDurations();
    } catch (e) {
      print("Error loading content: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Surah _ensureCategory(Surah s, String defaultCat) {
    if (s.category != null && s.category!.isNotEmpty) return s;
    return Surah(
      id: s.id,
      name: s.name,
      url: s.url,
      lrcUrl: s.lrcUrl,
      estimatedDuration: s.estimatedDuration,
      isMakki: s.isMakki,
      category: defaultCat,
    );
  }

  Future<void> _fetchAllDurations() async {
    final allContent = [
      ...state.telawat2018, ...state.telawat2019, ...state.telawat2020,
      ...state.telawat2022, ...state.telawat2023, ...state.telawat2024,
      ...state.telawat2025, ...state.telawat2026Local, ...state.telawat2026,
      ...state.anashid2018, ...state.anashid2019, ...state.anashid2020,
      ...state.anashid2022, ...state.anashid2023, ...state.anashid2024,
      ...state.azkar, ...state.doae, ...state.githubList,
      ...state.youtubeRecitationsList, ...state.remoteGithubList,
      ...state.quranKareemRemote,
    ];

    final db = DatabaseService.instance;

    bool updated = false;
    for (var surah in allContent) {
      if (surah.actualDuration != null) continue;

      final cachedSeconds = await db.getDuration(surah.id);
      if (cachedSeconds != null) {
        surah.actualDuration = Duration(seconds: cachedSeconds);
        updated = true;
        continue;
      }
    }
    if (updated) _notifyStateUpdate();

    // Batch fetch missing durations
    _startBatchFetch(allContent);
  }

  void _startBatchFetch(List<Surah> allContent) async {
    final missing = allContent.where((s) => s.actualDuration == null).toList();
    if (missing.isEmpty) return;

    final db = DatabaseService.instance;

    // Fetch in batches of 3 to avoid overloading
    for (int i = 0; i < missing.length; i += 3) {
      final batch = missing.skip(i).take(3);
      await Future.wait(batch.map((surah) async {
        try {
          Duration? d;
          if (surah.url.startsWith('http')) {
            d = await _durationPlayer.setUrl(surah.url, preload: false);
          } else {
            d = await _durationPlayer.setAsset(surah.url, preload: false);
          }

          if (d != null) {
            surah.actualDuration = d;
            await db.saveDuration(surah.id, d.inSeconds);
          }
        } catch (e) {
          // Silent fail for individual tracks
        }
      }));
      _notifyStateUpdate();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _notifyStateUpdate() {
    state = state.copyWith(); // Trigger UI rebuild
  }

  Future<Duration?> fetchRealDuration(Surah surah) async {
    if (surah.actualDuration != null) return surah.actualDuration;

    final db = DatabaseService.instance;
    final cachedSeconds = await db.getDuration(surah.id);
    if (cachedSeconds != null) {
      surah.actualDuration = Duration(seconds: cachedSeconds);
      _notifyStateUpdate();
      return surah.actualDuration;
    }

    try {
      Duration? d;
      if (surah.url.startsWith('http')) {
        d = await _durationPlayer.setUrl(surah.url, preload: false);
      } else {
        d = await _durationPlayer.setAsset(surah.url, preload: false);
      }

      if (d != null) {
        surah.actualDuration = d;
        await db.saveDuration(surah.id, d.inSeconds);
        _notifyStateUpdate();
        return d;
      }
    } catch (e) {
      print("Error fetching duration for ${surah.name}: $e");
    }
    return null;
  }

  void _loadQuranKareemRemote() {
    final List<Map<String, String>> remoteData = [
      {
        "title": "سورة البقرة 22",
        "audio_url": "https://www.dropbox.com/scl/fi/uh4at7bgnev1m6k6aw69s/hamza-medbouH-surat-baqara-1.mp3?rlkey=lolajavs7g07n8a5koixtkygm&st=l8u5kyoi&dl=1",
        "lrc_url": ""
      },
      {
        "title": "سورة المائدة",
        "audio_url": "https://www.dropbox.com/scl/fi/1q8dxyf9gzx5h95yvsh06/.mp3?rlkey=quymor6ab3otwvwtns63m4uyq&st=7le1jwpk&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/h0g3r5904aqz1fofv922t/.lrc?rlkey=9xfhxlchkst6pk9tym7r3cv6t&st=2lqexz78&dl=1"
      },
      {
        "title": "سورة المائدة EL",
        "audio_url": "https://www.dropbox.com/scl/fi/ugbx6p7sl3fxvtopra15q/EL-2.mp3?rlkey=cvp17j5ma21m9pfu19alxflsh&st=ln2a47t8&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/h0g3r5904aqz1fofv922t/.lrc?rlkey=9xfhxlchkst6pk9tym7r3cv6t&st=2lqexz78&dl=1"
      },
      {
        "title": "سورة الانفال",
        "audio_url": "https://www.dropbox.com/scl/fi/njysjl99sgkid27en3xqf/3.mp3?rlkey=riwip3ifr1iokagdprt3yif6s&st=3z7wf5o8&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/zyaf293r49elv5tstsjd7/.lrc?rlkey=4r3t4w74p8bcqdwi64qgt044f&st=q79k93sm&dl=1"
      },
      {
        "title": "سورة التوبة1",
        "audio_url": "https://www.dropbox.com/scl/fi/2udjfbnvyuky2aqvfbw57/1.mp3?rlkey=qoo9sj8jkdfivjnfecs2r7hqh&st=tt7fx61y&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/ae5oo2a7bqg910dky8msj/.lrc?rlkey=9gkcrh8xmr84qdlskjywnb5yy&st=h8ozo0qo&dl=1"
      },
      {
        "title": "سورة التوبة",
        "audio_url": "https://www.dropbox.com/scl/fi/8blzk8s0dntzxpwffvmyg/.mp3?rlkey=2wa1sx4gz6mszlqo5sjbnh06x&st=0gvaux06&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/ae5oo2a7bqg910dky8msj/.lrc?rlkey=9gkcrh8xmr84qdlskjywnb5yy&st=h8ozo0qo&dl=1"
      },
      {
        "title": "سورة الرعد",
        "audio_url": "https://www.dropbox.com/scl/fi/zb4xmqlgph22up70fgoxe/.mp3?rlkey=70fkmnqdtfqj3g6egxnp2k5zy&st=w8zwmhof&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/kyhrtih0a64wscd0blz5f/.lrc?rlkey=lo0t8x8s4t2h84szlern61pmr&st=3tsvy7c2&dl=1"
      },
      {
        "title": "سورة النحل",
        "audio_url": "https://www.dropbox.com/scl/fi/27dhbwawtbqzup8nckdwk/.mp3?rlkey=abrtsmcpnrf0xzhj1w3b9ym90&st=5hw2bosc&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/0st0wg8hxca6xn1lb8xha/.lrc?rlkey=kas1yn4gndf2twc69bfwhj5qp&st=2zpv5d13&dl=1"
      },
      {
        "title": "سورة الكهف",
        "audio_url": "https://www.dropbox.com/scl/fi/g6tl44c2imcx9wtc37cgm/.mp3?rlkey=05xuo2dwqm7k8fdfq4zm3gqsp&st=wid9kfrc&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/w00ev2b8h34hmu319wexk/.lrc?rlkey=73anw20rpedi3fikqubjkhc3i&st=dgrgdmrz&dl=1"
      },
      {
        "title": "سورة مريم n",
        "audio_url": "https://www.dropbox.com/scl/fi/stz7dbox8ns8wyf106w2j/n.mp3?rlkey=yu1lgrs863k6vlzxvyqzzwc89&st=6xwd6v6o&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/8ttmpq1pxrayv7cencede/.lrc?rlkey=0d94rre5p82khe9evx3d1iz3u&st=oplw18em&dl=1"
      },
      {
        "title": "سورة طه",
        "audio_url": "https://www.dropbox.com/scl/fi/sizsomjc6n1hirlf2jqsk/.mp3?rlkey=5f9iir09k8agzjtxwhujynffo&st=y63mq8mo&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/gf0ncum4w3mij5gpvmpu4/.lrc?rlkey=y0li9nx4yjwglpdvj8n8mf2nd&st=xkgl77ro&dl=1"
      },
      {
        "title": "سورة الانبياء",
        "audio_url": "https://www.dropbox.com/scl/fi/i0lyba4tu5ect29mjh12v/n_2.mp3?rlkey=s6e5k7a7xh02qz4i1m3t8i52z&st=fjks5ewl&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/4ywe7xdqsno4s70hw9h19/.lrc?rlkey=majn8a94eu93962ysorrxhems&st=ah3mbm5n&dl=1"
      },
      {
        "title": "سورة الفرقان",
        "audio_url": "https://www.dropbox.com/scl/fi/bo3xk1g0cqk2bagcqhd7s/.mp3?rlkey=jatpgx00zps2pg9ljocg26q4t&st=gywh4o79&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/gtzur56qshpwrce57fyi2/.lrc?rlkey=7df1k7j9sh02ff7abm3gmijr6&st=ueo35xkb&dl=1"
      },
      {
        "title": "سورة يوسف",
        "audio_url": "https://www.dropbox.com/scl/fi/qtssi53n6z3udqq61zvj1/26.mp3?rlkey=53uqlzj0oni8tzcfsoka4lyv4&st=q8cwfmj3&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/urcd6z9cb2cd54ns73lk1/...lrc?rlkey=bn0dh120n8sa90p0dcb8ktb00&st=azs111r2&dl=1"
      },
      {
        "title": "سورة القصص",
        "audio_url": "https://www.dropbox.com/scl/fi/jz19eq6hin4m2x1jyqu1o/3.mp3?rlkey=u04uiczabhkufxmb79qzc6hc4&st=5njeclfu&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/g3p7wedb6ucgmfy8lbkqx/.lrc?rlkey=hu1m7cm3nxrmbp0w3e15js76k&st=nb49yvqe&dl=1"
      },
      {
        "title": "سورة لقمان",
        "audio_url": "https://www.dropbox.com/scl/fi/mmku7au5gado5jfknu1si/.mp3?rlkey=9ajifyim5kxxcb4r2dvd39jdg&st=54fh8ozs&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/iurttjl5q8iiy3gwt15j4/.lrc?rlkey=6o9ct6kqwk1awx4azfts84zxi&st=ok5h8ztt&dl=1"
      },
      {
        "title": "سورة السجدة",
        "audio_url": "https://www.dropbox.com/scl/fi/2oh2920744i2zm45e7c3e/.mp3?rlkey=g42uwznkeympvkib9v7ec4ttr&st=wnho81d0&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/uv9jr27r8q4142bn8t51b/.lrc?rlkey=x9fsn1rl1u7phkhbqjlwcck82&st=kzhiozea&dl=1"
      },
      {
        "title": "سورة الأحزاب",
        "audio_url": "https://www.dropbox.com/scl/fi/j5su62n6f7wso6ov1d1rh/.mp3?rlkey=efl2kiqojuky7gw64z5lvn1lp&st=pt1xonrn&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/ei7nixx9rsww80mlxz6gm/.lrc?rlkey=bg7fqnsffqrsyezyj9y19gume&st=bb9jl2cb&dl=1"
      },
      {
        "title": "سورة فاطر",
        "audio_url": "https://www.dropbox.com/scl/fi/fq9508l1y244hluwdy1db/.mp3?rlkey=ypysoflu1gvdofdeibwsvaw4b&st=7klmum8p&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/bmjel9cq5sdz7r0c9f9wg/.lrc?rlkey=n2kim0jb7mipjomyqy3vczp6t&st=ttoo0l14&dl=1"
      },
      {
        "title": "سورة يس so",
        "audio_url": "https://www.dropbox.com/scl/fi/5083p7txu2jyk0l04pkrf/so.mp3?rlkey=6lw4iq0g13hsiu7nvmtmuec40&st=9spyonij&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/6hrvipkt18ivltf2ifp1v/.lrc?rlkey=3pwy0y7xn59grix7sn3oycgte&st=t9sk7o16&dl=1"
      },
      {
        "title": "سورة الزمر",
        "audio_url": "https://www.dropbox.com/scl/fi/5829yx5rjms0nz6w7s473/4.mp3?rlkey=7ctdn4pw60zpo1zs5lxlyqzbj&st=mffwn7z1&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/i8xfy1n4j521iuks717a4/.lrc?rlkey=59lx5q18zve7hzgfcwo695vfa&st=8t4r120b&dl=1"
      },
      {
        "title": "سورة الزمر 1",
        "audio_url": "https://www.dropbox.com/scl/fi/2oh2920744i2zm45e7c3e/.mp3?rlkey=g42uwznkeympvkib9v7ec4ttr&st=7wzwtlze&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/xgtbt4f57rthki8zxzgqa/.lrc?rlkey=0a2sach0d6z7dfq6cm6coml60&st=dalyoqoi&dl=1"
      },
      {
        "title": "سورة الشورى",
        "audio_url": "https://www.dropbox.com/scl/fi/lpyqowai8n778mwey9f7z/2-1.mp3?rlkey=x301i047uthd0lxeh5tza0873&st=veal83es&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/6b4vot85yi89i1smoea70/..lrc?rlkey=9jytaiiwuumx2j1bav3hjkcfd&st=spr8gq9k&dl=1"
      },
      {
        "title": "سورة الزخرف",
        "audio_url": "https://www.dropbox.com/scl/fi/zuk4etucdflijoqdsaytd/.mp3?rlkey=ia8wi2g0svmqq8er0lqgom7rm&st=l8bcsexg&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/i8xfy1n4j521iuks717a4/.lrc?rlkey=59lx5q18zve7hzgfcwo695vfa&st=8t4r120b&dl=1"
      },
      {
        "title": "سورة الدخان",
        "audio_url": "https://www.dropbox.com/scl/fi/ifx6dj8m8oaj0miw5q106/2.mp3?rlkey=z86cy4kwl4zk7vtm74r975nv9&st=v8pyb29v&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/y0zkjpz0fb5s0b6akhtrv/.lrc?rlkey=pxzqk3dr82umy0pqmvvjez7i6&st=a39u645o&dl=1"
      },
      {
        "title": "سورة الجاثية",
        "audio_url": "https://www.dropbox.com/scl/fi/8blzk8s0dntzxpwffvmyg/.mp3?rlkey=2wa1sx4gz6mszlqo5sjbnh06x&st=0gvaux06&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/bzuwizvev553csn932i1d/.lrc?rlkey=uzl9tgo9338zbwk3pyx5dighb&st=z5o07zz2&dl=1"
      },
      {
        "title": "سورة الاحقاف",
        "audio_url": "https://www.dropbox.com/scl/fi/jlyeazz4dp8was9qstr9j/.mp3?rlkey=74l6te7980fqgmqw7bnmmpsk7&st=d4kd1d9i&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/2x6axc0qny1d016083bzb/.lrc?rlkey=0jz9gm1iux9f69cvsc27j1rmw&st=sab2g12t&dl=1"
      },
      {
        "title": "سورة محمد",
        "audio_url": "https://www.dropbox.com/scl/fi/r54q5cyibinlry9kmce9r/.mp3?rlkey=pn928os45vwjlay9pby8w1tcq&st=1knbta1r&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/xsxfs2naxs1aba5pz2a8b/.lrc?rlkey=on6ura1eqa1hctzsov0h3649o&st=frjkade4&dl=1"
      },
      {
        "title": "سورة الفتح",
        "audio_url": "https://www.dropbox.com/scl/fi/x7lej5gjzkdot4n24thuq/2-c.mp3?rlkey=15jri8mux8699ht09a863q6t9&st=etr8zj8p&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/182ir9khozvb975nlg257/.lrc?rlkey=iji4nnjcycunl3qkfnf0tltt6&st=cbvo0fpg&dl=1"
      },
      {
        "title": "سورة ق",
        "audio_url": "https://www.dropbox.com/scl/fi/lgg75rlevdp8lw1cm7nxc/.mp3?rlkey=aevw7f0vjwrqx6nqrc0hzqxse&st=38gkhs11&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/zu8dczd5f1fzcd2m2yakw/.lrc?rlkey=o7j0ysfi47l165an5g8gh3wpa&st=x2o1f1pj&dl=1"
      },
      {
        "title": "سورة الذاريات",
        "audio_url": "https://www.dropbox.com/scl/fi/5gano27ijdytupu9rpnf5/.mp3?rlkey=9jxe530c4u3xe7nqqomd9jn0m&st=s09ju7kw&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/xa5ze5piwn8jrjf485jhj/.lrc?rlkey=pp2qr223t1w267p0v6b794zov&st=7e43nngg&dl=1"
      },
      {
        "title": "سورة القمر 1",
        "audio_url": "https://www.dropbox.com/scl/fi/bqcumvj2snmwf99zbizsu/1.mp3?rlkey=d9wi60yi7qjgryxxzd8xr6pv8&st=pujy1t5g&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/cgd1b2ar23yf32w46p084/.lrc?rlkey=11y972j50jnoivsx32wgsf7u4&st=j5hwmxkd&dl=1"
      },
      {
        "title": "سورة القمر ELI",
        "audio_url": "https://www.dropbox.com/scl/fi/lcgdwt0c2uigl8ytzdh7a/ELI.mp3?rlkey=bogebojk2wdolt6hho1wwleq9&st=17sadc7t&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/cgd1b2ar23yf32w46p084/.lrc?rlkey=11y972j50jnoivsx32wgsf7u4&st=j5hwmxkd&dl=1"
      },
      {
        "title": "سورة القمر",
        "audio_url": "https://www.dropbox.com/scl/fi/hxjklqbuxiwp3id81xbp7/h.mp3?rlkey=o97quvarb6abycdfaynrkumwg&st=ydljs6sn&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/cgd1b2ar23yf32w46p084/.lrc?rlkey=11y972j50jnoivsx32wgsf7u4&st=j5hwmxkd&dl=1"
      },
      {
        "title": "سررة القمر 1",
        "audio_url": "https://www.dropbox.com/scl/fi/tz2q4ml69j22piigc2o8x/.mp3?rlkey=lcfksmwsec939y3zxfr58iea1&st=6g22oz3o&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/cgd1b2ar23yf32w46p084/.lrc?rlkey=11y972j50jnoivsx32wgsf7u4&st=j5hwmxkd&dl=1"
      },
      {
        "title": "سورة الرحمان",
        "audio_url": "https://www.dropbox.com/scl/fi/a32xztams2nkei9gkoqaz/23.mp3?rlkey=0mm7gav24hw7ivgn3kzrwczwa&st=lsvsuhji&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/ft4ogseubdj489sca4zoy/.lrc?rlkey=jewumlebftvk946gwoeilcy8k&st=xewvpzms&dl=1"
      },
      {
        "title": "سورة الواقعة 26",
        "audio_url": "https://www.dropbox.com/scl/fi/xk6c4bqpenw5xxdfzhqe5/26.mp3?rlkey=3xukcftbzcyj1wggkkbxyjsqr&st=j1zy8mcb&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/8klwlhx9pkvzunc888gay/1.lrc?rlkey=pqu017wapwx53hirzr1y96ggy&st=6v8s8mc8&dl=1"
      },
      {
        "title": "سورة الحديد",
        "audio_url": "https://www.dropbox.com/scl/fi/9csdp8xe0gm5bbh86ke9w/.mp3?rlkey=2xbr0xd1yp8xjimbmmqm03i67&st=odcaphax&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/kc9h22v5p4jecw876ssgo/.lrc?rlkey=gckbrvtkgdfq9m4a7yqf3wg5r&st=28057r97&dl=1"
      },
      {
        "title": "سورة المجادلة",
        "audio_url": "https://www.dropbox.com/scl/fi/vnogti321t9nn10kh2iqd/5.mp3?rlkey=viadl0oje0ih19ahcl64dzy37&st=rxesvuqy&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/zxe0vetmpck5beiiuuk5r/..lrc?rlkey=jezhv6yaksfza1writvyaqt29&st=sd6iyeoh&dl=1"
      },
      {
        "title": "سورة الجمعة",
        "audio_url": "https://www.dropbox.com/scl/fi/xy6g0fwdqety3ddc0rs6j/3.mp3?rlkey=ufbtl8yzh8it4z35gg0r76sc6&st=41nz9qty&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/cxxrrn8475lbcy1rrc7k6/.lrc?rlkey=v87x06zkptssd0b3k0zf9qjog&st=qt2j5xul&dl=1"
      },
      {
        "title": "سورة الملك S",
        "audio_url": "https://www.dropbox.com/scl/fi/4odx7tbwrf2k0vmiibsma/s.mp3?rlkey=v39t64gfatiadpjnkmkgzecbb&st=b724y272&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/pgkvmojltuo7f6x96v5vd/2.lrc?rlkey=9qh8mi11egluzjqx83ds0tned&st=yy7k6f3z&dl=1"
      },
      {
        "title": "سورة الملك",
        "audio_url": "https://www.dropbox.com/scl/fi/a467isv6dhcvr9c092uku/2.mp3?rlkey=zpeno8u7r741ljbmdmvexeqdj&st=k9tkxuw2&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/pgkvmojltuo7f6x96v5vd/2.lrc?rlkey=9qh8mi11egluzjqx83ds0tned&st=yy7k6f3z&dl=1"
      },
      {
        "title": "سورة القلم",
        "audio_url": "https://www.dropbox.com/scl/fi/8ahefnvu50hb9zu9f2puk/5.mp3?rlkey=ynwrwtvbzwg0bb4y57nvz34k5&st=tna5sakk&dl=1",
        "lrc_url": ""
      },
      {
        "title": "سورة الحاقة",
        "audio_url": "https://www.dropbox.com/scl/fi/b7jwf5mz1z34ky5ukrsco/.mp3?rlkey=0hph7f8shpzp8xtd3cbazbvl0&st=6xtz99r4&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/zswo9l783glhok6qcb4sl/.lrc?rlkey=nreh7mgrxexyuav66qwug1lz9&st=58dl6nbb&dl=1"
      },
      {
        "title": "سورة الجن",
        "audio_url": "https://www.dropbox.com/scl/fi/ee1v5vejwkeniw6y8gy5m/2.mp3?rlkey=v8j5ll3w3qyz4m6ffs5g10s3o&st=ck6b4fsx&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/3kwexxmief1f4e8wkccs8/.lrc?rlkey=qel33zno4wlisazkaq6e918kf&st=6g6onk8y&dl=1"
      },
      {
        "title": "سورة القيامة",
        "audio_url": "https://www.dropbox.com/scl/fi/cq5vk3y69d0n9f4nzlxof/2.mp3?rlkey=l31ffzq7boy28aihrpyi9oafp&st=0137bcbx&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/8zdhe8n0emy3yid366t85/.lrc?rlkey=q043m0mh8xwf8dagmqxge1knv&st=t1572etu&dl=1"
      },
      {
        "title": "سورة الانسان",
        "audio_url": "https://www.dropbox.com/scl/fi/dzx8p7mfvcj7xp3sqby0q/.mp3?rlkey=18xyabz9qzzaoyechl8hlakk2&st=ikh7kh6b&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/7t2akma6h16acfm2ys4ox/.lrc?rlkey=2e40dy877zzq2q7bfzi7qnkmb&st=0zz6hy5e&dl=1"
      },
      {
        "title": "سورة النبا",
        "audio_url": "https://www.dropbox.com/scl/fi/j5sly6g6d8ecyuva6x4pb/3.mp3?rlkey=5x8lfsiswtt28jtyxtidgqogs&st=wghbuq8o&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/yvn7lvuj8msx02qnb6lzb/.lrc?rlkey=g14andimmjf493eojag3igtwc&st=uji7ukfh&dl=1"
      },
      {
        "title": "سورة النازعات",
        "audio_url": "https://www.dropbox.com/scl/fi/31fqfdhdtjasofkekjoti/12.mp3?rlkey=4u9oqchodbesqlk02a2pbttet&st=4j459kp8&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/llve5gvpbyl1hiqhuerk4/.lrc?rlkey=bspahwsidlqnjjv5wiotljydl&st=yhf8jfuj&dl=1"
      },
      {
        "title": "سورة المطففين",
        "audio_url": "https://www.dropbox.com/scl/fi/7ksq6lbx637xh1lc0smsh/.mp3?rlkey=477bip18jl024ovvv66w9o95l&st=5rxjadvb&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/zxsd0owcirn3tq9ivtq5r/.lrc?rlkey=svc69byzc3pgawem4r0jdjoub&st=vgdeldd0&dl=1"
      },
      {
        "title": "سورة البروج",
        "audio_url": "https://www.dropbox.com/scl/fi/n4zazya0ora4kjkk178ja/.mp3?rlkey=l7i84hht8ccq0tsczixtl632b&st=q4bmcser&dl=1",
        "lrc_url": "https://www.dropbox.com/scl/fi/pivmfkdhovy2ed3bjrpab/.lrc?rlkey=0x8ln20zag377xyy0wvtg6fb0&st=47yrnlm0&dl=1"
      }
    ];

    final quranKareem = remoteData.asMap().entries.map((entry) {
      final data = entry.value;
      return Surah(
        id: 'quran_remote_${data['title']}',
        name: data['title'] ?? 'تلاوة قرآن',
        url: data['audio_url'] ?? '',
        lrcUrl: data['lrc_url'] ?? '',
        estimatedDuration: Duration.zero,
        isMakki: true,
        category: 'تلاوات',
      );
    }).toList();

    state = state.copyWith(quranKareemRemote: _sort(quranKareem));
  }

  Future<void> _loadRemoteGithubJson() async {
    try {
      final response = await _dio.get('https://raw.githubusercontent.com/hamzahamzaaaaa/hamza-rep/refs/heads/main/lrcc.json');
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        final List<Surah> remoteList = (data['content'] as List).map((item) {
          return Surah(
            id: 'remote_github_${item['title']}',
            name: item['title'] ?? 'تلاوة',
            url: item['audio_url'] ?? '',
            lrcUrl: item['lrc_url'] ?? '',
            estimatedDuration: Duration.zero,
            isMakki: true,
            category: data['category'] ?? 'تلاوات خارجية',
          );
        }).toList();

        state = state.copyWith(remoteGithubList: _sort(remoteList));
      }
    } catch (e) {
      print("Remote Github JSON load error: $e");
    }
  }

  Future<void> _loadLocalJson() async {
    try {
      // Load Telawat 2026
      final telawatData = await rootBundle.loadString('assets/json/telawat_2026.json');
      final telawatJson = jsonDecode(telawatData);
      final List<Surah> telawatList = (telawatJson['tracks'] as List).map((track) {
        return Surah(
          id: 'telawat_2026_${track['title'] ?? ''}',
          name: track['title']?.toString() ?? '',
          url: track['url']?.toString() ?? '',
          estimatedDuration: Duration.zero,
          isMakki: true,
          category: 'تلاوات 2026',
        );
      }).toList();

      // Load Azkar
      final azkarData = await rootBundle.loadString('assets/json/adkar.json');
      final azkarJson = jsonDecode(azkarData);
      final List<Surah> azkarList = (azkarJson['azkar_items'] as List).map((item) {
        return Surah(
          id: 'azkar_${item['id'] ?? ''}',
          name: item['title']?.toString() ?? '',
          url: item['url']?.toString() ?? '',
          estimatedDuration: Duration.zero,
          isMakki: true,
          category: 'أذكار',
        );
      }).toList();

      // Load Doae
      final doaeData = await rootBundle.loadString('assets/json/doae.json');
      final doaeJson = jsonDecode(doaeData);
      final List<Surah> doaeList = (doaeJson['audios'] as List).map((audio) {
        return Surah(
          id: 'doae_${audio['title'] ?? ''}',
          name: audio['title']?.toString() ?? '',
          url: audio['audio_url']?.toString() ?? '',
          estimatedDuration: Duration.zero,
          isMakki: true,
          category: 'أدعية',
        );
      }).toList();

      // Load Github List (New Recitations)
      final githubData = await rootBundle.loadString('assets/json/new_recitations.json');
      final githubJson = jsonDecode(githubData);
      final List<Surah> githubList = (githubJson['content'] as List).map((track) {
        return Surah(
          id: 'github_${track['title'] ?? ''}',
          name: track['title']?.toString() ?? '',
          url: track['url']?.toString() ?? '',
          estimatedDuration: Duration.zero,
          isMakki: true,
          category: 'تلاوات جديدة',
        );
      }).toList();

      // Load YouTube Recitations (from Recitation2026.json or similar)
      final ytData = await rootBundle.loadString('assets/json/Recitation2026.json');
      final ytJson = jsonDecode(ytData);
      final List<Surah> ytList = (ytJson['tracks'] as List).map((track) {
        return Surah(
          id: 'yt_${track['title'] ?? ''}',
          name: track['title']?.toString() ?? '',
          url: track['url']?.toString() ?? '',
          estimatedDuration: Duration.zero,
          isMakki: true,
          category: 'تلاوات 2026 (YT)',
        );
      }).toList();

      state = state.copyWith(
        telawat2026: _sort(telawatList),
        azkar: _sort(azkarList),
        doae: _sort(doaeList),
        githubList: githubList,
        youtubeRecitationsList: ytList,
      );
    } catch (e) {
      print("Local JSON load error: $e");
    }
  }
}

final contentProvider = StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  return ContentNotifier();
});
