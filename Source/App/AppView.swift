import SwiftUI

/*
 * The main view of the app is a full screen web view
 */
struct AppView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var model: AppViewModel

    init(model: AppViewModel) {
        self.model = model
    }

    /*
     * Render a webview in the entire area
     */
    var body: some View {

        return VStack {

            // Show the title area
            TitleView()

            // Display application level errors when applicable
            if self.model.error != nil && self.model.error!.errorCode != ErrorCodes.redirectCancelled {

                ErrorSummaryView(
                    hyperlinkText: "Application Problem Encountered",
                    dialogTitle: "Application Error",
                    error: self.model.error!)
                        .padding(.bottom)
            }

            // Show the menu view in the main mobile area
            if self.model.isInitialised {
                MenuView(
                    model: self.model.menuViewModel,
                    onError: self.handleError,
                    onResetError: self.resetError
                )
            }

            // Fill up the remainder of the view if needed
            Spacer()
        }
        .onAppear(perform: self.initialiseApp)
    }

    /*
     * The main startup logic occurs after the initial render
     */
    private func initialiseApp() {

        do {
            // Initialise the model, which manages mutable data
            try self.model.initialise()

        } catch {

            // Report error details
            self.model.error = ErrorHandler.fromException(error: error)
        }
    }

    /*
     * Receive errors from other parts of the app
     */
    func handleError(error: UIError) {
        self.model.error = error
    }

    /*
     * Reset previous errors
     */
    func resetError() {
        self.model.error = nil
    }
}
