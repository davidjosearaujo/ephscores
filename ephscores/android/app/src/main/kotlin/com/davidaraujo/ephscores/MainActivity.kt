package com.davidaraujo.ephscores

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity, so the screen-lock prompt (local_auth) can be shown.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Blocks screenshots, screen recording and the recent-apps thumbnail
        // while the patient history is open.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ephscores/secure")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    val flag = WindowManager.LayoutParams.FLAG_SECURE
                    if (call.arguments == true) window.addFlags(flag) else window.clearFlags(flag)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
