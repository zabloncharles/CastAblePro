import SwiftUI
import WebKit

class NoAccessoryWKWebView: WKWebView {
    override var inputAccessoryView: UIView? { nil }
}

class WebViewModel: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var urlString: String = "https://www.google.com"
    var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func load(url: URL) {
        webView?.load(URLRequest(url: url))
    }
    
    func formatAndLoadURL(_ input: String) -> URL? {
        var formattedString = input
        
        // If the input doesn't have a scheme, try to add https://
        if !input.hasPrefix("http://") && !input.hasPrefix("https://") {
            // Check if it's a search query (contains spaces or doesn't look like a domain)
            if input.contains(" ") || !input.contains(".") {
                // Format as a Google search
                formattedString = "https://www.google.com/search?q=\(input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input)"
            } else {
                // Assume it's a domain and add https://
                formattedString = "https://\(input)"
            }
        }
        
        return URL(string: formattedString)
    }
}

struct WebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var showCastModal: Bool
    @Binding var videoURL: String?
    @ObservedObject var viewModel: WebViewModel
    var darkMode: Bool
    var autoDetectVideos: Bool
    @Binding var clearWebViewDataTrigger: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "videoDetected")
        configuration.userContentController = userContentController
        
        let webView = NoAccessoryWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        viewModel.webView = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        // Inject dark mode if needed
        if darkMode {
            let darkCSS = """
                (function() {
                    var style = document.getElementById('castablepro-dark');
                    if (!style) {
                        style = document.createElement('style');
                        style.id = 'castablepro-dark';
                        style.innerHTML = '* { background: #000 !important; color: #eee !important; border-color: #222 !important; } img, video { filter: brightness(0.8) !important; }';
                        document.head.appendChild(style);
                    }
                })();
            """
            webView.evaluateJavaScript(darkCSS, completionHandler: nil)
        } else {
            let removeCSS = """
                (function() {
                    var style = document.getElementById('castablepro-dark');
                    if (style) style.remove();
                })();
            """
            webView.evaluateJavaScript(removeCSS, completionHandler: nil)
        }
        // Clear browsing data if triggered
        if clearWebViewDataTrigger {
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                    print("Browsing data cleared!")
                }
            }
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if parent.autoDetectVideos {
                let script = """
                    var videos = document.getElementsByTagName('video');
                    if (videos.length > 0) {
                        for (var i = 0; i < videos.length; i++) {
                            videos[i].addEventListener('play', function() {
                                window.webkit.messageHandlers.videoDetected.postMessage(this.src);
                            });
                        }
                    }
                """
                webView.evaluateJavaScript(script) { _, error in
                    if let error = error {
                        print("Error injecting script: \(error)")
                    }
                }
            }
            DispatchQueue.main.async {
                self.parent.viewModel.canGoBack = webView.canGoBack
                self.parent.viewModel.canGoForward = webView.canGoForward
                self.parent.viewModel.urlString = webView.url?.absoluteString ?? ""
            }
            // Re-inject dark mode if needed
            if self.parent.darkMode {
                let darkCSS = """
                    (function() {
                        var style = document.getElementById('castablepro-dark');
                        if (!style) {
                            style = document.createElement('style');
                            style.id = 'castablepro-dark';
                            style.innerHTML = '* { background: #000 !important; color: #eee !important; border-color: #222 !important; } img, video { filter: brightness(0.8) !important; }';
                            document.head.appendChild(style);
                        }
                    })();
                """
                webView.evaluateJavaScript(darkCSS, completionHandler: nil)
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "videoDetected", let videoURL = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.videoURL = videoURL
                }
            }
        }
    }
} 