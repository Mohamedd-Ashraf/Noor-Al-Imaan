package com.example.quraan

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import java.io.File

/**
 * Foreground Service that plays Adhan audio even when the app process is dead.
 *
 * Triggered by:
 *  - AdhanAlarmReceiver (scheduled via AlarmManager -- fires even when app is closed)
 *  - MainActivity MethodChannel "startAdhanService" (when app is running)
 *
 * Audio stream: USAGE_NOTIFICATION_RINGTONE (ring stream).
 *   • Respects the user's ring volume — not the alarm volume.
 *   • On a locked screen, pressing any volume key changes ring volume →
 *     VOLUME_CHANGED_ACTION fires → this service stops the adhan.
 *     (With USAGE_ALARM some OEMs block VOLUME_CHANGED_ACTION on the lock screen.)
 *
 * Stop mechanisms:
 *   1. Tap "ايقاف الأذان" in the foreground notification (works anywhere).
 *   2. Press any hardware volume key — works on lock screen AND when app is open.
 *   3. Incoming phone call: audio-focus loss → service stops automatically.
 */
class AdhanPlayerService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ── Audio focus (API 26+) ────────────────────────────────────────────────
    private var legacyFocusListener: AudioManager.OnAudioFocusChangeListener? = null
    private var focusRequest: AudioFocusRequest? = null   // API 26+ only

    /**
     * BroadcastReceiver for android.media.VOLUME_CHANGED_ACTION.
     *
     * Android fires this broadcast whenever ANY stream's volume changes, including
     * when the user presses volume-up or volume-down. Because we use
     * USAGE_NOTIFICATION_RINGTONE, pressing the volume key on a locked screen
     * adjusts the RING stream which always triggers this broadcast — so the adhan
     * stops even when the screen is fully locked.
     */
    private var volumeReceiver: BroadcastReceiver? = null
    private var shortModeHandler: Handler? = null
    private var shortModeRunnable: Runnable? = null

    companion object {
        const val CHANNEL_ID      = "adhan_player_service_ch"
        const val NOTIF_ID        = 7_777
        const val EXTRA_SOUND               = "soundName"
        /** Pass true to auto-stop playback after shortCutoffSeconds. */
        const val EXTRA_SHORT_MODE           = "shortMode"
        /** Per-sound cutoff in seconds for short-adhan mode. */
        const val EXTRA_SHORT_CUTOFF_SECONDS = "shortCutoffSeconds"
        /** True → use STREAM_ALARM (alarm volume). False → STREAM_RING (ring volume, default). */
        const val EXTRA_USE_ALARM_STREAM     = "useAlarmStream"
        const val ACTION_STOP               = "com.example.quraan.STOP_ADHAN"
        private const val TAG               = "AdhanPlayerService"
        /** Default fallback cutoff when none provided (≈ 2 takbeers). */
        private const val DEFAULT_SHORT_CUTOFF_SECONDS = 15

        /** True while Adhan audio is actively playing.
         *  Checked by MainActivity to intercept volume key presses. */
        @Volatile var isPlaying: Boolean = false
            private set
    }

    // Lifecycle

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            Log.d(TAG, "Stop action received -- stopping")
            stopAdhan()
            stopSelf()
            return START_NOT_STICKY
        }

        val soundName          = intent?.getStringExtra(EXTRA_SOUND) ?: "adhan_1"
        val isShortMode        = intent?.getBooleanExtra(EXTRA_SHORT_MODE, false) ?: false
        val shortCutoffSeconds = intent?.getIntExtra(EXTRA_SHORT_CUTOFF_SECONDS, DEFAULT_SHORT_CUTOFF_SECONDS)
                                   ?: DEFAULT_SHORT_CUTOFF_SECONDS
        val useAlarmStream     = intent?.getBooleanExtra(EXTRA_USE_ALARM_STREAM, false) ?: false

        // Guard: if already playing, stop first (e.g. AlarmManager + in-app both fire).
        if (isPlaying) {
            Log.w(TAG, "onStartCommand: adhan already playing — restarting for $soundName")
        }

        // Must call startForeground() within 5 s of startForegroundService()
        startForeground(NOTIF_ID, buildNotification())
        playAdhan(soundName, isShortMode, shortCutoffSeconds, useAlarmStream)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        cancelShortModeTimer()
        stopAdhan()  // already calls abandonAudioFocus() + releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Audio focus ────────────────────────────────────────────────────────────

    /**
     * Request AUDIOFOCUS_GAIN on the RING stream.
     *
     * Benefits:
     *  • Other apps (music, podcasts) are paused while the adhan plays.
     *  • If an incoming phone call arrives, we receive AUDIOFOCUS_LOSS
     *    and stop the adhan automatically.
     *
     * @return true if focus was granted (we can play), false otherwise.
     */
    private fun requestAudioFocus(audioAttributes: AudioAttributes): Boolean {
        val am = getSystemService(AUDIO_SERVICE) as AudioManager
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            when (change) {
                AudioManager.AUDIOFOCUS_LOSS,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                    Log.d(TAG, "Audio focus lost ($change) — stopping adhan")
                    stopAdhan()
                    stopSelf()
                }
                // AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK: briefly duck for a notification, then continue.
                // We intentionally ignore this — adhan should not be interrupted by a small beep.
            }
        }
        legacyFocusListener = listener

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttributes)
                .setOnAudioFocusChangeListener(listener, Handler(Looper.getMainLooper()))
                .setWillPauseWhenDucked(false)
                .build()
            focusRequest = req
            am.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            // Pre-API 26: map AudioAttributes usage → legacy stream type.
            val legacyStream = if (audioAttributes.usage == AudioAttributes.USAGE_ALARM)
                AudioManager.STREAM_ALARM
            else
                AudioManager.STREAM_RING
            @Suppress("DEPRECATION")
            am.requestAudioFocus(
                listener, legacyStream, AudioManager.AUDIOFOCUS_GAIN
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        val am = getSystemService(AUDIO_SERVICE) as? AudioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { am.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            legacyFocusListener?.let { am.abandonAudioFocus(it) }
        }
        legacyFocusListener = null
    }

    // ── Playback ───────────────────────────────────────────────────────────────

    private fun cancelShortModeTimer() {
        shortModeRunnable?.let { shortModeHandler?.removeCallbacks(it) }
        shortModeHandler = null
        shortModeRunnable = null
    }

    private fun playAdhan(soundName: String, shortMode: Boolean = false, shortCutoffSeconds: Int = DEFAULT_SHORT_CUTOFF_SECONDS, useAlarmStream: Boolean = false) {
        cancelShortModeTimer()
        stopAdhan()
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "quraan:AdhanWakeLock")
            wakeLock?.acquire(10 * 60 * 1_000L) // max 10 minutes

            // ── Audio attributes: Ring (default) or Alarm ─────────────────────────────
            //  Ring (USAGE_NOTIFICATION_RINGTONE):
            //    • Volume controlled by the ring slider.
            //    • Volume-key on lock screen → VOLUME_CHANGED_ACTION → adhan stops.
            //    • Respects Silent/Vibrate mode.
            //  Alarm (USAGE_ALARM):
            //    • Volume controlled by the alarm slider.
            //    • Bypasses Silent/Vibrate — plays even in DND (on most devices).
            //    • VOLUME_CHANGED_ACTION may not fire on lock screen on some OEMs.
            val audioUsage = if (useAlarmStream)
                AudioAttributes.USAGE_ALARM
            else
                AudioAttributes.USAGE_NOTIFICATION_RINGTONE
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(audioUsage)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            Log.d(TAG, "Audio stream: ${if (useAlarmStream) "ALARM" else "RING"}")

            val player = MediaPlayer()
            player.setAudioAttributes(audioAttrs)

            // ── Resolve audio source ───────────────────────────────────────────
            // Online sounds are cached locally. If the cached file exists, use it.
            // If not found (cache cleared / storage pressure), fall back to adhan_1.
            var sourceLoaded = false
            if (soundName.startsWith("online_")) {
                val cachedFile = File("${filesDir.absolutePath}/adhan_cache/${soundName}.mp3")
                if (cachedFile.exists() && cachedFile.length() > 1024) {
                    player.setDataSource(cachedFile.absolutePath)
                    sourceLoaded = true
                    Log.d(TAG, "Adhan: playing cached online file: ${cachedFile.name}")
                } else {
                    Log.w(TAG, "Adhan: cached file missing for '$soundName' — falling back to adhan_1")
                }
            }

            if (!sourceLoaded) {
                val effectiveName = if (soundName.startsWith("online_")) "adhan_1" else soundName
                val resId = resources.getIdentifier(effectiveName, "raw", packageName)
                if (resId == 0) {
                    Log.e(TAG, "Sound resource not found: $effectiveName")
                    player.release()
                    releaseWakeLock()
                    stopSelf(); return
                }
                val afd = resources.openRawResourceFd(resId)
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
            }

            player.setOnCompletionListener {
                Log.d(TAG, "Adhan completed")
                it.release()
                mediaPlayer = null
                isPlaying = false
                releaseWakeLock()
                stopSelf()
            }
            player.setOnErrorListener { mp, what, extra ->
                Log.e(TAG, "MediaPlayer error: what=$what extra=$extra")
                mp.release()
                mediaPlayer = null
                isPlaying = false
                releaseWakeLock()
                stopSelf()
                true
            }

            player.prepare()

            // Request audio focus BEFORE starting playback.
            // If focus is denied (e.g. ongoing call), abort gracefully.
            if (!requestAudioFocus(audioAttrs)) {
                Log.w(TAG, "Audio focus denied — aborting adhan playback")
                player.release()
                releaseWakeLock()
                stopSelf()
                return
            }

            val prefs  = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Flutter stores doubles as Strings in SharedPreferences on Android.
            val volume = prefs.getString("flutter.adhan_volume", null)
                ?.toFloatOrNull()
                ?.coerceIn(0.0f, 1.0f)
                ?: 1.0f
            player.setVolume(volume, volume)
            player.start()
            mediaPlayer = player
            isPlaying = true
            registerVolumeReceiver()
            Log.d(TAG, "Adhan playing: $soundName (shortMode=$shortMode, cutoff=${shortCutoffSeconds}s)")

            // Short mode: auto-stop after the per-sound cutoff (approx. 2 takbeers).
            if (shortMode) {
                val cutoffMs = shortCutoffSeconds * 1000L
                val handler  = Handler(Looper.getMainLooper())
                val runnable = Runnable {
                    Log.d(TAG, "Short mode: auto-stopping adhan after ${shortCutoffSeconds}s")
                    stopAdhan()
                    stopSelf()
                }
                handler.postDelayed(runnable, cutoffMs)
                shortModeHandler  = handler
                shortModeRunnable = runnable
            }
        } catch (e: Exception) {
            Log.e(TAG, "Playback failed: $soundName", e)
            releaseWakeLock()
            stopSelf()
        }
    }

    private fun stopAdhan() {
        cancelShortModeTimer()
        unregisterVolumeReceiver()
        try { mediaPlayer?.stop() }    catch (_: Exception) {}
        try { mediaPlayer?.release() } catch (_: Exception) {}
        mediaPlayer = null
        isPlaying = false
        abandonAudioFocus()
        releaseWakeLock()
    }

    // Volume receiver

    private fun registerVolumeReceiver() {
        if (volumeReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                Log.d(TAG, "Volume changed broadcast received -- stopping Adhan")
                stopAdhan()
                stopSelf()
            }
        }
        try {
            val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(receiver, filter)
            }
            volumeReceiver = receiver
            Log.d(TAG, "Volume receiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register volume receiver", e)
        }
    }

    private fun unregisterVolumeReceiver() {
        volumeReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        volumeReceiver = null
    }

    private fun releaseWakeLock() {
        try { if (wakeLock?.isHeld == true) wakeLock?.release() } catch (_: Exception) {}
        wakeLock = null
    }

    // Notification

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, AdhanPlayerService::class.java).apply { action = ACTION_STOP }
        val stopPi = PendingIntent.getService(
            this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openPi = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 1, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        val iconRes = resources.getIdentifier("ic_notification", "drawable", packageName)
            .takeIf { it != 0 } ?: R.mipmap.ic_launcher

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(iconRes)
            .setContentTitle("الأذان")
            .setContentText("اضغط لوقف الأذان")
            .setContentIntent(openPi)
            .setOngoing(true)
            .addAction(
                Notification.Action.Builder(
                    null,
                    "ايقاف الاذان",
                    stopPi
                ).build()
            )
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adhan Player",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Adhan audio playback foreground service"
                setSound(null, null)
                enableVibration(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }
}