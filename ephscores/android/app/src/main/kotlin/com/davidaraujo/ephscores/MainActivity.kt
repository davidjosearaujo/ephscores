package com.davidaraujo.ephscores

import android.content.Intent
import android.graphics.Rect
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity, so the screen-lock prompt (local_auth) can be shown.
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null

    // The launcher shortcut that started the app, until Dart asks for it.
    private var launchShortcut: String? = null

    // The beep of the CPR metronome, created on first use.
    private var tone: ToneGenerator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            launchShortcut = intent?.getStringExtra(SHORTCUT)
        }
    }

    // A shortcut used while the app is already running.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(SHORTCUT)?.let { channel?.invokeMethod("shortcut", it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // setSecure blocks screenshots, screen recording and the recent-apps
        // thumbnail while the patient history is open; keepScreenOn keeps
        // the screen lit during a birth; takeShortcut hands over the
        // launcher shortcut the app was started with; click is one beep of
        // the CPR metronome; excludeGestures frees the CPR tab from the
        // system back swipe.
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ephscores/android")
        channel?.setMethodCallHandler { call, result ->
            val flag = when (call.method) {
                "setSecure" -> WindowManager.LayoutParams.FLAG_SECURE
                "keepScreenOn" -> WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                else -> null
            }
            when {
                call.method == "click" -> {
                    beep()
                    result.success(null)
                }
                call.method == "excludeGestures" -> {
                    excludeGestures(call.arguments as? List<*>)
                    result.success(null)
                }
                call.method == "takeShortcut" -> {
                    result.success(launchShortcut)
                    launchShortcut = null
                }
                flag == null -> result.notImplemented()
                else -> {
                    if (call.arguments == true) window.addFlags(flag) else window.clearFlags(flag)
                    result.success(null)
                }
            }
        }
    }

    // Keeps the system back swipe off the CPR tab at the screen edge, so it
    // can be dragged; a list of left, top, right, bottom in pixels, or
    // empty to put the swipe back.
    private fun excludeGestures(area: List<*>?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val v = area?.mapNotNull { (it as? Number)?.toInt() }
        window.decorView.systemGestureExclusionRects =
            if (v == null || v.size != 4) emptyList() else listOf(Rect(v[0], v[1], v[2], v[3]))
    }

    private fun beep() {
        try {
            val generator = tone ?: ToneGenerator(AudioManager.STREAM_MUSIC, 100).also { tone = it }
            generator.startTone(ToneGenerator.TONE_PROP_BEEP)
        } catch (e: RuntimeException) {
            // No audio available: the metronome keeps its visual beat.
        }
    }

    override fun onDestroy() {
        tone?.release()
        tone = null
        super.onDestroy()
    }

    private companion object {
        const val SHORTCUT = "shortcut"
    }
}
