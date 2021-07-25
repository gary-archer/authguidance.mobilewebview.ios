import Foundation
import SwiftUI
import SwiftCoroutine

/*
 * Receive Javascript requests, do the mobile work, then return a Javascript response
 */
class JavascriptBridge: ObservableObject {

    private let oidcManager: OIDCManager

    init(oidcManager: OIDCManager) {
        self.oidcManager = oidcManager
    }

    /*
     * Handle incoming messages from Javascript
     */
    func handleMessage(requestFields: [String: Any]) throws -> CoFuture<String?> {

        let promise = CoPromise<String?>()
        var result: String?

        do {

            // Determine and call the method
            let methodName = requestFields["methodName"] as? String
            switch methodName {

            case "isLoggedIn":
                result = try self.isLoggedIn()

            case "getAccessToken":
                result = try self.getAccessToken().await()

            case "refreshAccessToken":
                result = try self.refreshAccessToken().await()

            case "login":
                result = try self.login().await()

            case "logout":
                result = try self.logout().await()

            case "expireAccessToken":
                result = try self.expireAccessToken()

            case "expireRefreshToken":
                result = try self.expireRefreshToken()

            default:
                self.log(message: requestFields["message"] as? String)
            }

            // Return a success result
            promise.success(result)

        } catch {

            // Return a failure result
            promise.fail(error)
        }

        return promise
    }

    /*
     * Return true if logged in
     */
    private func isLoggedIn() throws -> String {

        let isLoggedIn = self.oidcManager.authenticator.isLoggedIn()
        return String(isLoggedIn)
    }

    /*
     * Handle SPA requests to get an access token
     */
    private func getAccessToken() throws -> CoFuture<String> {

        let promise = CoPromise<String>()

        do {
            let accessToken = try self.oidcManager.authenticator.getAccessToken().await()
            promise.success(accessToken)

        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Handle SPA requests to refresh an access token
     */
    private func refreshAccessToken() throws -> CoFuture<String> {

        let promise = CoPromise<String>()

        do {
            let accessToken = try self.oidcManager.authenticator.refreshAccessToken().await()
            promise.success(accessToken)

        } catch {
            promise.fail(error)
        }

        return promise
    }

    /*
     * Handle SPA requests to trigger a login redirect
     */
    private func login() throws -> CoFuture<String> {

        let promise = CoPromise<String>()

        let onLoginSuccess = {
            promise.success("")
        }

        let onLoginError: (UIError) -> Void = { error in
            promise.fail(error)
        }

        self.oidcManager.login(onSuccess: onLoginSuccess, onError: onLoginError)
        return promise
    }

    /*
     * Handle SPA requests to trigger a logout redirect
     */
    private func logout() throws -> CoFuture<String> {

        let promise = CoPromise<String>()

        let onLogoutSuccess = {
            promise.success("")
        }

        let onLogoutError: (UIError) -> Void = { error in
            promise.fail(error)
        }

        self.oidcManager.logout(onSuccess: onLogoutSuccess, onError: onLogoutError)
        return promise
    }

    /*
     * Handle test requests from the SPA to expire the access token
     */
    private func expireAccessToken() throws -> String {

        self.oidcManager.authenticator.expireAccessToken()
        return ""
    }

    /*
     * Handle test requests from the SPA to expire the access token
     */
    private func expireRefreshToken() throws -> String {

        self.oidcManager.authenticator.expireRefreshToken()
        return ""
    }

    /*
     * A helper method to get the scene delegate, on which the login response is received
     */
    private func getHostingViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }

    /*
     * Log a Javascript message from the SPA in the mobile app
     */
    private func log(message: String?) {

        if message != nil {
            print("MobileDebug: \(message!)")
        }
    }
}
