import SwiftUI

/*
* An error entity whose fields are rendered when there is a problem
*/
class UIError: Error, Codable {

    // Fields populated during error translation
    var area: String
    var errorCode: String
    var userMessage: String
    var utcTime: String
    var appAuthCode: String
    var details: String
    let stack: [String]

    /*
     * Create the error form supportable fields
     */
    init(area: String, errorCode: String, userMessage: String) {
        self.area = area
        self.errorCode = errorCode
        self.userMessage = userMessage
        self.appAuthCode = ""
        self.details = ""
        self.utcTime = ""
        self.stack = Thread.callStackSymbols
        self.utcTime = DateUtils.dateToUtcDisplayString(date: Date())
    }

    /*
     * Return a JSON representation of the error to return to the Web UI
     */
    func toJson() -> String {

        // Create a dictionary
        var data = [String: String]()
        data["area"] = self.area
        data["errorCode"] = self.errorCode
        data["userMessage"] = self.userMessage

        if !self.appAuthCode.isEmpty {
            data["appAuthCode"] = self.appAuthCode
        }

        // These fields are serialized as base 64 to prevent issues with dangerous characters
        if !self.details.isEmpty {
            data["details"] = self.details.data(using: .utf8)!.base64EncodedString()
        }

        if self.stack.count > 0 {
            let stackString = self.stack.joined(separator: "\n")
            data["stack"] = stackString.data(using: .utf8)!.base64EncodedString()
        }

        // Serialize the dictionary
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(data) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }

        return ""
    }
}
