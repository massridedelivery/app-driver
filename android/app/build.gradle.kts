import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload keystore config — see android/key.properties (not committed).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Load secrets (e.g. Maps API key) from local.properties — kept out of source control.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY", "")

// Flutter forwards every --dart-define to Gradle as the `dart-defines` property:
// a comma-separated list of base64-encoded KEY=VALUE pairs. Decoding it here lets
// config/*.json stay the single source of truth for the package suffix, so no
// --flavor argument (and no CI change) is needed. Absent on non-Flutter
// invocations (e.g. plain `gradlew`), hence the empty-map fallback.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { entry ->
            runCatching { String(Base64.getDecoder().decode(entry)) }.getOrNull()
        }
        ?.mapNotNull { decoded ->
            decoded.split("=", limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] }
        }
        ?.toMap()
        ?: emptyMap()

// e.g. ".dev" so a dev build installs alongside prod instead of replacing it.
val packageNameSuffix: String = dartDefines["APP_PACKAGE_NAME_SUFFIX"].orEmpty()

android {
    namespace = "com.massapp.massdrive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.massapp.massdrive"
        // Driven by APP_PACKAGE_NAME_SUFFIX in config/*.json (empty for
        // preprod/prod so the Play package stays com.massapp.massdrive).
        if (packageNameSuffix.isNotEmpty()) {
            applicationIdSuffix = packageNameSuffix
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Injected into AndroidManifest.xml as ${MAPS_API_KEY}
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties on this machine — fall back to debug signing
                // so `flutter run --release` still works. Play uploads must be
                // built with the upload keystore.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
