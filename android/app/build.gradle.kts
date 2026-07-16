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

// Flutter forwards --dart-define / --dart-define-from-file values to Gradle as a
// comma-separated list of base64-encoded "key=value" pairs in the "dart-defines"
// project property. Decode them so native build config (applicationId) is driven
// by the same config/*.json files as the Dart code, instead of being hardcoded.
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.mapNotNull { encoded ->
        val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        val sep = decoded.indexOf('=')
        if (sep < 0) null else decoded.substring(0, sep) to decoded.substring(sep + 1)
    }
    ?.toMap()
    ?: emptyMap()

// Defaults keep a plain `./gradlew` build (no dart-defines) working and match
// prod (no suffix). A Flutter build always supplies these via config/*.json.
val appPackageName: String = dartDefines["APP_PACKAGE_NAME"] ?: "com.massapp.massdrive"
val appPackageNameSuffix: String = dartDefines["APP_PACKAGE_NAME_SUFFIX"] ?: ""

android {
    // namespace stays fixed — it's the compile-time package of the generated R
    // class, not the installed app id (which is applicationId below).
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
        // dev/pre-prod -> com.massapp.massdrive.dev, prod -> com.massapp.massdrive
        // (suffix comes from config/mass_dev.json vs config/mass_prod.json).
        applicationId = appPackageName + appPackageNameSuffix
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
