import SwiftUI

struct CastModalView: View {
    @Binding var isPresented: Bool
    @Binding var videoURL: String?
    @ObservedObject var rokuController: RokuController
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Cast to Roku")
                .font(.title)
                .fontWeight(.bold)
            
            if rokuController.isConnected {
                Button(action: {
                    if let url = videoURL {
                        rokuController.castVideo(url: url)
                        isPresented = false
                    }
                }) {
                    HStack {
                        Image(systemName: "tv")
                            .font(.title2)
                        Text("Cast Video")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                if rokuController.discoveredDevices.isEmpty {
                    Text("No Roku devices found")
                        .foregroundColor(.red)
                    
                    Button(action: {
                        Task {
                            await rokuController.discoverDevices()
                        }
                    }) {
                        Text("Search for Roku Devices")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    List(rokuController.discoveredDevices) { device in
                        Button(action: {
                            rokuController.connect(to: device)
                        }) {
                            HStack {
                                Image(systemName: "tv")
                                Text(device.name)
                                Spacer()
                                Text(device.ipAddress)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
} 