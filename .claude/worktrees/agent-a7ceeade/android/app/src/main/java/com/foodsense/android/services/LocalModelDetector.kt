package com.foodsense.android.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.RectF
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import kotlin.math.max
import kotlin.math.min

data class InferenceResult(
    val rect: RectF,
    val confidence: Float,
    val label: String,
)

class LocalModelDetector(context: Context) {
    private val inputWidth = 640
    private val inputHeight = 640
    private val threshold = 0.4f

    private val interpreter: Interpreter by lazy {
        val options = Interpreter.Options().apply { setNumThreads(2) }
        Interpreter(loadModelFile(context, "model.tflite"), options)
    }

    private val labels = listOf(
        "Indianbread", "Rasgulla", "Biryani", "Uttapam", "Paneer", "Poha", "Khichdi", "Omelette",
        "Plainrice", "Dalmakhani", "Rajma", "Poori", "Chole", "Dal", "Sambhar", "Papad",
        "Gulabjamun", "Idli", "Vada", "Dosa", "Jalebi", "Samosa", "Paobhaji", "Dhokla",
        "Barfi", "Fishcurry", "Momos", "Kheer", "Kachori", "Vadapav", "Rasmalai", "Kalachana",
        "Chaat", "Saag", "Dumaloo", "Thupka", "Khandvi", "Kabab", "Thepla", "Rasam",
        "Appam", "Gatte", "Kadhipakora", "Ghewar", "Aloomatter", "Prawns", "Sandwich", "Dahipuri",
        "Haleem", "Mutton", "Aloogobi", "Eggbhurji", "Lemonrice", "Bhindimasala", "Matarmushroom", "Gajarkahalwa",
        "Motichoorladoo", "Ragiroti", "Chickentikka", "Tandoorichicken", "Lauki", "chanamasala", "bainganbharta", "karelabharta",
        "crabcurry", "kathiroll", "gujiya", "malpua", "mysorepak", "kaddu", "rabri", "chenapoda",
        "kulfi", "pakora", "boondi", "phirni", "tilkut", "Chilla", "Handvo", "Basundi",
        "Litti chokha", "kothimbirvadi", "Soya chaap", "sabudanakhichdi", "shevbhaji", "jeerarice", "Chettinad chicken", "masortenga",
        "Chikki", "moongdalhalwa", "avial", "dalbati", "malaikofta", "chickenchangezi", "pesarattu", "patishapta",
        "chingrimalaicurry", "pootharekulu", "imarti", "upma",
    )

    fun detect(bitmap: Bitmap): List<InferenceResult> {
        val scaled = Bitmap.createScaledBitmap(bitmap, inputWidth, inputHeight, true)
        val input = bitmapToInputBuffer(scaled)

        val outputShape = interpreter.getOutputTensor(0).shape()
        val outputBuffer = TensorBuffer.createFixedSize(outputShape, DataType.FLOAT32)

        interpreter.run(input, outputBuffer.buffer.rewind())

        val out = outputBuffer.floatArray
        val shape = outputShape.map { it.toInt() }

        return processOutput(out, shape)
    }

    private fun processOutput(outputFloats: FloatArray, shape: List<Int>): List<InferenceResult> {
        if (shape.size < 3) return emptyList()

        val dimA = shape[1]
        val dimB = shape[2]

        val channelsFirst = dimA < dimB
        val dimensions = if (channelsFirst) dimA else dimB
        val anchors = if (channelsFirst) dimB else dimA

        if (dimensions < 5 || anchors <= 0) return emptyList()

        val numClasses = dimensions - 4
        val classCount = min(numClasses, labels.size)

        fun value(channel: Int, anchor: Int): Float {
            return if (channelsFirst) {
                outputFloats[channel * anchors + anchor]
            } else {
                outputFloats[anchor * dimensions + channel]
            }
        }

        val candidates = mutableListOf<InferenceResult>()

        for (anchor in 0 until anchors) {
            var maxClass = -1
            var maxScore = 0f
            for (classIdx in 0 until classCount) {
                val score = value(4 + classIdx, anchor)
                if (score > maxScore) {
                    maxScore = score
                    maxClass = classIdx
                }
            }

            if (maxClass == -1 || maxScore < threshold) continue

            val cx = value(0, anchor)
            val cy = value(1, anchor)
            val w = value(2, anchor)
            val h = value(3, anchor)

            val rect = RectF(
                cx - (w / 2f),
                cy - (h / 2f),
                cx + (w / 2f),
                cy + (h / 2f),
            )

            candidates += InferenceResult(
                rect = rect,
                confidence = maxScore,
                label = labels[maxClass],
            )
        }

        return nonMaxSuppression(candidates, iouThreshold = 0.45f, limit = 10)
    }

    private fun nonMaxSuppression(
        boxes: List<InferenceResult>,
        iouThreshold: Float,
        limit: Int,
    ): List<InferenceResult> {
        val sorted = boxes.sortedByDescending { it.confidence }.toMutableList()
        val selected = mutableListOf<InferenceResult>()

        while (sorted.isNotEmpty() && selected.size < limit) {
            val candidate = sorted.removeAt(0)
            selected += candidate

            val iterator = sorted.iterator()
            while (iterator.hasNext()) {
                val next = iterator.next()
                if (iou(candidate.rect, next.rect) >= iouThreshold) {
                    iterator.remove()
                }
            }
        }

        return selected
    }

    private fun iou(a: RectF, b: RectF): Float {
        val left = max(a.left, b.left)
        val top = max(a.top, b.top)
        val right = min(a.right, b.right)
        val bottom = min(a.bottom, b.bottom)

        val width = right - left
        val height = bottom - top
        if (width <= 0f || height <= 0f) return 0f

        val intersection = width * height
        val union = a.width() * a.height() + b.width() * b.height() - intersection
        if (union <= 0f) return 0f

        return intersection / union
    }

    private fun bitmapToInputBuffer(bitmap: Bitmap): ByteBuffer {
        val buffer = ByteBuffer.allocateDirect(4 * inputWidth * inputHeight * 3)
        buffer.order(ByteOrder.nativeOrder())

        val pixels = IntArray(inputWidth * inputHeight)
        bitmap.getPixels(pixels, 0, inputWidth, 0, 0, inputWidth, inputHeight)

        for (pixel in pixels) {
            val r = ((pixel shr 16) and 0xFF) / 255f
            val g = ((pixel shr 8) and 0xFF) / 255f
            val b = (pixel and 0xFF) / 255f
            buffer.putFloat(r)
            buffer.putFloat(g)
            buffer.putFloat(b)
        }

        buffer.rewind()
        return buffer
    }

    private fun loadModelFile(context: Context, assetName: String): ByteBuffer {
        context.assets.openFd(assetName).use { fd ->
            FileInputStream(fd.fileDescriptor).channel.use { channel ->
                return channel.map(FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength)
            }
        }
    }
}
