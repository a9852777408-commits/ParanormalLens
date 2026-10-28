package com.paranormallens.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.SoundPool
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.paranormallens.app/audio"
    private var methodChannel: MethodChannel? = null
    private var mediaPlayer: MediaPlayer? = null
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()

    // Sacred Prayer Voice Detection
    private var isListeningPrayer = false
    private var isRecordingAudio = false
    private var audioRecordThread: Thread? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private val prayerKeywords = listOf(
        "отче", "наш", "господи", "помилуй", "изыди", "боже",
        "святый", "аминь", "крест", "воскреснет", "христос",
        "иисус", "спаси", "сохрани", "молитва", "дух"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initSoundPool()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
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
                "startPrayerListening" -> {
                    startPrayerListening()
                    result.success(true)
                }
                "stopPrayerListening" -> {
                    stopPrayerListening()
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

    // --- Sacred Prayer Voice Detection Implementation ---
    private fun startPrayerListening() {
        if (isListeningPrayer) return
        isListeningPrayer = true

        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 101)
            return
        }

        startSpeechRecognizer()
        startAudioEnergyMonitor()
    }

    private fun stopPrayerListening() {
        isListeningPrayer = false
        isRecordingAudio = false
        try {
            audioRecordThread?.interrupt()
            audioRecordThread = null
        } catch (_: Exception) {}

        runOnUiThread {
            try {
                speechRecognizer?.stopListening()
                speechRecognizer?.destroy()
                speechRecognizer = null
            } catch (_: Exception) {}
        }
    }

    private fun startSpeechRecognizer() {
        runOnUiThread {
            try {
                if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                    return@runOnUiThread
                }
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                    setRecognitionListener(object : RecognitionListener {
                        override fun onReadyForSpeech(params: Bundle?) {}
                        override fun onBeginningOfSpeech() {}
                        override fun onRmsChanged(rmsdB: Float) {
                            if (rmsdB > 2.0f) {
                                val normalized = (rmsdB / 12.0f).coerceIn(0.0f, 1.0f)
                                methodChannel?.invokeMethod("onVoiceEnergy", mapOf("energy" to normalized))
                            }
                        }
                        override fun onBufferReceived(buffer: ByteArray?) {}
                        override fun onEndOfSpeech() {}
                        override fun onError(error: Int) {
                            if (isListeningPrayer) {
                                Handler(Looper.getMainLooper()).postDelayed({
                                    if (isListeningPrayer) startSpeechRecognizer()
                                }, 600)
                            }
                        }
                        override fun onResults(results: Bundle?) {
                            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            checkMatchesForPrayer(matches)
                            if (isListeningPrayer) {
                                startSpeechRecognizer()
                            }
                        }
                        override fun onPartialResults(partialResults: Bundle?) {
                            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            checkMatchesForPrayer(matches)
                        }
                        override fun onEvent(eventType: Int, params: Bundle?) {}
                    })
                }

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ru-RU")
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                }
                speechRecognizer?.startListening(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun checkMatchesForPrayer(matches: ArrayList<String>?) {
        if (matches == null) return
        for (text in matches) {
            val lower = text.lowercase()
            for (kw in prayerKeywords) {
                if (lower.contains(kw)) {
                    Handler(Looper.getMainLooper()).post {
                        methodChannel?.invokeMethod(
                            "onPrayerRecognized",
                            mapOf(
                                "phrase" to text,
                                "keyword" to kw,
                                "source" to "speech_recognition"
                            )
                        )
                    }
                    return
                }
            }
        }
    }

    private fun startAudioEnergyMonitor() {
        isRecordingAudio = true
        audioRecordThread = Thread {
            val sampleRate = 16000
            val bufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            if (bufferSize <= 0) return@Thread

            var audioRecord: AudioRecord? = null
            try {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
                if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                    audioRecord.release()
                    return@Thread
                }
                audioRecord.startRecording()
                val buffer = ShortArray(bufferSize)
                var sustainedLoudFrames = 0

                while (isRecordingAudio) {
                    val read = audioRecord.read(buffer, 0, buffer.size)
                    if (read > 0) {
                        var sum = 0.0
                        for (i in 0 until read) {
                            sum += buffer[i] * buffer[i]
                        }
                        val rms = Math.sqrt(sum / read)
                        val normalizedEnergy = (rms / 5500.0).coerceIn(0.0, 1.0)

                        if (normalizedEnergy > 0.12) {
                            Handler(Looper.getMainLooper()).post {
                                methodChannel?.invokeMethod("onVoiceEnergy", mapOf("energy" to normalizedEnergy))
                            }
                        }

                        // If user chants/prays continuously into mic (> 1.2s):
                        if (normalizedEnergy > 0.38) {
                            sustainedLoudFrames++
                            if (sustainedLoudFrames >= 10) {
                                sustainedLoudFrames = 0
                                Handler(Looper.getMainLooper()).post {
                                    methodChannel?.invokeMethod(
                                        "onPrayerRecognized",
                                        mapOf(
                                            "phrase" to "«СВЯЩЕННАЯ МОЛИТВА ИЗГНАНИЯ»",
                                            "source" to "voice_chant"
                                        )
                                    )
                                }
                            }
                        } else {
                            if (sustainedLoudFrames > 0) sustainedLoudFrames--
                        }
                    }
                    Thread.sleep(100)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                try {
                    audioRecord?.stop()
                    audioRecord?.release()
                } catch (_: Exception) {}
            }
        }
        audioRecordThread?.start()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 101 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            if (isListeningPrayer) {
                startSpeechRecognizer()
                startAudioEnergyMonitor()
            }
        }
    }

    override fun onDestroy() {
        stopPrayerListening()
        mediaPlayer?.release()
        mediaPlayer = null
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
