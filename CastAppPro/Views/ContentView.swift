import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode: Bool = false
    @AppStorage("homePage") private var homePage: String = "https://www.google.com"
    @AppStorage("autoDetectVideos") private var autoDetectVideos: Bool = true
    @State private var url: URL = URL(string: "https://www.google.com")!
    @State private var showCastModal = false
    @State private var videoURL: String?
    @State private var isCasting = false
    @StateObject private var rokuController = RokuController()
    @StateObject private var webViewModel = WebViewModel()
    @FocusState private var searchFocused: Bool
    @State private var showSettings = false
    // For clearing browsing data
    @State private var clearWebViewDataTrigger = false

    var body: some View {
        NavigationView {
            ZStack {
                (darkMode ? Color.black : Color.white)
                    .ignoresSafeArea(edges: .top)
                WebView(
                    url: $url,
                    showCastModal: $showCastModal,
                    videoURL: $videoURL,
                    viewModel: webViewModel,
                    darkMode: darkMode,
                    autoDetectVideos: autoDetectVideos,
                    clearWebViewDataTrigger: $clearWebViewDataTrigger
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        searchBar
                            .padding(.bottom, 4)
                        bottomToolbar
                            .padding(.bottom, 8)
                    }.background(darkMode ? Color.black : Color.white)
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
                NavigationLink(destination: SettingsView(
                    darkMode: $darkMode,
                    homePage: $homePage,
                    autoDetectVideos: $autoDetectVideos,
                    clearWebViewDataTrigger: $clearWebViewDataTrigger,
                    connectedDevice: $rokuController.connectedDevice,
                    disconnectDevice: { rokuController.connectedDevice = nil }
                ), isActive: $showSettings) { EmptyView() }
            }
            .onAppear {
                url = URL(string: homePage) ?? URL(string: "https://www.google.com")!
            }
            .onChange(of: homePage) { newValue in
                url = URL(string: newValue) ?? URL(string: "https://www.google.com")!
            }
            .onChange(of: videoURL) { newValue in
                if newValue != nil {
                    showCastModal = true
                }
            }
            .onChange(of: rokuController.currentVideo) { video in
                isCasting = video != nil
            }
            .onChange(of: webViewModel.urlString) { newValue in
                if let newURL = URL(string: newValue), newURL != url {
                    url = newURL
                }
            }
            .navigationBarHidden(true)
        }
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                webViewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(webViewModel.canGoBack ? .blue : .gray)
            }
            TextField("Search or enter website name", text: $webViewModel.urlString, onCommit: {
                if let newURL = URL(string: webViewModel.urlString) {
                    url = newURL
                    searchFocused = false
                }
            })
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .frame(minHeight: 36)
            .focused($searchFocused)

            if searchFocused {
                Button(action: {
                    if let newURL = URL(string: webViewModel.urlString) {
                        url = newURL
                        searchFocused = false
                    }
                }) {
                    Text("Go")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .transition(.opacity)
            } else {
                Button(action: {
                    webViewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                Button(action: {
                    UIPasteboard.general.string = webViewModel.urlString
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(darkMode ? Color.black : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
        .animation(.easeInOut(duration: 0.18), value: searchFocused)
    }

    var bottomToolbar: some View {
        HStack {
            Button(action: {
                webViewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(webViewModel.canGoBack ? .blue : .gray)
            }
            Spacer()
            Button(action: {
                webViewModel.goForward()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(webViewModel.canGoForward ? .blue : .gray)
            }
            Spacer()
            Button(action: {
                // Share action (implement if needed)
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                // Bookmarks action (implement if needed)
            }) {
                Image(systemName: "book")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(darkMode ? Color.black : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
        .padding(.horizontal, 32)
    }
}

struct SettingsView: View {
    @Binding var darkMode: Bool
    @Binding var homePage: String
    @Binding var autoDetectVideos: Bool
    @Binding var clearWebViewDataTrigger: Bool
    @Binding var connectedDevice: RokuDevice?
    var disconnectDevice: () -> Void
    @State private var showClearAlert = false
    @State private var showResetAlert = false
    @State private var feedbackURL = URL(string: "mailto:support@castablepro.com")!
    @State private var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    var body: some View {
        ZStack {
            (darkMode ? Color.black : Color.white)
                .ignoresSafeArea()
            Form {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $darkMode) {
                        Text("Dark Mode")
                            .foregroundColor(darkMode ? .white : .primary)
                    }
                }
                .listRowBackground(darkMode ? Color.black : Color.white)
                Section(header: Text("Browser")) {
                    TextField("Default Home Page", text: $homePage)
                        .foregroundColor(darkMode ? .white : .primary)
                        .listRowBackground(darkMode ? Color.black : Color.white)
                    Toggle(isOn: $autoDetectVideos) {
                        Text("Auto-Detect Videos")
                            .foregroundColor(darkMode ? .white : .primary)
                    }
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Text("Clear Browsing Data")
                    }
                    .alert("Clear all browsing data?", isPresented: $showClearAlert) {
                        Button("Clear", role: .destructive) {
                            clearWebViewDataTrigger.toggle()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }.listRowBackground(darkMode ? Color.black : Color.white)
                Section(header: Text("Device")) {
                    HStack {
                        Text("Connected Device")
                            .foregroundColor(darkMode ? .white : .primary)
                        Spacer()
                        if let device = connectedDevice {
                            Text(device.name)
                                .foregroundColor(.blue)
                        } else {
                            Text("None")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(role: .destructive) {
                        disconnectDevice()
                    } label: {
                        Text("Disconnect Device")
                            .foregroundColor(darkMode ? .gray : .gray)
                    }
                    .disabled(connectedDevice == nil)
                }.listRowBackground(darkMode ? Color.black : Color.white)
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                            .foregroundColor(darkMode ? .white : .primary)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    Link(destination: feedbackURL) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://github.com/zabloncharles/CastAblePro")!) {
                        Label("GitHub Repo", systemImage: "link")
                    }
                }
                .listRowBackground(darkMode ? Color.black : Color.white)
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Reset All Settings")
                    }
                    .alert("Reset all settings?", isPresented: $showResetAlert) {
                        Button("Reset", role: .destructive) {
                            UserDefaults.standard.removeObject(forKey: "darkMode")
                            UserDefaults.standard.removeObject(forKey: "homePage")
                            UserDefaults.standard.removeObject(forKey: "autoDetectVideos")
                            // Add more keys if you add more settings
                            darkMode = false
                            homePage = "https://www.google.com"
                            autoDetectVideos = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }.listRowBackground(darkMode ? Color.black : Color.white)
            }
            .background(darkMode ? Color.black : Color.white)
            .scrollContentBackground(.hidden)
        }
        .toolbarBackground(darkMode ? Color.black : Color(.systemGroupedBackground), for: .navigationBar)
        .toolbarBackground(darkMode ? Color.black : Color(.systemGroupedBackground), for: .automatic)
        .navigationTitle("Settings")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
