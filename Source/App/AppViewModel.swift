import Foundation
import SwiftCoroutine
import SwiftUI

/*
 * A primitive view model class to manage global objects and state
 */
class AppViewModel: ObservableObject {

    @Published var isInitialised = false
    @Published var configuration: Configuration?
    @Published var oidcManager: OIDCManager?
    @Published var error: UIError?
    @Published var menuViewModel = MenuViewModel()

    /*
     * Read configuration and create global objects
     */
    func initialise() throws {

        // Reset state flags
        self.isInitialised = false

        // Load configuration and create global objects
        self.configuration = try ConfigurationLoader.load()
        let authenticator = AuthenticatorImpl(configuration: self.configuration!.oauth)
        self.oidcManager = OIDCManager(authenticator: authenticator)

        // Create the menu view model
        self.menuViewModel.initialise(
            configuration: self.configuration!,
            oidcManager: self.oidcManager!,
            isLoggedIn: self.oidcManager!.authenticator.isLoggedIn())

        // Indicate successful startup
        self.isInitialised = true
    }

    /*
     * Process any claimed HTTPS scheme login / logout responses
     */
    func handleOAuthResponse(url: URL) {

        let authenticator = self.oidcManager!.authenticator
        if authenticator.isOAuthResponse(responseUrl: url) {
            authenticator.resumeOperation(responseUrl: url)
        }
    }
}
