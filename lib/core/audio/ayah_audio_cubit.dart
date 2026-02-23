import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../services/ayah_audio_service.dart';
import '../services/adhan_notification_service.dart';

enum AyahAudioMode { ayah, surah }

enum AyahAudioStatus { idle, buffering, playing, paused, error }

class AyahAudioState extends Equatable {
  final AyahAudioStatus status;
  final AyahAudioMode mode;
  final int? surahNumber;
  final int? ayahNumber;
  final String? errorMessage;

  const AyahAudioState({
    required this.status,
    this.mode = AyahAudioMode.ayah,
    this.surahNumber,
    this.ayahNumber,
    this.errorMessage,
  });

  const AyahAudioState.idle() : this(status: AyahAudioStatus.idle);

  bool get hasTarget => surahNumber != null && ayahNumber != null;

  bool isCurrent(int s, int a) => surahNumber == s && ayahNumber == a;

  @override
  List<Object?> get props => [
    status,
    mode,
    surahNumber,
    ayahNumber,
    errorMessage,
  ];

  AyahAudioState copyWith({
    AyahAudioStatus? status,
    AyahAudioMode? mode,
    int? surahNumber,
    int? ayahNumber,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AyahAudioState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AyahAudioCubit extends Cubit<AyahAudioState> {
  final AyahAudioService _service;
  final AudioPlayer _player;
  final AdhanNotificationService _adhanService;

  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _durationCacheSub;
  bool _initialized = false;

  // ── Playlist progress tracking ────────────────────────────────────────────
  /// Total items in the playlist (ayahs + silence items interleaved).
  int _playlistLength = 1;
  /// Number of ayah items only (excludes silence gaps).
  int _ayahCount = 1;
  /// Index of the item currently being played.
  int _currentItemIndex = 0;
  /// Known duration for each completed / loaded playlist item.
  final Map<int, Duration> _itemDurations = {};
  /// Sum of durations of all items that have already *finished* playing.
  Duration _accumulatedDuration = Duration.zero;
  /// Silence gap injected between consecutive ayahs.
  static const Duration _ayahGap = Duration(milliseconds: 400);
  /// Tag used on SilenceAudioSource items so we can identify them.
  static const int _kSilenceTag = -1;
  AyahAudioCubit(this._service, this._adhanService)
    : _player = AudioPlayer(),
      super(const AyahAudioState.idle()) {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    // Configure for music/media playback with ducking support
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    if (isClosed) return;

    // Ensure playback never loops unless explicitly enabled.
    await _player.setLoopMode(LoopMode.off);
    await _player.setShuffleModeEnabled(false);

    if (isClosed) return;
    _initialized = true;

    // Cache the duration of the current item whenever it becomes known.
    _durationCacheSub = _player.durationStream.listen((dur) {
      if (isClosed || dur == null) return;
      _itemDurations[_currentItemIndex] = dur;
    });

    _playerSub = _player.playerStateStream.listen(
      (ps) {
      if (isClosed) return;
      final processing = ps.processingState;
      if (processing == ProcessingState.loading ||
          processing == ProcessingState.buffering) {
        emit(
          state.copyWith(status: AyahAudioStatus.buffering, clearError: true),
        );
        return;
      }

      if (processing == ProcessingState.completed) {
        // Auto-hide player by resetting to idle after completion
        emit(const AyahAudioState.idle());
        return;
      }

      if (ps.playing) {
        emit(state.copyWith(status: AyahAudioStatus.playing, clearError: true));
      } else {
        // If we have a target, treat as paused; otherwise idle.
        emit(
          state.copyWith(
            status: state.hasTarget
                ? AyahAudioStatus.paused
                : AyahAudioStatus.idle,
            clearError: true,
          ),
        );
      }
    },
      onError: (Object e, StackTrace st) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: AyahAudioStatus.error,
            errorMessage: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      },
    );

    _indexSub = _player.currentIndexStream.listen((idx) {
      if (isClosed) return;
      if (idx == null) return;

      // ── Accumulate duration of the item we just left ──────────────────────
      if (idx > _currentItemIndex) {
        // For silence items use the fixed gap; for ayah items use cached dur.
        final prev = _currentItemIndex;
        final sequence = _player.sequenceState;
        final prevTag = (sequence != null && prev < sequence.sequence.length)
            ? sequence.sequence[prev].tag
            : null;
        final dur = prevTag == _kSilenceTag
            ? _ayahGap
            : (_itemDurations[prev] ?? Duration.zero);
        _accumulatedDuration += dur;
      }
      _currentItemIndex = idx;

      if (state.mode != AyahAudioMode.surah) return;

      // Get the ayah number from the audio source tag
      final sequence = _player.sequenceState;
      if (sequence != null && idx < sequence.sequence.length) {
        final tag = sequence.sequence[idx].tag;
        // Silence items: keep current ayah highlighted, don't change state.
        if (tag == _kSilenceTag) return;
        if (tag is int) {
          emit(state.copyWith(ayahNumber: tag));
          return;
        }
      }

      // Fallback: assume playlist starts from ayah 1
      emit(state.copyWith(ayahNumber: idx + 1));
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // ── Playlist-aware streams ───────────────────────────────────────────────

  /// Position relative to the START of the playlist.
  /// For single-ayah mode this is identical to [positionStream].
  /// For page/surah mode it accumulates the durations of completed items.
  Stream<Duration> get effectivePositionStream =>
      _player.positionStream.map((pos) => _accumulatedDuration + pos);

  /// Total duration of the full playlist.
  /// Becomes more accurate as each item's duration is loaded.
  /// Falls back to a proportional estimate while items are still loading.
  Stream<Duration?> get effectiveDurationStream =>
      _player.durationStream.map((currentItemDur) {
        if (_ayahCount <= 1) return currentItemDur;

        // Fixed total silence duration is always known.
        final silenceTotal = _ayahGap * (_ayahCount - 1);

        // Collect known ayah durations (even indices 0, 2, 4, …).
        final knownAyahDurs = <Duration>[];
        for (var i = 0; i < _playlistLength; i += 2) {
          final d = _itemDurations[i];
          if (d != null) knownAyahDurs.add(d);
        }

        if (knownAyahDurs.isEmpty) return currentItemDur;

        final knownAyahTotal =
            knownAyahDurs.fold(Duration.zero, (sum, d) => sum + d);

        if (knownAyahDurs.length >= _ayahCount) {
          // All ayah durations known — return exact total.
          return knownAyahTotal + silenceTotal;
        }

        // Proportional estimate for the remaining ayahs.
        final avgMs = knownAyahTotal.inMilliseconds / knownAyahDurs.length;
        return Duration(
          milliseconds:
              (avgMs * _ayahCount).round() + silenceTotal.inMilliseconds,
        );
      });

  Future<void> togglePlayAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (state.mode == AyahAudioMode.ayah &&
        state.isCurrent(surahNumber, ayahNumber) &&
        _player.playing) {
      await pause();
      return;
    }

    await playAyah(surahNumber: surahNumber, ayahNumber: ayahNumber);
  }

  void _resetPlaylistTracking(int ayahCount) {
    _ayahCount = ayahCount;
    // Total items: ayahs interleaved with silence gaps.
    // N ayahs → N + (N−1) = 2N−1 items.  Single ayah → 1 item (no gap).
    _playlistLength = ayahCount <= 1 ? 1 : 2 * ayahCount - 1;
    _currentItemIndex = 0;
    _accumulatedDuration = Duration.zero;
    _itemDurations.clear();
    // Pre-populate known durations for silence items (odd indices).
    for (var i = 1; i < _playlistLength; i += 2) {
      _itemDurations[i] = _ayahGap;
    }
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    // Stop Adhan (await so native stop completes before audio starts).
    await _adhanService.stopCurrentAdhan();
    if (!_initialized) {
      // Best-effort: allow _init() to finish.
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    _resetPlaylistTracking(1);
    emit(
      AyahAudioState(
        status: AyahAudioStatus.buffering,
        mode: AyahAudioMode.ayah,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );

    try {
      final source = await _service.resolveAyahAudio(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );

      if (source.isLocal) {
        await _player.setAudioSource(AudioSource.file(source.localFilePath!));
      } else {
        await _player.setAudioSource(AudioSource.uri(source.remoteUri!));
      }

      await _player.setLoopMode(LoopMode.off);
      await _player.setShuffleModeEnabled(false);

      await _player.play();
    } catch (e) {
      emit(
        AyahAudioState(
          status: AyahAudioStatus.error,
          mode: AyahAudioMode.ayah,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> togglePlaySurah({
    required int surahNumber,
    required int numberOfAyahs,
  }) async {
    if (state.mode == AyahAudioMode.surah && state.surahNumber == surahNumber) {
      if (_player.playing) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    await playSurah(surahNumber: surahNumber, numberOfAyahs: numberOfAyahs);
  }

  Future<void> playSurah({
    required int surahNumber,
    required int numberOfAyahs,
  }) async {
    // Stop Adhan (await so native stop completes before audio starts).
    await _adhanService.stopCurrentAdhan();
    if (!_initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    _resetPlaylistTracking(numberOfAyahs);
    emit(
      AyahAudioState(
        status: AyahAudioStatus.buffering,
        mode: AyahAudioMode.surah,
        surahNumber: surahNumber,
        ayahNumber: 1,
      ),
    );

    try {
      final sources = await _service.resolveSurahAyahAudio(
        surahNumber: surahNumber,
        numberOfAyahs: numberOfAyahs,
      );

      final children = <AudioSource>[];
      for (var i = 0; i < sources.length; i++) {
        final ayahNumber = i + 1;
        final s = sources[i];
        if (s.isLocal) {
          children.add(AudioSource.file(s.localFilePath!, tag: ayahNumber));
        } else {
          children.add(AudioSource.uri(s.remoteUri!, tag: ayahNumber));
        }
        // Add silence gap after every ayah except the last.
        if (i < sources.length - 1) {
          children.add(
            SilenceAudioSource(duration: _ayahGap, tag: _kSilenceTag),
          );
        }
      }

      final playlist = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _player.setLoopMode(LoopMode.off);
      await _player.setShuffleModeEnabled(false);
      await _player.play();
    } catch (e) {
      emit(
        AyahAudioState(
          status: AyahAudioStatus.error,
          mode: AyahAudioMode.surah,
          surahNumber: surahNumber,
          ayahNumber: 1,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Plays a specific range of ayahs from a surah
  Future<void> playAyahRange({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
  }) async {
    // Stop Adhan (await so native stop completes before audio starts).
    await _adhanService.stopCurrentAdhan();
    if (!_initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    _resetPlaylistTracking(endAyah - startAyah + 1);
    emit(
      AyahAudioState(
        status: AyahAudioStatus.buffering,
        mode: AyahAudioMode.surah,
        surahNumber: surahNumber,
        ayahNumber: startAyah,
      ),
    );

    try {
      final children = <AudioSource>[];
      for (var ayahNumber = startAyah; ayahNumber <= endAyah; ayahNumber++) {
        final source = await _service.resolveAyahAudio(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );

        if (source.isLocal) {
          children.add(
            AudioSource.file(source.localFilePath!, tag: ayahNumber),
          );
        } else {
          children.add(AudioSource.uri(source.remoteUri!, tag: ayahNumber));
        }
        // Add silence gap after every ayah except the last.
        if (ayahNumber < endAyah) {
          children.add(
            SilenceAudioSource(duration: _ayahGap, tag: _kSilenceTag),
          );
        }
      }

      final playlist = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _player.setLoopMode(LoopMode.off);
      await _player.setShuffleModeEnabled(false);
      await _player.play();
    } catch (e) {
      emit(
        AyahAudioState(
          status: AyahAudioStatus.error,
          mode: AyahAudioMode.surah,
          surahNumber: surahNumber,
          ayahNumber: startAyah,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
    emit(state.copyWith(status: AyahAudioStatus.paused));
  }

  Future<void> resume() async {
    await _player.play();
    emit(state.copyWith(status: AyahAudioStatus.playing));
  }

  Future<void> next() async {
    if (state.mode != AyahAudioMode.surah) return;
    if (!_player.hasNext) return;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (state.mode != AyahAudioMode.surah) return;
    if (!_player.hasPrevious) return;
    await _player.seekToPrevious();
  }

  Future<void> stop() async {
    await _player.stop();
    emit(const AyahAudioState.idle());
  }

  @override
  Future<void> close() async {
    await _playerSub?.cancel();
    await _indexSub?.cancel();
    await _durationCacheSub?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    await _player.dispose();
    return super.close();
  }
}
