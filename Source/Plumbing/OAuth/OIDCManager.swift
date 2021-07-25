import Foundation
import SwiftCoroutine
import SwiftUI

/*
 * An entry point class for OAuth processing, shared between native mobile and webview processing
 */
class OIDCManager {

    let authenticator: Authenticator
    var isTopMost: Bool

    /*
     * Store details from the main view
     */
    init(authenticator: Authenticator) {
        self.authenticator = authenticator
        self.isTopMost = true
    }

    /*
     * The entry point for login redirects
     */
    func login(
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        // Prevent re-entrancy
        if !self.isTopMost {
            return
        }

        do {
            // Do the login redirect on the UI thread
            self.isTopMost = false
            let viewController = self.getHostingViewController()
            let response = try self.authenticator.startLogin(viewController: viewController)
                .await()

            // Do the code exchange on a background thread
            try DispatchQueue.global().await {
                try self.authenticator.finishLogin(authResponse: response)
                    .await()
            }

            // Do post login success processing
            self.isTopMost = true
            onSuccess()

        } catch {

            // Do post login error processing
            self.isTopMost = true
            let uiError = ErrorHandler.fromException(error: error)
            onError(uiError)
        }
    }

    /*
     * The entry point for logout redirects
     */
    func logout(
        onSuccess: @escaping () -> Void,
        onError: @escaping (UIError) -> Void) {

        // Prevent re-entrancy
        if !self.isTopMost {
            return
        }

        do {
            // Ask the authenticator to do the OAuth work
            self.isTopMost = false
            let viewController = self.getHostingViewController()
            try self.authenticator.logout(viewController: viewController)
                .await()

            // Do post logout success processing
            self.isTopMost = true
            onSuccess()

        } catch {

            // Do post logout error processing
            self.isTopMost = true
            let uiError = ErrorHandler.fromException(error: error)
            onError(uiError)
        }
    }

    /*
     * A helper method to get the scene delegate, on which OAuth responses are received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
