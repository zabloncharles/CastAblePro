import SwiftUI

struct RemoteControlView: View {
    @ObservedObject var rokuController: RokuController
    @State private var seekPosition: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            if let video = rokuController.currentVideo {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            // Playback time display
            HStack {
                Text(formatTime(rokuController.currentPosition))
                Spacer()
                Text(formatTime(rokuController.duration))
            }
            .font(.caption)
            .padding(.horizontal)
            
            // Seek slider
            Slider(value: $seekPosition, in: 0...rokuController.duration) { editing in
                if !editing {
                    rokuController.seek(to: seekPosition)
                }
            }
            .padding(.horizontal)
            
            // Playback controls
            HStack(spacing: 40) {
                Button(action: {
                    rokuController.seek(to: max(0, rokuController.currentPosition - 10))
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.title)
                }
                
                Button(action: {
                    if rokuController.isPlaying {
                        rokuController.pause()
                    } else {
                        rokuController.play()
                    }
                }) {
                    Image(systemName: rokuController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                }
                
                Button(action: {
                    rokuController.seek(to: min(rokuController.duration, rokuController.currentPosition + 10))
                }) {
                    Image(systemName: "goforward.10")
                        .font(.title)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            seekPosition = rokuController.currentPosition
        }
        .onChange(of: rokuController.currentPosition) { newPosition in
            seekPosition = newPosition
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
} 