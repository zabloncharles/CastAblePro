import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var showCastModal: Bool
    @Binding var videoURL: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "videoDetected")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "videoDetected", let videoURL = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.videoURL = videoURL
                }
            }
        }
    }
} 