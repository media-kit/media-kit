import java.io.File
import java.net.URI
import java.security.MessageDigest

group = "com.alexmercerind.media_kit_libs_android_video"
version = "1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.13.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "com.alexmercerind.media_kit_libs_android_video"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation(fileTree(layout.buildDirectory.dir("output")) { include("*.jar") })
}

fun File.md5(): String {
    val digest = MessageDigest.getInstance("MD5")
    inputStream().use { input ->
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            digest.update(buffer, 0, count)
        }
    }
    return digest.digest().joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
}

val downloadDependencies by tasks.registering {
    doLast {
        val outputDirectory = layout.buildDirectory.dir("output").get().asFile
        project.delete(outputDirectory)
        outputDirectory.mkdirs()

        val filesToDownload = listOf(
            Triple(
                "https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.11/default-arm64-v8a.jar",
                "540af35cefe192b42fafb253f8ca6580",
                layout.buildDirectory.file("v1.1.11/default-arm64-v8a.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.11/default-armeabi-v7a.jar",
                "348ddcebec228bb53256ac980ea2bb84",
                layout.buildDirectory.file("v1.1.11/default-armeabi-v7a.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.11/default-x86_64.jar",
                "d8d0b19a8bb673ab61f2808b2b9bf4fa",
                layout.buildDirectory.file("v1.1.11/default-x86_64.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.11/default-x86.jar",
                "19906a87efffbe994a0ca976ab577feb",
                layout.buildDirectory.file("v1.1.11/default-x86.jar").get().asFile,
            ),
        )

        filesToDownload.forEach { (url, expectedMd5, destination) ->
            if (destination.exists() && destination.md5() != expectedMd5) {
                destination.delete()
                println("MD5 mismatch. File deleted: $destination")
            }

            if (!destination.exists()) {
                destination.parentFile.mkdirs()
                println("Downloading file from: $url")
                URI.create(url).toURL().openStream().use { input ->
                    destination.outputStream().use(input::copyTo)
                }
                if (destination.md5() != expectedMd5) {
                    throw GradleException("MD5 verification failed for $destination")
                }
            }

            project.copy {
                from(destination)
                into(outputDirectory)
            }
        }
    }
}

tasks.named("preBuild").configure {
    dependsOn(downloadDependencies)
}
