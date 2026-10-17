import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

val firebaseConfigured = file("google-services.json").exists()
val offlinePreview = providers.gradleProperty("bnyadOfflinePreview").orNull == "true"
if (firebaseConfigured && !offlinePreview) apply(plugin = "com.google.gms.google-services")
val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) releasePropertiesFile.inputStream().use { releaseProperties.load(it) }

gradle.taskGraph.whenReady {
    if (offlinePreview) {
        val unsafeTasks = allTasks.filter { it.project.path == ":app" &&
            (it.name.endsWith("Release", ignoreCase = true) || it.name.endsWith("Profile", ignoreCase = true) ||
             it.name.contains("ReleaseResources") || it.name.contains("ProfileResources")) }
        require(unsafeTasks.isEmpty()) {
            "Offline Android preview is restricted to debug builds: ${unsafeTasks.map { it.path }}"
        }
    }
    if (allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
        require(releasePropertiesFile.exists()) { "Release signing requires android/key.properties from the release developer." }
        require(firebaseConfigured) { "Release builds require the existing android/app/google-services.json." }
    }
}

android {
    namespace = "com.bnyad.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures { buildConfig = true }
    if (offlinePreview) {
        sourceSets.getByName("debug").manifest.srcFile("src/offlinePreview/AndroidManifest.xml")
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bnyad.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releasePropertiesFile.exists()) {
            create("release") {
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
                storeFile = file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        debug {
            if (offlinePreview) applicationIdSuffix = ".dev"
            buildConfigField("boolean", "BNYAD_OFFLINE_PREVIEW", offlinePreview.toString())
        }
        release {
            buildConfigField("boolean", "BNYAD_OFFLINE_PREVIEW", "false")
            signingConfig = signingConfigs.findByName("release")
        }
    }
    // Profile builds are never allowed to activate fixture authentication.
    buildTypes.configureEach {
        if (name != "debug" && name != "release") {
            buildConfigField("boolean", "BNYAD_OFFLINE_PREVIEW", "false")
        }
    }
}

dependencies {
    // Stable, read-only native Health Connect integration (no Flutter health SDK).
    implementation("androidx.health.connect:connect-client:1.1.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
