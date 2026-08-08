pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8, not 9. Flutter 3.44.8's Gradle plugin still casts the Android
    // extension to the old-DSL AbstractAppExtension, so it cannot apply under
    // AGP 9's new DSL — and AGP 9's built-in Kotlin requires that new DSL. The
    // two are mutually exclusive until Flutter ships new-DSL support; AGP 8.13
    // is the newest release that works here and it supports compileSdk 36.
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Google Services (Firebase). Declared here but applied in app/build.gradle.kts
    // ONLY when google-services.json exists, so a checkout without the Firebase
    // config still builds (push stays off until the file is added).
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
