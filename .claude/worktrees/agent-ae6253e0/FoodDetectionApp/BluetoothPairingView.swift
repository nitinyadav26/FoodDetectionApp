import SwiftUI

struct BluetoothPairingView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon
                Image(systemName: bluetoothManager.isConnected ? "wave.3.right.circle.fill" : "wave.3.right.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(bluetoothManager.isConnected ? .blue : .gray)
                    .padding(.top, 50)
                    .accessibilityLabel(bluetoothManager.isConnected ? "Bluetooth connected" : "Bluetooth disconnected")

                // Status Text
                VStack(spacing: 10) {
                    Text(bluetoothManager.isConnected ? "Scale Connected" : "Searching for Scale...")
                        .font(.title2)
                        .bold()

                    Text(bluetoothManager.statusMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .accessibilityElement(children: .combine)
                
                if bluetoothManager.isConnected {
                    // Live Weight Preview
                    VStack {
                        Text("Current Weight")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.0f g", bluetoothManager.currentWeight))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current weight: \(String(format: "%.0f", bluetoothManager.currentWeight)) grams")
                    .accessibilityValue("\(String(format: "%.0f", bluetoothManager.currentWeight)) grams")
                }
                
                Spacer()
                
                // Scan Button
                if !bluetoothManager.isConnected {
                    Button(action: {
                        bluetoothManager.startScanning()
                    }) {
                        Text("Scan Again")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .accessibilityLabel("Scan for devices")
                    .accessibilityHint("Starts scanning for nearby Bluetooth scales")
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Pair Device")
        }
        .navigationViewStyle(.stack)
    }
}
