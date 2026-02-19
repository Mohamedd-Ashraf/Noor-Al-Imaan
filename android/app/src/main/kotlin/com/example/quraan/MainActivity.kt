package com.example.quraan

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val adhanChannel = "quraan/adhan_player"
	private var adhanPlayer: MediaPlayer? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"playAdhan" -> {
						val soundName = call.argument<String>("soundName") ?: "adhan_1"
						result.success(playAdhanNative(soundName))
					}
					"stopAdhan" -> {
						stopAdhanNative()
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun playAdhanNative(soundName: String): Boolean {
		return try {
			stopAdhanNative()

			// Resolve the raw resource ID dynamically so any of the 10 sounds can be played
			val resId = resources.getIdentifier(soundName, "raw", packageName)
			if (resId == 0) {
				Log.e("MainActivity", "Sound resource not found: $soundName")
				return false
			}

			val afd = applicationContext.resources.openRawResourceFd(resId) ?: return false
			val player = MediaPlayer()
			player.setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
			player.setAudioAttributes(
				AudioAttributes.Builder()
					.setUsage(AudioAttributes.USAGE_ALARM)
					.setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
					.build()
			)
			player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
			afd.close()

			player.setOnCompletionListener {
				it.release()
				if (adhanPlayer === it) {
					adhanPlayer = null
				}
			}
			player.setOnErrorListener { mp, _, _ ->
				mp.release()
				if (adhanPlayer === mp) {
					adhanPlayer = null
				}
				true
			}

			player.prepare()
			player.start()
			adhanPlayer = player
			Log.d("MainActivity", "Adhan started: $soundName")
			true
		} catch (e: Exception) {
			Log.e("MainActivity", "Native Adhan playback failed: $soundName", e)
			false
		}
	}

	private fun stopAdhanNative() {
		try {
			adhanPlayer?.stop()
		} catch (_: Exception) {
		}

		try {
			adhanPlayer?.release()
		} catch (_: Exception) {
		}

		adhanPlayer = null
	}

	override fun onDestroy() {
		stopAdhanNative()
		super.onDestroy()
	}
}
