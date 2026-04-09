# ===== Kotlinx Serialization =====
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep all @Serializable data classes in our data package
-keep class com.foodsense.android.data.** { *; }
-keepclassmembers class com.foodsense.android.data.** { *; }

# ===== OkHttp3 =====
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ===== TensorFlow Lite =====
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep InferenceResult used by LocalModelDetector
-keep class com.foodsense.android.services.InferenceResult { *; }

# ===== Compose =====
-dontwarn androidx.compose.**

# ===== General =====
-keepattributes Signature
-keepattributes Exceptions
