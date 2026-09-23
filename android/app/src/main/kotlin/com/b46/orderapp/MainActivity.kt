package com.b46.orderapp

import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.CredentialManagerCallback
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

class MainActivity : FlutterActivity() {
    private val callbackExecutor = Executor { command -> runOnUiThread(command) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.b46.orderapp/google_auth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "authenticate" -> {
                        val serverClientId = call.argument<String>("serverClientId")
                        val nonce = call.argument<String>("nonce")
                        if (serverClientId.isNullOrBlank() || nonce.isNullOrBlank()) {
                            result.error("not_configured", "Google sign-in configuration is missing.", null)
                        } else {
                            authenticate(serverClientId, nonce, result)
                        }
                    }
                    "signOut" -> signOut(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun authenticate(serverClientId: String, nonce: String, result: MethodChannel.Result) {
        val request = GoogleNonceRequestFactory.build(serverClientId, nonce)
        CredentialManager.create(this).getCredentialAsync(
            this,
            request,
            null,
            callbackExecutor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    val credential = response.credential
                    if (credential !is CustomCredential ||
                        credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
                    ) {
                        result.error("provider_error", "Google did not return an identity token.", null)
                        return
                    }
                    try {
                        val token = GoogleIdTokenCredential.createFrom(credential.data).idToken
                        if (token.isBlank()) {
                            result.error("provider_error", "Google returned an empty identity token.", null)
                        } else {
                            result.success(token)
                        }
                    } catch (_: Exception) {
                        result.error("provider_error", "Google identity token could not be read.", null)
                    }
                }

                override fun onError(error: GetCredentialException) {
                    if (error is GetCredentialCancellationException) {
                        result.error("cancelled", "Google sign-in was cancelled.", null)
                    } else {
                        result.error("provider_error", "Google sign-in is unavailable.", null)
                    }
                }
            }
        )
    }

    private fun signOut(result: MethodChannel.Result) {
        CredentialManager.create(this).clearCredentialStateAsync(
            ClearCredentialStateRequest(),
            null,
            callbackExecutor,
            object : CredentialManagerCallback<Void?, ClearCredentialException> {
                override fun onResult(value: Void?) {
                    result.success(null)
                }

                override fun onError(error: ClearCredentialException) {
                    result.error("provider_error", "Google sign-out could not clear provider state.", null)
                }
            }
        )
    }
}
