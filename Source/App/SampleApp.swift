import Foundation
import SwiftUI

/*
 * The application entry point
 */
@main
struct SampleApp: App {

    private let appViewModel = AppViewModel()
    private let orientationHandler = OrientationHandler()

    /*
     * The app's main layout
     */
    var body: some Scene {

        WindowGroup {
            AppView(model: self.appViewModel)
                .environmentObject(self.orientationHandler)
                .onOpenURL(perform: self.appViewModel.handleOAuthResponse)
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in

                    // Handle orientation changes in the app by updating the handler
                    // We also need to include the handler as an environment object in all views which need redrawing
                    self.orientationHandler.isLandscape = UIDevice.current.orientation.isLandscape
                }
        }
    }
}
