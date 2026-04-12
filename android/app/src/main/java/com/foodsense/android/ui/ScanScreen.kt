package com.foodsense.android.ui

import android.Manifest
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.services.AnalyticsService
import com.foodsense.android.services.BarcodeScanner
import com.foodsense.android.services.InferenceResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

@Composable
fun ScanScreen(app: FoodSenseApplication) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var hasCameraPermission by remember(context) {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED,
        )
    }
    val cameraPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        hasCameraPermission = granted
    }

    var latestBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var capturedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var detectedFood by remember { mutableStateOf("Align food & Tap Capture") }
    var nutritionInfo by remember { mutableStateOf<NutritionInfo?>(null) }
    var detectedResults by remember { mutableStateOf<List<InferenceResult>>(emptyList()) }
    var showResult by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    var isBarcodeMode by remember { mutableStateOf(false) }

    val barcodeScanner = remember { BarcodeScanner() }

    fun resetScan() {
        showResult = false
        detectedFood = "Align food & Tap Capture"
        nutritionInfo = null
        detectedResults = emptyList()
        capturedBitmap = null
        isProcessing = false
    }

    fun captureAndScanBarcode() {
        val bitmap = latestBitmap ?: return
        if (isProcessing) return

        isProcessing = true
        detectedFood = "Scanning barcode..."
        capturedBitmap = bitmap

        scope.launch {
            val code = barcodeScanner.scanBarcode(bitmap)

            if (code == null) {
                detectedFood = "No barcode found. Try again."
                isProcessing = false
                return@launch
            }

            detectedFood = "Barcode: $code - Looking up..."

            val result = barcodeScanner.lookupBarcode(code)

            if (result != null) {
                val (name, info) = result
                detectedFood = name
                nutritionInfo = info
                showResult = true
                isProcessing = false
                AnalyticsService.logFoodScanned(name, "barcode")
            } else {
                detectedFood = "Product not found for barcode: $code"
                isProcessing = false
            }
        }
    }

    fun captureAndAnalyze(useCloud: Boolean) {
        val bitmap = latestBitmap ?: return
        if (isProcessing) return

        isProcessing = true
        detectedFood = if (useCloud) "Asking AI..." else "Analyzing..."
        capturedBitmap = bitmap

        scope.launch {
            if (useCloud) {
                runCatching {
                    app.apiService.analyzeFood(bitmap)
                }.onSuccess { (name, info) ->
                    detectedFood = name
                    nutritionInfo = info
                    showResult = true
                    isProcessing = false
                    AnalyticsService.logFoodScanned(name, "cloud")
                }.onFailure {
                    detectedFood = "AI Failed. Try again."
                    isProcessing = false
                }
            } else {
                val results = withContext(Dispatchers.Default) {
                    runCatching { app.localModelDetector.detect(bitmap) }.getOrElse { emptyList() }
                }
                isProcessing = false
                if (results.isNotEmpty()) {
                    detectedResults = results
                    detectedFood = "${results.size} items detected"
                    showResult = true
                    results.forEach { AnalyticsService.logFoodScanned(it.label, "local") }
                } else {
                    detectedFood = "No food detected."
                }
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        if (!hasCameraPermission) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Camera permission is required to scan food.", textAlign = TextAlign.Center)
                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = {
                    cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                    hasCameraPermission = ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.CAMERA,
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                }) {
                    Text("Grant Camera Permission")
                }
            }
        } else {
            CameraPreview(onFrame = { latestBitmap = it })

            Column(modifier = Modifier.fillMaxSize()) {
                // Mode Toggle at the top
                if (!showResult) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 48.dp),
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        Row(
                            modifier = Modifier
                                .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(10.dp)),
                        ) {
                            Button(
                                onClick = { isBarcodeMode = false },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (!isBarcodeMode) Color(0xFF1DB954) else Color.Transparent,
                                    contentColor = if (!isBarcodeMode) Color.White else Color.White.copy(alpha = 0.7f),
                                ),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.height(36.dp),
                            ) {
                                Text("AI Scan", fontSize = 13.sp)
                            }
                            Button(
                                onClick = { isBarcodeMode = true },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (isBarcodeMode) Color(0xFF1DB954) else Color.Transparent,
                                    contentColor = if (isBarcodeMode) Color.White else Color.White.copy(alpha = 0.7f),
                                ),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.height(36.dp),
                            ) {
                                Text("Barcode", fontSize = 13.sp)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Bottom Controls
                if (!showResult) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.Black.copy(alpha = 0.55f))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text(detectedFood, color = Color.White)
                        Spacer(modifier = Modifier.height(14.dp))

                        if (isBarcodeMode) {
                            // Barcode scan button
                            Button(
                                onClick = { captureAndScanBarcode() },
                                enabled = !isProcessing,
                                shape = CircleShape,
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800)),
                                modifier = Modifier.size(90.dp),
                            ) {
                                if (isProcessing) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp),
                                        strokeWidth = 2.dp,
                                        color = Color.White,
                                    )
                                } else {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text("|||||||", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                                        Text("Scan", fontSize = 11.sp)
                                    }
                                }
                            }
                        } else {
                            Row(horizontalArrangement = Arrangement.spacedBy(28.dp), verticalAlignment = Alignment.CenterVertically) {
                                Button(
                                    onClick = { captureAndAnalyze(useCloud = false) },
                                    enabled = !isProcessing,
                                    shape = CircleShape,
                                    modifier = Modifier.size(78.dp),
                                ) {
                                    if (isProcessing) {
                                        CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                                    } else {
                                        Text("Go")
                                    }
                                }

                                Button(
                                    onClick = { captureAndAnalyze(useCloud = true) },
                                    enabled = !isProcessing,
                                    shape = CircleShape,
                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7E57C2)),
                                    modifier = Modifier.size(90.dp),
                                ) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Icon(Icons.Default.Star, contentDescription = "AI Scan")
                                        Text("AI")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (showResult && detectedResults.isNotEmpty()) {
                MultiObjectResultSheet(
                    image = capturedBitmap,
                    results = detectedResults,
                    app = app,
                    onCancel = { resetScan() },
                    onDone = { resetScan() },
                )
            } else if (showResult && nutritionInfo != null) {
                ResultSheet(
                    image = capturedBitmap,
                    dishName = detectedFood,
                    nutrition = nutritionInfo!!,
                    app = app,
                    onCancel = { resetScan() },
                    onLog = { resetScan() },
                )
            }
        }
    }
}

@Composable
private fun CameraPreview(onFrame: (Bitmap) -> Unit) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    AndroidView(
        factory = {
            PreviewView(it).apply {
                implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                scaleType = PreviewView.ScaleType.FILL_CENTER
            }
        },
        modifier = Modifier.fillMaxSize(),
        update = { previewView ->
            val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()

                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()

                analysis.setAnalyzer(ContextCompat.getMainExecutor(context)) { proxy ->
                    proxy.toBitmap()?.let(onFrame)
                    proxy.close()
                }

                runCatching {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        CameraSelector.DEFAULT_BACK_CAMERA,
                        preview,
                        analysis,
                    )
                }
            }, ContextCompat.getMainExecutor(context))
        },
    )
}

private fun ImageProxy.toBitmap(): Bitmap? {
    val yBuffer = planes[0].buffer
    val uBuffer = planes[1].buffer
    val vBuffer = planes[2].buffer

    val ySize = yBuffer.remaining()
    val uSize = uBuffer.remaining()
    val vSize = vBuffer.remaining()

    val nv21 = ByteArray(ySize + uSize + vSize)
    yBuffer.get(nv21, 0, ySize)
    vBuffer.get(nv21, ySize, vSize)
    uBuffer.get(nv21, ySize + vSize, uSize)

    val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
    val out = ByteArrayOutputStream()
    yuvImage.compressToJpeg(Rect(0, 0, width, height), 75, out)
    val bytes = out.toByteArray()
    return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
}

@Composable
fun ResultSheet(
    image: Bitmap?,
    dishName: String,
    nutrition: NutritionInfo,
    app: FoodSenseApplication,
    onCancel: () -> Unit,
    onLog: () -> Unit,
) {
    val bluetoothManager = app.bluetoothScaleManager
    var manualWeight by rememberSaveable { mutableStateOf("100") }
    var useScaleWeight by rememberSaveable { mutableStateOf(false) }

    val currentWeight = if (useScaleWeight && bluetoothManager.isConnected) {
        bluetoothManager.currentWeight
    } else {
        manualWeight.toDoubleOrNull() ?: 100.0
    }

    val displayed = app.nutritionManager.calculateNutrition(nutrition, currentWeight)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.7f)),
        contentAlignment = Alignment.BottomCenter,
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(560.dp),
            shape = RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                image?.let {
                    androidx.compose.foundation.Image(
                        bitmap = it.asImageBitmap(),
                        contentDescription = dishName,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp)
                            .clip(RoundedCornerShape(16.dp)),
                        contentScale = ContentScale.Crop,
                    )
                }

                Text(dishName, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)

                // AI Provider badge
                app.aiProviderManager.activeProvider?.let { provider ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center,
                        modifier = Modifier
                            .background(MaterialTheme.colorScheme.surfaceVariant, shape = MaterialTheme.shapes.small)
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                    ) {
                        Icon(
                            imageVector = if (provider.providerName == "Gemini Cloud")
                                Icons.Default.Cloud else Icons.Default.Memory,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            "Powered by ${provider.providerName}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                if (bluetoothManager.isConnected) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Use SmartScale")
                        Spacer(modifier = Modifier.weight(1f))
                        Switch(checked = useScaleWeight, onCheckedChange = { useScaleWeight = it })
                    }
                    if (useScaleWeight) {
                        Text("Reading: ${"%.1f".format(bluetoothManager.currentWeight)}g", color = Color(0xFF4FC3F7))
                    }
                }

                if (!useScaleWeight) {
                    OutlinedTextField(
                        value = manualWeight,
                        onValueChange = { manualWeight = it },
                        label = { Text("Weight (g)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    )
                }

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                    MacroRing("Calories", displayed.calories, Color(0xFF1DB954))
                    MacroRing("Protein", displayed.protein, Color(0xFF4FC3F7))
                    MacroRing("Carbs", displayed.carbs, Color(0xFFFF9800))
                    MacroRing("Fats", displayed.fats, Color(0xFFF44336))
                }

                displayed.micros?.takeIf { it.isNotEmpty() }?.let { micros ->
                    Text("Micronutrients", fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                    micros.forEach { (k, v) -> Text("$k: $v", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp) }
                }

                Text("Healthier Advice", fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                Text(displayed.recipe, color = MaterialTheme.colorScheme.onSurfaceVariant)

                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(onClick = onCancel, modifier = Modifier.weight(1f)) { Text("Cancel") }
                    Button(
                        onClick = {
                            app.nutritionManager.logFood(dish = dishName, info = nutrition, weight = currentWeight)
                            AnalyticsService.logFoodLogged(dishName, displayed.calories.filter { it.isDigit() || it == '.' }.toDoubleOrNull()?.toInt() ?: 0)
                            onLog()
                        },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Log Food")
                    }
                }
            }
        }
    }
}

@Composable
fun MultiObjectResultSheet(
    image: Bitmap?,
    results: List<InferenceResult>,
    app: FoodSenseApplication,
    onCancel: () -> Unit,
    onDone: () -> Unit,
) {
    val bluetoothManager = app.bluetoothScaleManager
    val nutritionManager = app.nutritionManager

    val selectedItems = remember(results) { mutableStateListOf(*results.map { it.label }.toTypedArray()) }
    val quantities = remember(results) {
        mutableStateMapOf<String, String>().apply {
            results.forEach { this[it.label] = "100" }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.7f)),
        contentAlignment = Alignment.BottomCenter,
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(560.dp),
            shape = RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        ) {
            Column(modifier = Modifier.fillMaxSize().padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                image?.let {
                    androidx.compose.foundation.Image(
                        bitmap = it.asImageBitmap(),
                        contentDescription = "Captured image",
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp)
                            .clip(RoundedCornerShape(14.dp)),
                        contentScale = ContentScale.Crop,
                    )
                }

                Text("Detected Items", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
                Text("Select items to log", color = MaterialTheme.colorScheme.onSurfaceVariant)

                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(results, key = { it.label }) { result ->
                        val checked = result.label in selectedItems
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Switch(
                                    checked = checked,
                                    onCheckedChange = {
                                        if (it) selectedItems.add(result.label) else selectedItems.remove(result.label)
                                    },
                                )
                                Spacer(modifier = Modifier.width(8.dp))

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(result.label, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                                    Text(
                                        nutritionManager.getNutrition(result.label)?.let { "${it.calories} kcal / 100g" } ?: "No nutrition info",
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        fontSize = 12.sp,
                                    )
                                }

                                if (checked) {
                                    OutlinedTextField(
                                        value = quantities[result.label] ?: "100",
                                        onValueChange = { quantities[result.label] = it },
                                        label = { Text("g") },
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                        modifier = Modifier.width(90.dp),
                                    )
                                }
                            }
                        }
                    }
                }

                if (bluetoothManager.isConnected) {
                    Text("Scale connected: ${"%.0f".format(bluetoothManager.currentWeight)} g", color = Color(0xFF4FC3F7))
                }

                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(onClick = onCancel, modifier = Modifier.weight(1f)) { Text("Cancel") }
                    Button(
                        onClick = {
                            selectedItems.forEach { label ->
                                val info = nutritionManager.getNutrition(label)
                                val weight = quantities[label]?.toDoubleOrNull() ?: 100.0
                                if (info != null) {
                                    nutritionManager.logFood(dish = label, info = info, weight = weight)
                                    val cals = nutritionManager.calculateNutrition(info, weight).calories
                                    AnalyticsService.logFoodLogged(label, cals.filter { it.isDigit() || it == '.' }.toDoubleOrNull()?.toInt() ?: 0)
                                }
                            }
                            onDone()
                        },
                        modifier = Modifier.weight(1f),
                        enabled = selectedItems.isNotEmpty(),
                    ) {
                        Text("Log Selected (${selectedItems.size})")
                    }
                }
            }
        }
    }
}
