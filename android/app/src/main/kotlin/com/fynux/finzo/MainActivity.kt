package com.fynux.finzo

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.auth.api.phone.SmsRetrieverClient
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fynux.finzo/sms_consent"
    private val SMS_CONSENT_REQUEST_CODE = 1001
    private var pendingSmsResult: MethodChannel.Result? = null
    private var smsConsentReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsConsent" -> {
                    requestSmsConsent(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestSmsConsent(result: MethodChannel.Result) {
        Log.d("SmsConsent", "Starting SMS consent request")
        
        // Check if Google Play Services is available
        val apiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = apiAvailability.isGooglePlayServicesAvailable(this)
        if (resultCode != com.google.android.gms.common.ConnectionResult.SUCCESS) {
            Log.e("SmsConsent", "Google Play Services not available: $resultCode")
            result.error("GOOGLE_PLAY_SERVICES_UNAVAILABLE", "Google Play Services is not available. Please update Google Play Services.", null)
            return
        }
        
        // Cancel any previous pending request
        pendingSmsResult?.error("CANCELLED", "New SMS consent request started", null)
        pendingSmsResult = null
        
        // Clean up any existing receiver
        smsConsentReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d("SmsConsent", "Unregistered previous receiver")
            } catch (e: Exception) {
                // Ignore if already unregistered
            }
        }
        smsConsentReceiver = null
        
        try {
            pendingSmsResult = result
            
            // Register BroadcastReceiver to receive SMS consent result
            // ✅ CORRECT: Listen for SMS_RETRIEVED_ACTION (not SMS_RETRIEVER_DONE)
            smsConsentReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    Log.d("SmsConsent", "BroadcastReceiver received: ${intent.action}")
                    
                    // ✅ CORRECT: Check for SMS_RETRIEVED_ACTION
                    if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                        val extras = intent.extras ?: return
                        val status = extras.get(SmsRetriever.EXTRA_STATUS) as? Status ?: return
                        Log.d("SmsConsent", "Status code: ${status.statusCode}")
                        
                        when (status.statusCode) {
                            CommonStatusCodes.SUCCESS -> {
                                // ✅ CRITICAL: Get consent intent and launch activity
                                val consentIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    extras.getParcelable(SmsRetriever.EXTRA_CONSENT_INTENT, Intent::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                                }
                                if (consentIntent != null) {
                                    Log.d("SmsConsent", "Launching consent activity")
                                    try {
                                        startActivityForResult(consentIntent, SMS_CONSENT_REQUEST_CODE)
                                    } catch (e: Exception) {
                                        Log.e("SmsConsent", "Failed to launch consent activity: ${e.message}", e)
                                        pendingSmsResult?.error("ERROR", "Failed to show consent dialog: ${e.message}", null)
                                        pendingSmsResult = null
                                        _cleanupReceiver()
                                    }
                                } else {
                                    Log.e("SmsConsent", "Consent intent is null")
                                    pendingSmsResult?.error("ERROR", "Consent intent not available", null)
                                    pendingSmsResult = null
                                    _cleanupReceiver()
                                }
                            }
                            CommonStatusCodes.TIMEOUT -> {
                                Log.d("SmsConsent", "Timeout from SMS Retriever")
                                pendingSmsResult?.error("TIMEOUT", "SMS consent timeout", null)
                                pendingSmsResult = null
                                _cleanupReceiver()
                            }
                            else -> {
                                Log.d("SmsConsent", "Error status: ${status.statusCode}")
                                pendingSmsResult?.error("ERROR", "SMS consent error: ${status.statusCode}", null)
                                pendingSmsResult = null
                                _cleanupReceiver()
                            }
                        }
                    }
                }
            }
            
            // ✅ CORRECT: Register receiver with SMS_RETRIEVED_ACTION
            val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
            // SMS Retriever broadcasts come from Google Play Services (external app)
            // Use RECEIVER_EXPORTED to allow receiving broadcasts from Google Play Services
            // This flag is required for Android 13+ (API 33+) when targetSdk is 33+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(smsConsentReceiver, intentFilter, Context.RECEIVER_EXPORTED)
                Log.d("SmsConsent", "Registered receiver with RECEIVER_EXPORTED flag")
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(smsConsentReceiver, intentFilter)
                Log.d("SmsConsent", "Registered receiver (deprecated method)")
            }
            
            // Get an instance of SmsRetrieverClient
            val client: SmsRetrieverClient = SmsRetriever.getClient(this)
            Log.d("SmsConsent", "Got SmsRetrieverClient, starting consent flow")
            
            // Start SMS User Consent flow
            // This will show Android system dialog with SMS messages
            // User selects one SMS and taps Allow
            val task = client.startSmsUserConsent(null)
            
            task.addOnSuccessListener {
                Log.d("SmsConsent", "SMS User Consent flow started successfully - waiting for user selection")
                // Successfully started SMS User Consent
                // Android will show system dialog, user selects SMS
                // Result will come via BroadcastReceiver
            }.addOnFailureListener { e ->
                Log.e("SmsConsent", "Failed to start SMS consent: ${e.message}", e)
                try {
                    unregisterReceiver(smsConsentReceiver)
                } catch (ex: Exception) {
                    // Ignore
                }
                smsConsentReceiver = null
                pendingSmsResult?.error("SMS_CONSENT_ERROR", "Failed to start SMS consent: ${e.message}", null)
                pendingSmsResult = null
            }
        } catch (e: Exception) {
            Log.e("SmsConsent", "Exception in requestSmsConsent: ${e.message}", e)
            if (smsConsentReceiver != null) {
                try {
                    unregisterReceiver(smsConsentReceiver)
                } catch (ex: Exception) {
                    // Ignore
                }
                smsConsentReceiver = null
            }
            pendingSmsResult?.error("SMS_CONSENT_ERROR", "Error: ${e.message}", null)
            pendingSmsResult = null
        }
    }

    // ✅ CRITICAL: Handle result from consent activity
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == SMS_CONSENT_REQUEST_CODE) {
            Log.d("SmsConsent", "onActivityResult: resultCode=$resultCode")
            
            if (resultCode == Activity.RESULT_OK && data != null) {
                // ✅ User granted consent - get SMS message
                val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                Log.d("SmsConsent", "SMS message received, length: ${message?.length ?: 0}")
                
                pendingSmsResult?.success(message ?: "")
                pendingSmsResult = null
            } else {
                // User denied consent or cancelled
                Log.d("SmsConsent", "User denied SMS consent or cancelled")
                pendingSmsResult?.error("DENIED", "User denied SMS consent", null)
                pendingSmsResult = null
            }
            
            _cleanupReceiver()
        }
    }
    
    private fun _cleanupReceiver() {
        smsConsentReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d("SmsConsent", "Unregistered receiver")
            } catch (e: Exception) {
                // Ignore if already unregistered
            }
        }
        smsConsentReceiver = null
    }

    override fun onDestroy() {
        super.onDestroy()
        _cleanupReceiver()
        // Cancel any pending result to prevent hanging
        pendingSmsResult?.error("CANCELLED", "Activity destroyed", null)
        pendingSmsResult = null
    }
}
