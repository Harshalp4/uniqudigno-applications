allprojects {
    repositories {
        google()
        mavenCentral()
        // rootbeer, used by the vendored flutter_jailbreak_detection, is JitPack-only.
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Several pub plugins still pin compileSdk 33 while the AndroidX artifacts they
// pull in (exifinterface, core, biometric, …) require 34+, which fails the build.
// Their sources live in the read-only pub cache, so raise it here instead.
// Compiling against a newer SDK doesn't change runtime behaviour — that's
// targetSdk — so this is safe for plugins written against older APIs.
//
// Reflection because AGP's types aren't on the root project's buildscript classpath.
fun Project.forceCompileSdk(sdk: Int) {
    val androidExt = extensions.findByName("android") ?: return
    androidExt.javaClass.methods.firstOrNull {
        it.name == "setCompileSdkVersion" &&
            it.parameterCount == 1 &&
            it.parameterTypes[0] == Int::class.javaPrimitiveType
    }?.invoke(androidExt, sdk)
}

// Registered before the evaluationDependsOn block below, which eagerly evaluates
// projects — afterEvaluate throws on an already-evaluated project, hence the guard.
subprojects {
    if (state.executed) forceCompileSdk(36) else afterEvaluate { forceCompileSdk(36) }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
