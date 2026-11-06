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
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// Gradle 9 requires writable project directories, unlike Nix's immutable SDK.
val integrationTest = findProject(":integration_test")
if (integrationTest != null) {
    val source = integrationTest.projectDir
    if (source.toPath().startsWith(
            java.nio.file.Path
                .of("/nix/store"),
        )
    ) {
        val sdkKey =
            java.security.MessageDigest
                .getInstance("SHA-256")
                .digest(source.absolutePath.toByteArray())
                .joinToString("") { "%02x".format(it) }
        val writableProject = file(".gradle/flutter-sdk-plugins/$sdkKey/integration_test")
        val complete = java.io.File(writableProject, ".copy-complete")
        if (!complete.exists()) {
            check(source.copyRecursively(writableProject, overwrite = true)) {
                "Could not copy integration_test to a writable Gradle project"
            }
            complete.writeText(source.absolutePath)
        }
        integrationTest.projectDir = writableProject
    }
}
