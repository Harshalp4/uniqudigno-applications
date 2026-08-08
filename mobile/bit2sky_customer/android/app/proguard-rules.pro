# Razorpay — the checkout SDK is driven through a JS bridge and reflective
# payment callbacks, both of which R8 strips without these.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Google Pay / ProxyGoogleFactory is referenced by Razorpay but not bundled.
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# local_auth uses androidx.biometric prompt callbacks reflectively.
-keep class androidx.biometric.** { *; }

# Flutter deferred components / split debug info.
-keep class io.flutter.embedding.** { *; }

# The Flutter engine references Play Core for deferred components. This app has
# no deferred components and doesn't depend on Play Core, so those classes are
# genuinely absent — tell R8 that's expected instead of failing the build.
-dontwarn com.google.android.play.core.**
