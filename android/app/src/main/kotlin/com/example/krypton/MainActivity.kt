package com.example.krypton

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.autofill.AutofillManager
import android.provider.Settings
import android.content.Intent
import android.net.Uri
import android.app.Activity
import android.util.Log

class MainActivity: FlutterFragmentActivity() {
	private val CHANNEL = "com.example.krypton/autofill"
	private val REQUEST_CODE_SET_AUTOFILL_SERVICE = 0xF123
	private var pendingResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"hasEnabledAutofillServices" -> {
					try {
						val manager = getSystemService(AutofillManager::class.java)
						val enabled = try { manager.hasEnabledAutofillServices() } catch (e: Exception) { false }
						result.success(enabled)
					} catch (e: Exception) {
						result.success(false)
					}
				}
				"requestSetAutofillService" -> {
					// Launch settings intent and return result asynchronously
					pendingResult = result
					try {
						val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
						intent.data = Uri.parse("package:${applicationContext.packageName}")
						startActivityForResult(intent, REQUEST_CODE_SET_AUTOFILL_SERVICE)
					} catch (e: Exception) {
						pendingResult = null
						result.success(false)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == REQUEST_CODE_SET_AUTOFILL_SERVICE) {
			pendingResult?.let { r ->
				r.success(resultCode == Activity.RESULT_OK)
				pendingResult = null
			}
		}
	}
}
 
