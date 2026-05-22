plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.school_projects_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.school_projects_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Автоматически вырезаем сломанный старый класс из автосгенерированного файла перед компиляцией
tasks.withType<JavaCompile> {
    doFirst {
        val registrantFile = file("${projectDir}/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (registrantFile.exists()) {
            var text = registrantFile.readText()
            if (text.contains("com.mr.flutter.plugin.filepicker.FilePickerPlugin")) {
                // Вырезаем весь блок try-catch, который вызывает ошибку
                val regex = """try\s*\{\s*flutterEngine\.getPlugins\(\)\.add\(new\s+com\.mr\.flutter\.plugin\.filepicker\.FilePickerPlugin\(\)\);\s*\}\s*catch\s*\(Exception\s+e\)\s*\{\s*Log\.e\([^\)]+\);\s*\}""".toRegex()
                text = text.replace(regex, "")
                registrantFile.writeText(text)
                logger.lifecycle("Successfully patched GeneratedPluginRegistrant.java for file_picker 11.x")
            }
        }
    }
}
