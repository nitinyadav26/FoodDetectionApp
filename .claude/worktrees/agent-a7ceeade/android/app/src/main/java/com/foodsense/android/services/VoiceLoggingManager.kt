package com.foodsense.android.services

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class VoiceLoggingManager(private val context: Context) {

    var isListening by mutableStateOf(false)
        private set

    var transcript by mutableStateOf("")
        private set

    var error by mutableStateOf<String?>(null)
        private set

    var isAvailable by mutableStateOf(SpeechRecognizer.isRecognitionAvailable(context))
        private set

    private var recognizer: SpeechRecognizer? = null

    fun startListening() {
        if (!isAvailable) {
            error = "Speech recognition not available on this device."
            return
        }

        error = null
        transcript = ""
        isListening = true

        recognizer?.destroy()
        recognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    isListening = false
                }

                override fun onError(errorCode: Int) {
                    isListening = false
                    error = when (errorCode) {
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected. Try again."
                        SpeechRecognizer.ERROR_NETWORK -> "Network error. Check connection."
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error."
                        else -> "Speech recognition error ($errorCode)."
                    }
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    transcript = matches?.firstOrNull() ?: ""
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    matches?.firstOrNull()?.let { transcript = it }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }

        recognizer?.startListening(intent)
    }

    fun stopListening() {
        recognizer?.stopListening()
        isListening = false
    }

    fun clearTranscript() {
        transcript = ""
        error = null
    }

    fun destroy() {
        recognizer?.destroy()
        recognizer = null
    }
}
