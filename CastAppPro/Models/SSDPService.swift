import Foundation
import Network

class SSDPService {
    @Published var discoveredDevices: [RokuDevice] = []
    private var browser: NWBrowser?
    private var udpConnection: NWConnection?
    private var promptConnection: NWConnection?
    
    func startDiscovery() {
        print("[SSDP] Starting device discovery...")
        // Force local network prompt by sending a UDP packet to a local IP
        let promptEndpoint = NWEndpoint.hostPort(host: "192.168.1.1", port: 9)
        let promptParams = NWParameters.udp
        promptConnection = NWConnection(to: promptEndpoint, using: promptParams)
        promptConnection?.start(queue: .main)
        promptConnection?.send(content: Data([0]), completion: .contentProcessed { result in
            print("[SSDP] Sent UDP packet to 192.168.1.1:9 to trigger local network prompt. Result: \(result)")
            self.promptConnection?.cancel()
            self.promptConnection = nil
        })
        
        // Create UDP connection for SSDP
        let parameters = NWParameters.udp
        parameters.includePeerToPeer = true
        
        // SSDP multicast address and port
        let endpoint = NWEndpoint.hostPort(host: "239.255.255.250", port: 1900)
        udpConnection = NWConnection(to: endpoint, using: parameters)
        
        // Set up state handler
        udpConnection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("[SSDP] UDP connection ready. Sending SSDP discovery message...")
                self?.sendSSDPDiscovery()
                self?.listenForResponses()
            case .failed(let error):
                print("[SSDP] UDP connection failed: \(error)")
            default:
                break
            }
        }
        
        // Start the connection
        udpConnection?.start(queue: .main)
    }
    
    private func listenForResponses() {
        udpConnection?.receiveMessage { [weak self] (data, _, _, error) in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("[SSDP] Received SSDP response:\n\(response)")
                DispatchQueue.main.async {
                    self?.handleSSDPResponse(response)
                }
            }
            if let error = error {
                print("[SSDP] Receive error: \(error)")
            }
            // Keep listening for more responses
            self?.listenForResponses()
        }
    }
    
    private func sendSSDPDiscovery() {
        let discoveryMessage = """
        M-SEARCH * HTTP/1.1\r\n\
        HOST: 239.255.255.250:1900\r\n\
        MAN: \"ssdp:discover\"\r\n\
        ST: roku:ecp\r\n\
        MX: 3\r\n\
        \r\n
        """
        print("[SSDP] Sending SSDP discovery message to 239.255.255.250:1900...")
        if let data = discoveryMessage.data(using: .utf8) {
            udpConnection?.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("[SSDP] Send error: \(error)")
                } else {
                    print("[SSDP] SSDP discovery message sent successfully.")
                }
            })
        }
    }
    
    private func handleSSDPResponse(_ response: String) {
        // Parse SSDP response
        let lines = response.components(separatedBy: .newlines)
        var deviceInfo: [String: String] = [:]
        
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                deviceInfo[key] = value
            }
        }
        
        // Extract device information
        if let location = deviceInfo["LOCATION"],
           let url = URL(string: location),
           let host = url.host {
            let device = RokuDevice(
                id: UUID().uuidString,
                name: deviceInfo["SERVER"] ?? "Roku Device",
                ipAddress: host
            )
            
            // Always update on main thread
            if !self.discoveredDevices.contains(where: { $0.ipAddress == device.ipAddress }) {
                print("[SSDP] Adding discovered device: \(device.name) @ \(device.ipAddress)")
                self.discoveredDevices.append(device)
            } else {
                print("[SSDP] Device already discovered: \(device.ipAddress)")
            }
        } else {
            print("[SSDP] Could not extract device info from response.")
        }
    }
    
    func stopDiscovery() {
        print("[SSDP] Stopping device discovery and cleaning up connections.")
        udpConnection?.cancel()
        udpConnection = nil
        discoveredDevices.removeAll()
    }
} 