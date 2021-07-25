import SwiftUI
import WebKit

/*
 * The web view dialog's overall layout
 */
struct WebViewDialog: View {

    @Environment(\.presentationMode) private var presentationMode
    private let configuration: Configuration
    private let oidcManager: OIDCManager
    private let onDismissed: () -> Void
    private let onError: (UIError) -> Void
    private let width: CGFloat
    private let height: CGFloat

    /*
     * Store configuration and create the bridge object
     */
    init(configuration: Configuration,
         oidcManager: OIDCManager,
         onDismissed: @escaping () -> Void,
         onError: @escaping (UIError) -> Void,
         width: CGFloat,
         height: CGFloat) {

        self.configuration = configuration
        self.oidcManager = oidcManager
        self.onDismissed = onDismissed
        self.onError = onError
        self.width = width
        self.height = height
    }

    /*
     * Render the view
     */
    var body: some View {

        GeometryReader { geometry in

            VStack {

                HStack(spacing: 0) {

                    // Render the title
                    Text("")
                        .font(.headline)
                        .frame(width: geometry.size.width * 0.9)

                    // Render a close button to the right
                    Text("X")
                        .frame(width: geometry.size.width * 0.1, alignment: .leading)
                        .onTapGesture(perform: self.onClose)

                }.padding(.top)

                // Render the SPA in a web view
                CustomWebView(
                    configuration: self.configuration,
                    oidcManager: self.oidcManager,
                    onWebViewLoadError: self.onWebViewLoadError,
                    width: self.width,
                    height: self.height)

            }.contentShape(Rectangle())
        }
    }

    /*
     * Handle web view load errors by informing the parent then closing the dialog
     */
    private func onWebViewLoadError(error: UIError) {
        self.onError(error)
        self.onClose()
    }

    /*
     * Handle closing the modal dialog
     */
    private func onClose() {

        // Clear the cached web view
        WebViewCache.clear()

        // Dismiss the dialog
        self.presentationMode.wrappedValue.dismiss()

        // Inform the parent
        self.onDismissed()
    }
}
