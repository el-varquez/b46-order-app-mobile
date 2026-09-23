package com.b46.orderapp

import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class GoogleNonceRequestFactoryTest {
    @Test
    fun eachRequestCarriesItsOwnNonce() {
        val first = GoogleNonceRequestFactory.build("web-client-id", "first-intent")
        val second = GoogleNonceRequestFactory.build("web-client-id", "second-intent")

        val firstOption = first.credentialOptions.single() as GetSignInWithGoogleOption
        val secondOption = second.credentialOptions.single() as GetSignInWithGoogleOption
        assertEquals("first-intent", firstOption.nonce)
        assertEquals("second-intent", secondOption.nonce)
    }
}
