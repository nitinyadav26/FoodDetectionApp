import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager()
    
    @Published var currentWeight: Double = 100.0
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = "Disconnected"
    
    private var centralManager: CBCentralManager!
    private var scalePeripheral: CBPeripheral?
    
    // UUIDs from your ESP32 code
    private let serviceUUID = CBUUID(string: "0000181d-0000-1000-8000-00805f9b34fb")
    private let charUUID = CBUUID(string: "00002a9d-0000-1000-8000-00805f9b34fb")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth not ready"
            return
        }
        statusMessage = "Scanning..."
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            statusMessage = "Bluetooth is Off"
            isConnected = false
        case .unauthorized:
            statusMessage = "Bluetooth Unauthorized"
        default:
            statusMessage = "Bluetooth Error"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        scalePeripheral = peripheral
        scalePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
        statusMessage = "Connecting to \(peripheral.name ?? "Scale")..."
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusMessage = "Connected"
        peripheral.discoverServices([serviceUUID])
        AnalyticsService.logScaleConnected()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusMessage = "Disconnected"
        startScanning() // Auto-reconnect
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([charUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == charUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Parse JSON: {"w_g":100.00,"unit":"g","ts":...}
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let weight = json["w_g"] as? Double {
            DispatchQueue.main.async {
                self.currentWeight = weight
            }
        }
    }
}
