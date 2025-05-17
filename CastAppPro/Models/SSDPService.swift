import Foundation
import Network

class SSDPService {
    @Published var discoveredDevices: [RokuDevice] = []
    private var browser: NWBrowser?
    
    func startDiscovery() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browserDescriptor = NWBrowser.Descriptor.bonjour(type: "_roku._tcp", domain: "local")
        browser = NWBrowser(for: browserDescriptor, using: parameters)
        
        browser?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Browser is ready")
            case .failed(let error):
                print("Browser failed: \(error)")
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleDiscoveredDevices(results)
        }
        
        browser?.start(queue: .main)
    }
    
    private func handleDiscoveredDevices(_ results: Set<NWBrowser.Result>) {
        var devices: [RokuDevice] = []
        
        for result in results {
            if case .service(let name, _, _, _) = result.endpoint {
                // Extract IP address and other details from the service
                // This is a simplified version - you'll need to implement proper SSDP parsing
                let device = RokuDevice(
                    id: UUID().uuidString,
                    name: name,
                    ipAddress: "192.168.1.1" // This should be extracted from the service
                )
                devices.append(device)
            }
        }
        
        DispatchQueue.main.async {
            self.discoveredDevices = devices
        }
    }
    
    func stopDiscovery() {
        browser?.cancel()
        browser = nil
    }
} 