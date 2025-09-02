package com.example.expense_tracker

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.expense_tracker/sms"
    private var smsBody: String? = null
    private var smsSender: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        intent?.extras?.let {
            smsBody = it.getString("sms_body")
            smsSender = it.getString("sms_sender")
        }

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSmsLaunchData") {
                val data = hashMapOf("body" to (smsBody ?: ""), "sender" to (smsSender ?: ""))
                result.success(data)
            } else {
                result.notImplemented()
            }
        }
    }
}
