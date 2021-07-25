import SwiftUI
import SafariServices

/*
 * A simple menu area container
 */
struct MenuView: View {

    @ObservedObject private var model: MenuViewModel
    @State private var showModal = false
    private let onError: (UIError) -> Void
    private let onResetError: () -> Void

    init(model: MenuViewModel,
         onError: @escaping (UIError) -> Void,
         onResetError: @escaping () -> Void) {

        self.model = model
        self.onError = onError
        self.onResetError = onResetError
    }

    /*
     * Render the menu area
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width

        return VStack {

            // Allow the user to choose how to execute the web content
            VStack {

                Button(action: self.onSignIn) {
                   Text("1. Sign In to Mobile App")
                }
                .buttonStyle(MenuButtonStyle(width: deviceWidth * 0.77, disabled: self.model.isLoggedIn))
                .disabled(self.model.isLoggedIn)

                Button(action: self.onInvokeSystemBrowser) {
                   Text("2. Run SPA in System Browser")
                }
                .buttonStyle(MenuButtonStyle(width: deviceWidth * 0.75, disabled: !self.model.isLoggedIn))
                .disabled(!self.model.isLoggedIn)

                Button(action: self.onInvokeInAppBrowser) {
                   Text("3. Run SPA via In App Browser")
                }
                .buttonStyle(MenuButtonStyle(width: deviceWidth * 0.75, disabled: !self.model.isLoggedIn))
                .disabled(!self.model.isLoggedIn)

                Button {
                    self.showModal = true
                } label: {
                    Text("4. Run SPA in Web View")
                }
                .sheet(isPresented: self.$showModal) {
                    self.onInvokeWebView()
                }
                .buttonStyle(MenuButtonStyle(width: deviceWidth * 0.75, disabled: !self.model.isLoggedIn))
                .disabled(!self.model.isLoggedIn)

                Button(action: self.onSignOut) {
                   Text("5. Sign Out from Mobile App")
                }
                .buttonStyle(MenuButtonStyle(width: deviceWidth * 0.75, disabled: !self.model.isLoggedIn))
                .disabled(!self.model.isLoggedIn)
            }
        }
    }

    /*
     * Perform the Open Id Connect sign in
     */
    private func onSignIn() {

        let onLoginSuccess = {
            self.onResetError()
            self.model.isLoggedIn = true
        }

        DispatchQueue.main.startCoroutine {

            self.model.oidcManager!.login(
                onSuccess: onLoginSuccess,
                onError: self.onError)
        }
    }

    /*
     * Perform the Open Id Connect sign out
     */
    private func onSignOut() {

        let onLogoutSuccess = {
            self.onResetError()
            self.model.isLoggedIn = false
        }

        let onLogoutError: (UIError) -> Void = { error in
            self.model.isLoggedIn = false
            self.onError(error)
        }

        DispatchQueue.main.startCoroutine {

            self.model.oidcManager!.logout(
                onSuccess: onLogoutSuccess,
                onError: onLogoutError)
        }
    }

    /*
     * Open our SPA in the system browser
     */
    private func onInvokeSystemBrowser() {

        self.onResetError()
        let url = URL(string: self.model.configuration!.app.webBaseUrl)!
        UIApplication.shared.open(url, options: [:], completionHandler: { success in

            // Handle errors if a URL fails to load
            if !success {
                let uiError = ErrorHandler.fromSystemBrowserLoadError(
                    url: self.model.configuration!.app.webBaseUrl)
                self.onError(uiError)
            }
        })
    }

    /*
     * Open our SPA in the integrated Safari View Controller browser
     * https://www.hackingwithswift.com/read/32/3/how-to-use-sfsafariviewcontroller-to-browse-a-web-page
     */
    private func onInvokeInAppBrowser() {

        self.onResetError()
        let safariConfiguration = SFSafariViewController.Configuration()
        safariConfiguration.entersReaderIfAvailable = true

        // Run the Safari View Controller
        let url = URL(string: self.model.configuration!.app.webBaseUrl)
        if url == nil || url!.scheme != "https" {

            // Handle URLs that do not parse
            let uiError = ErrorHandler.fromInAppBrowserLoadError(
                url: self.model.configuration!.app.webBaseUrl)
            self.onError(uiError)

        } else {

            // Attempt to browse to valid URLs
            let safari = SFSafariViewController(url: url!, configuration: safariConfiguration)
            self.getHostingViewController().present(safari, animated: true)
        }
    }

    /*
     * Invoke web content in a web view
     */
    private func onInvokeWebView() -> WebViewDialog {

        let deviceWidth = UIScreen.main.bounds.size.width
        let deviceHeight = UIScreen.main.bounds.size.height
        self.onResetError()

        return WebViewDialog(
            configuration: self.model.configuration!,
            oidcManager: self.model.oidcManager!,
            onDismissed: {
                self.model.isLoggedIn = self.model.oidcManager!.authenticator.isLoggedIn()
            },
            onError: self.onError,
            width: deviceWidth,
            height: deviceHeight)
    }

    /*
     * A helper method to get the scene delegate, on which OAuth responses are received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
