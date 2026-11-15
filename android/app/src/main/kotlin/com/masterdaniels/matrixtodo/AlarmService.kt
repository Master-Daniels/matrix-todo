package com.masterdaniels.matrixtodo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Dedicated foreground service providing robust, uninterrupted alarm playback
 * on Android.
 *
 * Runs with foregroundServiceType="mediaPlayback", loops overdue_tone on
 * USAGE_ALARM, and holds AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE so incoming
 * notification alerts never mute, duck, or terminate the active ringer.
 */
class AlarmService : Service() {
    companion object {
        const val ACTION_START_ALARM = "com.masterdaniels.matrixtodo.START_ALARM"
        const val ACTION_STOP_ALARM = "com.masterdaniels.matrixtodo.STOP_ALARM"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NID = "nid"
        const val CHANNEL_ID = "matrix_alarms_v5"
        const val DEFAULT_NOTIFICATION_ID = 999991

        private var isRunning = false
        fun isActive(): Boolean = isRunning
    }

    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var focusChangeListener: AudioManager.OnAudioFocusChangeListener? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_ALARM
        if (action == ACTION_STOP_ALARM) {
            stopAlarmPlayback()
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Task Alarm"
        val body = intent?.getStringExtra(EXTRA_BODY) ?: "Task is starting now"
        val nid = intent?.getIntExtra(EXTRA_NID, DEFAULT_NOTIFICATION_ID) ?: DEFAULT_NOTIFICATION_ID

        startAlarmPlayback(title, body, nid)
        return START_NOT_STICKY
    }

    private fun startAlarmPlayback(title: String, body: String, nid: Int) {
        isRunning = true
        createNotificationChannelIfNeeded()

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()

        startForeground(nid, notification)

        requestAlarmAudioFocus()
        playOverdueTone()
    }

    private fun requestAlarmAudioFocus() {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            Log.d("AlarmService", "AudioFocus changed: $focusChange")
            // Crucial: Incoming notifications emit AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK.
            // For alarms, we intentionally ignore ducking to keep ringing at full volume.
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(false)
                .setWillPauseWhenDucked(false)
                .setOnAudioFocusChangeListener(focusChangeListener!!)
                .build()
            focusRequest = req
            audioManager?.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                focusChangeListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
            )
        }
    }

    private fun playOverdueTone() {
        try {
            mediaPlayer?.release()
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(audioAttributes)
                setVolume(1.0f, 1.0f)
                isLooping = true
                val afd = resources.openRawResourceFd(R.raw.overdue_tone)
                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                }
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AlarmService", "Failed to start media player", e)
        }
    }

    private fun stopAlarmPlayback() {
        isRunning = false
        try {
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            Log.w("AlarmService", "Error releasing media player", e)
        }

        abandonAlarmAudioFocus()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun abandonAlarmAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(focusChangeListener)
        }
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            if (notificationManager?.getNotificationChannel(CHANNEL_ID) == null) {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Alarms",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Task alarm ringers"
                    setSound(null, audioAttributes)
                }
                notificationManager?.createNotificationChannel(channel)
            }
        }
    }

    override fun onDestroy() {
        stopAlarmPlayback()
        super.onDestroy()
    }
}
