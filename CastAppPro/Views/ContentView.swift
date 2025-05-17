import SwiftUI

struct ContentView: View {
    @State private var url = URL(string: "https://www.google.com")!
    @State private var showCastModal = false
    @State private var videoURL: String?
    @State private var isCasting = false
    @StateObject private var rokuController = RokuController()

    var body: some View {
        ZStack {
            WebView(url: $url, showCastModal: $showCastModal, videoURL: $videoURL)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        searchBar
                            .padding(.bottom, 4)
                        bottomToolbar
                            .padding(.bottom, 8)
                    }
                }
            // Cast Modal
            if showCastModal {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showCastModal = false
                    }
                CastModalView(isPresented: $showCastModal, videoURL: $videoURL, rokuController: rokuController)
                    .transition(.move(edge: .bottom))
            }
            // Remote Control
            if isCasting {
                VStack {
                    Spacer()
                    RemoteControlView(rokuController: rokuController)
                        .padding(.bottom, 20)
                }
            }
        }
        .onChange(of: videoURL) { newValue in
            if newValue != nil {
                showCastModal = true
            }
        }
        .onChange(of: rokuController.currentVideo) { video in
            isCasting = video != nil
        }
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Go back action (implement if needed)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            TextField("Search or enter website name", text: Binding(
                get: { url.absoluteString },
                set: { newValue in
                    if let newURL = URL(string: newValue) {
                        url = newURL
                    }
                }
            ))
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .frame(minHeight: 36)
            Button(action: {
                // Reload action (implement if needed)
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
            Button(action: {
                UIPasteboard.general.string = url.absoluteString
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
    }

    var bottomToolbar: some View {
        HStack {
            Button(action: {
                // Back action
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                // Forward action
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                // Share action
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                // Bookmarks action
            }) {
                Image(systemName: "book")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                UIPasteboard.general.string = url.absoluteString
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
        .padding(.horizontal, 32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 