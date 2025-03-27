//
//  AuthViewModel.swift
//  MSALiOS
//
//  Created by Hafiz Saad on 26/03/2025.
//  Copyright © 2025 Microsoft. All rights reserved.
//

import MSAL
import Combine

enum AuthConstants {
    static let clientID = "5e4e4817-67f8-4e91-9cf2-3b13a8e86761"
    static let graphEndpoint = "https://graph.microsoft.com/v1.0/me/"
    static let authority = "https://login.microsoftonline.com/443fdb4d-77c8-482a-961a-4c2fee164ef5"
    static let redirectUri = "msauth.com.microsoft.identitysample.MSALiOS://auth"
    static let scopes = ["api://5e4e4817-67f8-4e91-9cf2-3b13a8e86761/NX.User.Read"]
}

class AuthViewModel {
    private var applicationContext: MSALPublicClientApplication?
    private var webViewParameters: MSALWebviewParameters?
    private var currentAccount: MSALAccount?
    private var currentDeviceMode: MSALDeviceMode?

    typealias AccountCompletion = (MSALAccount?) -> Void
    
    var logUpdate = PassthroughSubject<String, Never>()
    var accountUpdate = PassthroughSubject<MSALAccount?, Never>()
    var signOutStatusChange = PassthroughSubject<Bool, Never>()
    @Published var deviceModeMessage: String?
    
    /**
     Initialize a MSALPublicClientApplication with a given clientID and authority
     
     - clientId:            The clientID of your application, you should get this from the app portal.
     - redirectUri:         A redirect URI of your application, you should get this from the app portal.
     If nil, MSAL will create one by default. i.e./ msauth.<bundleID>://auth
     - authority:           A URL indicating a directory that MSAL can use to obtain tokens. In Azure AD
     it is of the form https://<instance/<tenant>, where <instance> is the
     directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
     identifier within the directory itself (e.g. a domain associated to the
     tenant, such as contoso.onmicrosoft.com, or the GUID representing the
     TenantID property of the directory)
     - error                The error that occurred creating the application object, if any, if you're
     not interested in the specific error pass in nil.
     */
    
    func initMSAL(parentViewController: UIViewController) {
        do {
            guard let authorityURL = URL(string: AuthConstants.authority) else {
                logUpdate.send("Unable to create authority URL")
                return
            }
            let authority = try MSALAADAuthority(url: authorityURL)
            let msalConfiguration = MSALPublicClientApplicationConfig(
                clientId: AuthConstants.clientID,
                redirectUri: AuthConstants.redirectUri,
                authority: authority
            )
            applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
            webViewParameters = MSALWebviewParameters(authPresentationViewController: parentViewController)
        } catch {
            logUpdate.send("Unable to create Application Context \(error)")
        }
    }
    
    func loadCurrentAccount(completion: AccountCompletion? = nil) {
        guard let applicationContext = applicationContext else { return }
        
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
        
        // Note that this sample showcases an app that signs in a single account at a time
        // If you're building a more complex app that signs in multiple accounts at the same time, you'll need to use a different account retrieval API that specifies account identifier
        // For example, see "accountsFromDeviceForParameters:completionBlock:" - https://azuread.github.io/microsoft-authentication-library-for-objc/Classes/MSALPublicClientApplication.html#/c:objc(cs)MSALPublicClientApplication(im)accountsFromDeviceForParameters:completionBlock:
        applicationContext.getCurrentAccount(with: msalParameters) { [weak self] (currentAccount, previousAccount, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logUpdate.send("Couldn't query current account with error: \(error)")
                return
            }
            
            if let currentAccount = currentAccount {
                self.logUpdate.send("Found a signed-in account \(currentAccount.username ?? ""). Updating data for that account...")
                
                self.currentAccount = currentAccount
                self.accountUpdate.send(currentAccount)
                self.signOutStatusChange.send(true)
                
                if let completion = completion {
                    completion(self.currentAccount)
                }
                
                return
            }
            
            // If testing with Microsoft's shared device mode, see the account that has been signed out from another app. More details here:
            // https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-ios-shared-devices
            if let previousAccount = previousAccount {
                self.logUpdate.send("The account with username \(previousAccount.username ?? "") has been signed out.")
            } else {
                self.logUpdate.send("Account signed out. Updating UX")
            }
            
            self.currentAccount = nil
            self.accountUpdate.send(nil)
            self.signOutStatusChange.send(false)
            
            if let completion = completion {
                completion(nil)
            }
        }
    }
    
    func callGraphAPI() {
        self.loadCurrentAccount { [weak self] (account) in
            guard let self = self else { return }
            guard let currentAccount = account else {
                
                // We check to see if we have a current logged in account.
                // If we don't, then we need to sign someone in.
                self.acquireTokenInteractively()
                return
            }
            
            self.acquireTokenSilently(currentAccount)
        }
    }
    
    private func acquireTokenInteractively() {
        guard let applicationContext = applicationContext, let webViewParameters = webViewParameters else { return }
        
        let parameters = MSALInteractiveTokenParameters(scopes: AuthConstants.scopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        applicationContext.acquireToken(with: parameters) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.logUpdate.send("Could not acquire token: \(error)")
                return
            }
            guard let result = result else {
                self.logUpdate.send("Could not acquire token: No result returned")
                return
            }
            self.logUpdate.send("Access token is \(result.accessToken)")
            self.currentAccount = result.account
            self.accountUpdate.send(result.account)
            self.signOutStatusChange.send(true)
            self.showTenantProfileClaims()
        }
    }
    
    func showTenantProfileClaims() {
        if let tenantProfile = currentAccount?.tenantProfiles?.first,
           let claims = tenantProfile.claims {
            let result = claims.map { " \($0): \(String(describing: $1))" }.joined(separator: "\n")
            self.logUpdate.send(result)
        } else if let claims = currentAccount?.accountClaims {
            let result = claims.map { " \($0): \($1)" }.joined(separator: "\n")
            self.logUpdate.send(result)
        }
    }
    
    /**
     
     Acquire a token for an existing account silently
     
     - forScopes:           Permissions you want included in the access token received
     in the result in the completionBlock. Not all scopes are
     guaranteed to be included in the access token returned.
     - account:             An account object that we retrieved from the application object before that the
     authentication flow will be locked down to.
     - completionBlock:     The completion block that will be called when the authentication
     flow completes, or encounters an error.
     */
    
    private func acquireTokenSilently(_ account: MSALAccount) {
        guard let applicationContext = applicationContext else { return }
        let parameters = MSALSilentTokenParameters(scopes: AuthConstants.scopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                let nsError = error as NSError
                // interactionRequired means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.
                
                if (nsError.domain == MSALErrorDomain) {
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                self.logUpdate.send( "Could not acquire token silently: \(error)")
                return
            }
            guard let result = result else {
                self.logUpdate.send("Could not acquire token silently: No result returned")
                return
            }
            self.logUpdate.send("Refreshed Access token is \(result.accessToken)")
            self.currentAccount = result.account
            self.signOutStatusChange.send(true)
            self.showTenantProfileClaims()
        }
    }
    
    func refreshDeviceMode() {
        if #available(iOS 13.0, *) {
            self.applicationContext?.getDeviceInformation(with: nil, completionBlock: {  [weak self]  (deviceInformation, error) in
                guard let self = self else { return }
                guard let deviceInfo = deviceInformation else {
                    return
                }
                self.currentDeviceMode = deviceInfo.deviceMode
            })
        }
    }
    
    func getDeviceMode() {
        guard #available(iOS 13.0, *) else {
            deviceModeMessage = "Running on older iOS. GetDeviceInformation API is unavailable."
            return
        }
        applicationContext?.getDeviceInformation(with: nil) { [weak self] (deviceInformation, error) in
            guard let self = self else { return }
            guard let deviceInfo = deviceInformation else {
                self.deviceModeMessage = "Device info not returned. Error: \(String(describing: error))"
                return
            }
            
            let isSharedDevice = deviceInfo.deviceMode == .shared
            let modeString = isSharedDevice ? "shared" : "private"
            self.deviceModeMessage = "Received device info. Device is in the \(modeString) mode."
        }
    }
    
    /**
     This action will invoke the remove account APIs to clear the token cache
     to sign out a user from this application.
     */
    func signOut() {
        /**
         Removes all tokens from the cache for this application for the provided account
         - account:    The account to remove from the cache
         */
        guard let applicationContext = applicationContext, let account = currentAccount else { return }
        let signoutParameters = MSALSignoutParameters(webviewParameters: self.webViewParameters!)
        
        // If testing with Microsoft's shared device mode, trigger signout from browser. More details here:
        // https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-ios-shared-devices
        
        if (self.currentDeviceMode == .shared) {
            signoutParameters.signoutFromBrowser = true
        } else {
            signoutParameters.signoutFromBrowser = false
        }
        applicationContext.signout(with: account, signoutParameters: signoutParameters, completionBlock: { [weak self] (success, error) in
            guard let self = self else { return }
            if let error = error {
                self.logUpdate.send("Couldn't sign out account with error: \(error)")
                return
            }
            
            self.logUpdate.send("Sign out completed successfully")
            self.currentAccount = nil
            self.accountUpdate.send(nil)
            self.signOutStatusChange.send(false)
        })
    }
    
}
