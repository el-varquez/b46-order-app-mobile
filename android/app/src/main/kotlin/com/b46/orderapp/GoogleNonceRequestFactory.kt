package com.b46.orderapp

import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption

internal object GoogleNonceRequestFactory {
    fun build(serverClientId: String, nonce: String): GetCredentialRequest =
        GetCredentialRequest.Builder()
            .addCredentialOption(
                GetSignInWithGoogleOption.Builder(serverClientId)
                    .setNonce(nonce)
                    .build()
            )
            .build()
}
