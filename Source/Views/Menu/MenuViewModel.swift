import Foundation

/*
 * A simple view model for the button menu items
 */
class MenuViewModel: ObservableObject {

    var configuration: Configuration?
    var oidcManager: OIDCManager?
    @Published var isLoggedIn: Bool = false

    /*
     * Set initial state after the app is initialised
     */
    func initialise(configuration: Configuration, oidcManager: OIDCManager, isLoggedIn: Bool) {
        self.configuration = configuration
        self.oidcManager = oidcManager
        self.isLoggedIn = isLoggedIn
    }
}
