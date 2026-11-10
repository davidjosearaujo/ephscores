package com.davidaraujo.ephscores

import android.content.Intent
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
        // launcher shortcut the app was started with.
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ephscores/android")
        channel?.setMethodCallHandler { call, result ->
            val flag = when (call.method) {
                "setSecure" -> WindowManager.LayoutParams.FLAG_SECURE
                "keepScreenOn" -> WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                else -> null
            }
            when {
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

    private companion object {
        const val SHORTCUT = "shortcut"
    }
}
