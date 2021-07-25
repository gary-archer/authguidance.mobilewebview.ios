import Foundation

/*
 * A class to manage error translation
 */
struct ErrorHandler {

    static let AppAuthNamespace = "org.openid.appauth."

    /*
     * Translate a general exception into a form ready for display
     */
    static func fromException(
        error: Error,
        errorCode: String? = nil,
        userMessage: String? = nil) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Initialise top level fields
        let message = userMessage != nil ? userMessage! : "A technical problem was encountered in the UI"
        let code = errorCode != nil ? errorCode! : ErrorCodes.generalUIError

        // Create the error object
        uiError = UIError(
            area: "Mobile UI",
            errorCode: code,
            userMessage: message)

        // Update from the caught exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Used to throw programming level errors that should not occur
     * Equivalent to throwing a RuntimeException in Android
     */
    static func fromMessage(message: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.generalUIError,
            userMessage: message)
    }

    /*
     * Used when we cannot parse a URL to load into a web view
     */
    static func fromWebViewLoadError(url: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.loadWebViewFailed,
            userMessage: "A problem was encountered loading the Web View at \(url)")
    }

    /*
     * Used when the web view endpoint is not contactable
     */
    static func fromWebViewLoadError(error: Error, url: String) -> UIError {

        let uiError = ErrorHandler.fromWebViewLoadError(url: url)
        ErrorHandler.updateFromException(error: error, uiError: uiError)
        return uiError
    }

    /*
     * Used when we cannot open an In App Browser at a URL
     */
    static func fromInAppBrowserLoadError(url: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.loadInAppBrowserFailed,
            userMessage: "A problem was encountered loading the In App Browser at \(url)")
    }

    /*
     * Used when we cannot open the system browser at a URL
     */
    static func fromSystemBrowserLoadError(url: String) -> UIError {

        return UIError(
            area: "Mobile UI",
            errorCode: ErrorCodes.loadSystemBrowserFailed,
            userMessage: "A problem was encountered loading the System Browser at \(url)")
    }

    /*
     * Return an error to short circuit execution
     */
    static func fromLoginRequired() -> UIError {

        return UIError(
            area: "Login",
            errorCode: ErrorCodes.loginRequired,
            userMessage: "A login is required so the API call was aborted")
    }

    /*
     * Return an error to indicate that the Safari View Controller window was closed
     */
    static func fromRedirectCancelled() -> UIError {

        return UIError(
            area: "Redirect",
            errorCode: ErrorCodes.redirectCancelled,
            userMessage: "The redirect request was cancelled")
    }

    /*
     * Handle errors triggering login requests
     */
    static func fromLoginRequestError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        uiError = UIError(
            area: "Login",
            errorCode: ErrorCodes.loginRequestFailed,
            userMessage: "A technical problem occurred during login processing"
        )

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Handle errors processing login responses
     */
    static func fromLoginResponseError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        uiError = UIError(
            area: "Login",
            errorCode: ErrorCodes.loginResponseFailed,
            userMessage: "A technical problem occurred during login processing"
        )

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Handle logout errors
     */
    static func fromLogoutRequestError(error: Error) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Create the error
        uiError = UIError(
            area: "Logout",
            errorCode: ErrorCodes.logoutRequestFailed,
            userMessage: "A technical problem occurred during logout processing")

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Handle token related errors
     */
    static func fromTokenError(error: Error, errorCode: String) -> UIError {

        // Already handled
        var uiError = error as? UIError
        if uiError != nil {
            return uiError!
        }

        // Create the error
        uiError = UIError(
            area: "Token",
            errorCode: errorCode,
            userMessage: "A technical problem occurred during token processing")

        // Update it from the exception
        ErrorHandler.updateFromException(error: error, uiError: uiError!)
        return uiError!
    }

    /*
     * Add iOS details from the exception
     */
    private static func updateFromException(error: Error, uiError: UIError) {

        let nsError = error as NSError
        var details = error.localizedDescription

        // Get iOS common details
        if nsError.domain.count > 0 {
            details += "\nDomain: \(nsError.domain)"
        }
        if nsError.code != 0 {
            details += "\nCode: \(nsError.code)"
        }
        for (name, value) in nsError.userInfo {
            details += "\n\(name): \(value)"
        }

        // Get details to assist with lookups in AppAuth error files
        if nsError.domain.contains(ErrorHandler.AppAuthNamespace) {
            let category = ErrorHandler.getAppAuthCategory(domain: nsError.domain)
            uiError.appAuthCode = "\(category) / \(nsError.code)"
        }

        uiError.details = details
    }

    /*
     * Translate the error category to a readable form
     */
    private static func getAppAuthCategory(domain: String) -> String {

        // Remove the namespace
        let category = domain.replacingOccurrences(
            of: ErrorHandler.AppAuthNamespace,
            with: "")
                .uppercased()

        // Remove the OAUTH prefix, to form a value such as 'TOKEN'
        return category.replacingOccurrences(
            of: "OAUTH_",
            with: "")
                .uppercased()
    }
}
