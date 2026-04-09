package com.foodsense.android.services

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.util.UUID

class BluetoothScaleManager(private val context: Context) {
    var currentWeight by mutableStateOf(100.0)
        private set
    var isConnected by mutableStateOf(false)
        private set
    var statusMessage by mutableStateOf("Disconnected")
        private set

    private val serviceUUID = UUID.fromString("0000181d-0000-1000-8000-00805f9b34fb")
    private val charUUID = UUID.fromString("00002a9d-0000-1000-8000-00805f9b34fb")

    private val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val adapter: BluetoothAdapter? = btManager.adapter
    private val scanner: BluetoothLeScanner?
        get() = adapter?.bluetoothLeScanner

    private var gatt: BluetoothGatt? = null
    private var isScanning = false

    fun hasRequiredPermissions(): Boolean {
        val required = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            required += Manifest.permission.BLUETOOTH_SCAN
            required += Manifest.permission.BLUETOOTH_CONNECT
        } else {
            required += Manifest.permission.ACCESS_FINE_LOCATION
        }

        return required.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    @SuppressLint("MissingPermission")
    fun startScanning() {
        if (adapter == null) {
            statusMessage = "Bluetooth unavailable on this device"
            return
        }

        if (!adapter.isEnabled) {
            statusMessage = "Bluetooth is Off"
            return
        }

        if (!hasRequiredPermissions()) {
            statusMessage = "Bluetooth permission needed"
            return
        }

        if (isConnected) {
            statusMessage = "Connected"
            return
        }

        val scanner = scanner
        if (scanner == null) {
            statusMessage = "BLE scanner unavailable"
            return
        }

        if (isScanning) return

        statusMessage = "Scanning..."
        isScanning = true

        val filters = listOf(
            ScanFilter.Builder().setServiceUuid(ParcelUuid(serviceUUID)).build(),
        )
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanner.startScan(filters, settings, scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        scanner?.stopScan(scanCallback)
        isScanning = false
        gatt?.disconnect()
        gatt?.close()
        gatt = null
        isConnected = false
        statusMessage = "Disconnected"
    }

    @SuppressLint("MissingPermission")
    private fun connect(device: BluetoothDevice) {
        statusMessage = "Connecting to ${device.name ?: "Scale"}..."
        scanner?.stopScan(scanCallback)
        isScanning = false
        gatt = device.connectGatt(context, false, gattCallback)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            connect(result.device)
        }

        override fun onScanFailed(errorCode: Int) {
            isScanning = false
            statusMessage = "Scan failed ($errorCode)"
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                isConnected = true
                statusMessage = "Connected"
                gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                isConnected = false
                statusMessage = "Disconnected"
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            val service: BluetoothGattService = gatt.getService(serviceUUID) ?: return
            val characteristic: BluetoothGattCharacteristic = service.getCharacteristic(charUUID) ?: return
            gatt.setCharacteristicNotification(characteristic, true)

            val descriptor = characteristic.descriptors.firstOrNull()
            descriptor?.let {
                it.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                gatt.writeDescriptor(it)
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (characteristic.uuid != charUUID) return
            val payload = characteristic.value?.toString(Charsets.UTF_8).orEmpty()
            runCatching {
                val json = JSONObject(payload)
                currentWeight = json.optDouble("w_g", currentWeight)
            }
        }
    }
}
