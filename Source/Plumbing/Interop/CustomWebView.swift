import SwiftUI
import WebKit

/*
 * Wrap a WKWebView and handle method calls from the SPA
 */
final class CustomWebView: NSObject, UIViewRepresentable, WKNavigationDelegate, WKScriptMessageHandler {

    private let configuration: Configuration
    private let oidcManager: OIDCManager
    private let onWebViewLoadError: (UIError) -> Void
    private let width: CGFloat
    private let height: CGFloat

    /*
     * Store configuration and create the bridge object
     */
    init(configuration: Configuration,
         oidcManager: OIDCManager,
         onWebViewLoadError: @escaping (UIError) -> Void,
         width: CGFloat,
         height: CGFloat) {

        self.configuration = configuration
        self.oidcManager = oidcManager
        self.onWebViewLoadError = onWebViewLoadError
        self.width = width
        self.height = height
    }

    /*
     * Create the WKWebView and wire up behaviour
     */
    func makeUIView(context: Context) -> WKWebView {

        // Prevent Swift UI recreating the inner web view
        if WebViewCache.webView != nil {
            return WebViewCache.webView!
        }

        // First enable Javascript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        // Make a bridge to the mobile app available to our SPA
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "mobileBridge")
        configuration.userContentController.addUserScript(self.createConsoleLogUserScript())
        configuration.defaultWebpagePreferences = preferences

        // Create and return the web view
        let rect = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        WebViewCache.webView = WKWebView(frame: rect, configuration: configuration)
        WebViewCache.webView!.navigationDelegate = self
        return WebViewCache.webView!
    }

    /*
     * Load the view's content
     */
    func updateUIView(_ webview: WKWebView, context: Context) {

        // Prevent SwiftUI reloading the inner web view
        if WebViewCache.webView != nil && !WebViewCache.webViewLoaded {

            let webViewUrl = URL(string: self.configuration.app.webBaseUrl)
            if webViewUrl == nil || webViewUrl!.scheme != "https" {

                // Handle URLs that do not parse
                let error = ErrorHandler.fromMessage(message: "An invalid web view URL was supplied")
                let uiError = ErrorHandler.fromWebViewLoadError(error: error, url: self.configuration.app.webBaseUrl)
                self.onWebViewLoadError(uiError)

            } else {

                // Register for errors then load the view
                webview.navigationDelegate = self
                let request = URLRequest(url: webViewUrl!)
                webview.load(request)
                WebViewCache.webViewLoaded = true
            }
        }
    }

    /*
     * Handle errors loading the web content, and report the URL that has failed
     */
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error) {

        let uiError = ErrorHandler.fromWebViewLoadError(error: error, url: self.configuration.app.webBaseUrl)
        self.onWebViewLoadError(uiError)
    }

    /*
     * Handle incoming calls from Javascript by deferring to the Javascript bridge
     */
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage) {

        // Get the JSON request data
        let data = (message.body as? String)!.data(using: .utf8)!
        if let requestJson = try? JSONSerialization.jsonObject(with: data, options: []) {

            // Get a collection of top level fields
            if let requestFields = requestJson as? [String: Any] {

                // Start a coroutine for async handling
                let callbackName = requestFields["callbackName"] as? String
                DispatchQueue.main.startCoroutine {

                    do {

                        // Call the implementation
                        let bridge = JavascriptBridge(oidcManager: self.oidcManager)
                        let data = try bridge.handleMessage(requestFields: requestFields).await()

                        // Return a success response, to resolve the promise in the calling Javascript
                        if data != nil {
                            self.successResult(callbackName: callbackName!, result: data!)
                        }

                    } catch {

                        // Return an error response, to reject the promise in the calling Javascript
                        let uiError = ErrorHandler.fromException(error: error)
                        self.errorResult(callbackName: callbackName!, errorJson: uiError.toJson())
                    }
                }
            }
        }
    }

    /*
     * Override console.log for the SPA web view so that messages are captured by the mobile app
     */
    private func createConsoleLogUserScript() -> WKUserScript {

        let script = """
            var console = {
                log: function(msg) {
                    const data = {
                        methodName: 'log',
                        message: `${msg}`,
                    };
                    window.webkit.messageHandlers.mobileBridge.postMessage(JSON.stringify(data));
                }
            };
        """

        return WKUserScript(
            source: script,
            injectionTime: WKUserScriptInjectionTime.atDocumentStart,
            forMainFrameOnly: false
        )
    }

    /*
     * Return a success result to the SPA
     */
    private func successResult(callbackName: String, result: String) {

        let javascript = "window['\(callbackName)']('\(result)', null)"
        WebViewCache.webView?.evaluateJavaScript(javascript, completionHandler: nil)
    }

    /*
     * Return a failure result to the SPA
     */
    private func errorResult(callbackName: String, errorJson: String) {

        let javascript = "window['\(callbackName)'](null, '\(errorJson)')"
        WebViewCache.webView?.evaluateJavaScript(javascript, completionHandler: nil)
    }
}
