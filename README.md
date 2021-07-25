# oauth.mobileweb.ios

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/59019915812241c390290fe1140b535f)](https://www.codacy.com/gh/gary-archer/oauth.mobileweb.ios/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=gary-archer/oauth.mobileweb.ios&amp;utm_campaign=Badge_Grade)

### Overview 

* An iOS Sample using OAuth and Open Id Connect, referenced in my blog at https://authguidance.com
* **The goal of this sample is to integrate Secured Web Content into an Open Id Connect Secured iOS App**

### Details

* See the [Overview Page](https://authguidance.com/2020/06/17/mobile-web-integration-goals/) for a summary and instructions on how to run the code
* See the post on [Coding Key Points](https://authguidance.com/2020/06/18/mobile-web-integration-coding-key-points/) for design aspects

### Technologies and Behaviour

* XCode 12 and SwiftUI 2 are used to develop an app that consumes Secured Web Content
* Secured ReactJS SPA views can be run from the mobile app, without a second login 
* SPA views can execute in a web view and call back the mobile app to get tokens
* SPA views can alternatively execute in a system browser and rely on Single Sign On cookies

### Middleware Used

* The [AppAuth-iOS Library](https://github.com/openid/AppAuth-iOS) implements Authorization Code Flow (PKCE) via a Claimed HTTPS Scheme
* AWS API Gateway is used to host our sample OAuth Secured API
* AWS Cognito is used as the default Authorization Server
* The iOS Keychain is used to store encrypted tokens on the device after login
* AWS S3 and Cloudfront are used to serve mobile deep linking asset files and interstitial web pages
