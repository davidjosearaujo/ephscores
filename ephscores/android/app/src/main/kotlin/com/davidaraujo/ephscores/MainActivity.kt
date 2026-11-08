package com.davidaraujo.ephscores

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity, so the screen-lock prompt (local_auth) can be shown.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // setSecure blocks screenshots, screen recording and the recent-apps
        // thumbnail while the patient history is open; keepScreenOn keeps
        // the screen lit during a birth.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ephscores/window")
            .setMethodCallHandler { call, result ->
                val flag = when (call.method) {
                    "setSecure" -> WindowManager.LayoutParams.FLAG_SECURE
                    "keepScreenOn" -> WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    else -> null
                }
                if (flag == null) {
                    result.notImplemented()
                } else {
                    if (call.arguments == true) window.addFlags(flag) else window.clearFlags(flag)
                    result.success(null)
                }
            }
    }
}
