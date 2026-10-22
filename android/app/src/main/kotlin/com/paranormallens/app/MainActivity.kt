package com.paranormallens.app

import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.paranormallens.app/audio"
    private var mediaPlayer: MediaPlayer? = null
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initSoundPool()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAmbient" -> {
                    playAmbient()
                    result.success(true)
                }
                "stopAmbient" -> {
                    stopAmbient()
                    result.success(true)
                }
                "playSfx" -> {
                    val name = call.argument<String>("name") ?: ""
                    playSfx(name)
                    result.success(true)
                }
                "setAmbientVolume" -> {
                    val vol = (call.argument<Double>("volume") ?: 0.35).toFloat()
                    mediaPlayer?.setVolume(vol, vol)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initSoundPool() {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(8)
            .setAudioAttributes(audioAttributes)
            .build()

        loadSound("geiger_tick")
        loadSound("holy_dawn_bell")
        loadSound("jumpscare_screech")
        loadSound("raven_window")
        loadSound("whisper_chills")
    }

    private fun loadSound(name: String) {
        try {
            val flutterKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/audio/$name.wav")
            val afd: AssetFileDescriptor = assets.openFd(flutterKey)
            val soundId = soundPool?.load(afd, 1) ?: 0
            if (soundId > 0) {
                soundMap[name] = soundId
            }
        } catch (e: Exception) {
            try {
                val afd = assets.openFd("flutter_assets/assets/audio/$name.wav")
                val soundId = soundPool?.load(afd, 1) ?: 0
                if (soundId > 0) {
                    soundMap[name] = soundId
                }
            } catch (e2: Exception) {
                // Sound file not present
            }
        }
    }

    private fun playAmbient() {
        try {
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer()
                val flutterKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/audio/ambient_drone.wav")
                val afd = assets.openFd(flutterKey)
                mediaPlayer?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                mediaPlayer?.isLooping = true
                mediaPlayer?.setVolume(0.35f, 0.35f)
                mediaPlayer?.prepare()
            }
            if (mediaPlayer?.isPlaying == false) {
                mediaPlayer?.start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAmbient() {
        try {
            mediaPlayer?.pause()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun playSfx(name: String) {
        val soundId = soundMap[name]
        if (soundId != null && soundId > 0) {
            soundPool?.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
        }
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
