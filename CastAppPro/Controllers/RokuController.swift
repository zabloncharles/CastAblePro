import Foundation
import Network
import Combine

class RokuController: ObservableObject {
    @Published var connectedDevice: RokuDevice?
    @Published var discoveredDevices: [RokuDevice] = []
    @Published var currentVideo: VideoMetadata?
    @Published var isConnected = false
    @Published var isPlaying = false
    @Published var currentPosition: Double = 0
    @Published var duration: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let ssdpService = SSDPService()
    private var statusUpdateTimer: Timer?
    
    private let lastDeviceKey = "lastConnectedRokuDevice"
    
    init() {
        setupBindings()
        autoReconnectLastDevice()
    }
    
    private func setupBindings() {
        ssdpService.$discoveredDevices
            .sink { [weak self] devices in
                self?.discoveredDevices = devices
            }
            .store(in: &cancellables)
    }
    
    func discoverDevices() async {
        // Clear existing devices
        await MainActor.run {
            discoveredDevices.removeAll()
        }
        
        // Start discovery
        ssdpService.startDiscovery()
        
        // Wait for a reasonable time to discover devices
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Stop discovery
        ssdpService.stopDiscovery()
    }
    
    func connect(to device: RokuDevice) {
        connectedDevice = device
        isConnected = true
        saveLastConnectedDevice(device)
    }
    
    func saveLastConnectedDevice(_ device: RokuDevice) {
        let dict: [String: String] = ["ip": device.ipAddress, "name": device.name]
        UserDefaults.standard.set(dict, forKey: lastDeviceKey)
    }
    
    private func autoReconnectLastDevice() {
        guard connectedDevice == nil else { return }
        guard let dict = UserDefaults.standard.dictionary(forKey: lastDeviceKey) as? [String: String],
              let ip = dict["ip"], let name = dict["name"] else { return }
        let urlString = "http://\(ip):8060/query/device-info"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard error == nil, let data = data, let xml = String(data: data, encoding: .utf8), xml.contains("<device-info>") else { return }
            DispatchQueue.main.async {
                let device = RokuDevice(id: UUID().uuidString, name: name, ipAddress: ip)
                self.connectedDevice = device
                self.isConnected = true
                if !self.discoveredDevices.contains(where: { $0.ipAddress == device.ipAddress }) {
                    self.discoveredDevices.append(device)
                }
            }
        }.resume()
    }
    
    func castVideo(url: String) {
        guard let device = connectedDevice else { return }
        
        let launchCommand = "http://\(device.ipAddress):\(device.port)/launch/11?contentId=\(url)"
        sendCommand(to: launchCommand)
        
        // Initialize video metadata
        currentVideo = VideoMetadata(
            url: url,
            title: "Casting Video",
            duration: 0,
            currentPosition: 0,
            isPlaying: true
        )
        
        // Start periodic status updates
        startStatusUpdates()
    }
    
    func play() {
        guard let device = connectedDevice else { return }
        sendCommand(to: "http://\(device.ipAddress):\(device.port)/keypress/Play")
        isPlaying = true
        currentVideo?.isPlaying = true
    }
    
    func pause() {
        guard let device = connectedDevice else { return }
        sendCommand(to: "http://\(device.ipAddress):\(device.port)/keypress/Pause")
        isPlaying = false
        currentVideo?.isPlaying = false
    }
    
    func seek(to position: Double) {
        guard let device = connectedDevice else { return }
        let seekCommand = "http://\(device.ipAddress):\(device.port)/seek?position=\(position)"
        sendCommand(to: seekCommand)
        currentPosition = position
        currentVideo?.currentPosition = position
    }
    
    private func sendCommand(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if let error = error {
                print("Error sending command: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }.resume()
    }
    
    private func startStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlaybackStatus()
        }
    }
    
    func updatePlaybackStatus() {
        guard let device = connectedDevice else { return }
        let statusCommand = "http://\(device.ipAddress):\(device.port)/query/media-player"
        
        guard let url = URL(string: statusCommand) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let position = json["position"] as? Double,
                  let duration = json["duration"] as? Double else {
                return
            }
            
            DispatchQueue.main.async {
                self?.currentPosition = position
                self?.duration = duration
                
                if var video = self?.currentVideo {
                    video.currentPosition = position
                    video.duration = duration
                    self?.currentVideo = video
                }
            }
        }.resume()
    }
    
    deinit {
        statusUpdateTimer?.invalidate()
    }
} 