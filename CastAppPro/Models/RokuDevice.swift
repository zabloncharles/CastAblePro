import Foundation

struct RokuDevice: Identifiable {
    let id: String
    let name: String
    let ipAddress: String
    let port: UInt16
    
    init(id: String, name: String, ipAddress: String, port: UInt16 = 8060) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
    }
}

struct VideoMetadata: Equatable {
    let url: String
    let title: String
    var duration: Double
    var currentPosition: Double
    var isPlaying: Bool
    
    init(url: String, title: String, duration: Double = 0, currentPosition: Double = 0, isPlaying: Bool = false) {
        self.url = url
        self.title = title
        self.duration = duration
        self.currentPosition = currentPosition
        self.isPlaying = isPlaying
    }
    
    static func == (lhs: VideoMetadata, rhs: VideoMetadata) -> Bool {
        return lhs.url == rhs.url &&
               lhs.title == rhs.title &&
               lhs.duration == rhs.duration &&
               lhs.currentPosition == rhs.currentPosition &&
               lhs.isPlaying == rhs.isPlaying
    }
} 