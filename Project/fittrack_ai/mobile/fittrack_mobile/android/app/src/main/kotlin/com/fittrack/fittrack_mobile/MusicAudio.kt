package com.fittrack.fittrack_mobile

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.sin
import kotlin.math.sqrt

/** Local-only reference audio and pitch detection. Microphone PCM never crosses the channel. */
internal class MusicAudio(private val activity: Activity, messenger: BinaryMessenger) {
    private val method = MethodChannel(messenger, "ancai/music/audio")
    private val stream = EventChannel(messenger, "ancai/music/pitch")
    private val handler = Handler(Looper.getMainLooper())
    private var playback: AudioTrack? = null
    private var permission: MethodChannel.Result? = null
    @Volatile private var capture: AudioRecord? = null
    private var generation = 0

    init {
        method.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val notes = call.argument<List<Number>>("frequencies")
                        ?.map { it.toDouble() }
                        ?.takeIf { it.isNotEmpty() && it.size <= 6 && it.all { hz -> hz in 50.0..3000.0 } }
                    if (notes == null) {
                        result.error("audio", "Tần số tham chiếu không hợp lệ.", null)
                    } else {
                        try {
                            play(notes, (call.argument<Int>("milliseconds") ?: 380).coerceIn(15, 600))
                            result.success(null)
                        } catch (_: RuntimeException) {
                            result.error("audio", "Thiết bị không phát được âm tham chiếu.", null)
                        }
                    }
                }
                "permission" -> when {
                    microphoneAllowed() -> result.success(true)
                    permission != null -> result.success(false)
                    else -> {
                        permission = result
                        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), permissionCode)
                    }
                }
                "stopPlayback" -> { releasePlayback(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        stream.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) = listen(events)
            override fun onCancel(arguments: Any?) = stopRecording()
        })
    }

    private fun microphoneAllowed() = activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
        PackageManager.PERMISSION_GRANTED

    fun permissionResult(request: Int, grants: IntArray) {
        if (request != permissionCode) return
        permission?.success(grants.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        permission = null
    }

    private fun play(notes: List<Double>, milliseconds: Int) {
        releasePlayback()
        val size = outputRate * milliseconds / 1000
        val pcm = ShortArray(size) { sample ->
            val t = sample.toDouble() / outputRate
            val signal = notes.sumOf { hz -> sin(2 * PI * hz * t) }
            val envelope = (sample / (outputRate * 0.004)).coerceAtMost(1.0) *
                exp(-3.5 * sample / size) * ((size - sample) / (outputRate * 0.008)).coerceAtMost(1.0)
            (signal / notes.size * envelope * 12500).toInt().toShort()
        }
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
            .setAudioFormat(AudioFormat.Builder().setSampleRate(outputRate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setBufferSizeInBytes(pcm.size * 2).setTransferMode(AudioTrack.MODE_STATIC).build()
        playback = track
        try {
            check(track.write(pcm, 0, pcm.size) == pcm.size)
            track.play()
        } catch (error: RuntimeException) {
            releasePlayback()
            throw error
        }
        handler.postDelayed({ if (playback === track) releasePlayback() }, milliseconds + 40L)
    }

    private fun releasePlayback() {
        val track = playback ?: return
        playback = null
        runCatching { track.stop() }
        track.release()
    }

    private fun listen(events: EventChannel.EventSink) {
        stopRecording()
        if (!microphoneAllowed()) {
            events.error("permission", "Chưa cấp quyền micrô.", null)
            return
        }
        val current = ++generation
        val config = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        // 16 kHz is supported by the Android compatibility definition.
        val min = AudioRecord.getMinBufferSize(inputRate, config, encoding)
        val recorder = try {
            AudioRecord(MediaRecorder.AudioSource.DEFAULT, inputRate, config, encoding, maxOf(min, frameSize * 4))
        } catch (_: RuntimeException) {
            events.error("microphone", "Không thể mở micrô.", null)
            return
        }
        capture = recorder
        Thread {
            try {
                if (capture !== recorder) return@Thread
                recorder.startRecording()
                val samples = ShortArray(frameSize)
                while (capture === recorder) {
                    var count = 0
                    while (count < samples.size && capture === recorder) {
                        val received = recorder.read(samples, count, samples.size - count)
                        if (received <= 0) error("AudioRecord.read failed")
                        count += received
                    }
                    if (capture !== recorder || count != samples.size) break
                    val frequency = pitch(samples)
                    handler.post { if (current == generation) events.success(frequency) }
                }
            } catch (_: RuntimeException) {
                handler.post {
                    if (current == generation) events.error("microphone", "Micrô không đọc được âm thanh.", null)
                }
            } finally {
                runCatching { recorder.stop() }
                recorder.release()
                handler.post { if (capture === recorder) capture = null }
            }
        }.apply { name = "AnCaiPitch"; start() }
    }

    private fun stopRecording() {
        generation++
        val old = capture
        capture = null
        runCatching { old?.stop() }
    }

    private fun pitch(raw: ShortArray): Double? {
        val mean = raw.average()
        val data = raw.map { it - mean }.toDoubleArray()
        if (sqrt(data.sumOf { it * it } / data.size) < 140) return null
        val firstLag = inputRate / 2100
        val lastLag = inputRate / 70
        val confidence = DoubleArray(lastLag + 2)
        for (lag in firstLag - 1..lastLag + 1) {
            var cross = 0.0
            var energy = 0.0
            for (i in 0 until data.size - lag) {
                val a = data[i]
                val b = data[i + lag]
                cross += a * b
                energy += a * a + b * b
            }
            if (energy > 0) confidence[lag] = 2 * cross / energy
        }
        val candidates = (firstLag..lastLag).filter { lag ->
            confidence[lag] >= 0.78 && confidence[lag] > confidence[lag - 1] &&
                confidence[lag] >= confidence[lag + 1]
        }
        val best = candidates.maxOfOrNull { confidence[it] } ?: return null
        val lag = candidates.first { confidence[it] >= best * 0.91 }
        val before = confidence[lag - 1]
        val center = confidence[lag]
        val after = confidence[lag + 1]
        val curve = before - 2 * center + after
        val shift = if (abs(curve) < 0.000001) 0.0 else (0.5 * (before - after) / curve).coerceIn(-0.5, 0.5)
        return inputRate / (lag + shift)
    }

    fun stop() { stopRecording(); releasePlayback() }

    fun dispose() {
        stop()
        handler.removeCallbacksAndMessages(null)
        permission?.success(false)
        permission = null
        method.setMethodCallHandler(null)
        stream.setStreamHandler(null)
    }

    private companion object {
        const val permissionCode = 9703
        const val inputRate = 16000
        const val outputRate = 22050
        const val frameSize = 2048
    }
}
