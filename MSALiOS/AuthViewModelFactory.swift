//
//  AuthViewModelFactory.swift
//  MSALiOS
//
//  Created by Hafiz Saad on 27/03/2025.
//  Copyright © 2025 Microsoft. All rights reserved.
//


import MSAL

class AuthViewModelFactory {
    
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
    
    static func create(parentViewController: UIViewController) -> AuthViewModel? {
        do {
            guard let authorityURL = URL(string: AuthConstants.authority) else {
                print("Invalid authority URL")
                return nil
            }

            let authority = try MSALAADAuthority(url: authorityURL)
            let configuration = MSALPublicClientApplicationConfig(
                clientId: AuthConstants.clientID,
                redirectUri: AuthConstants.redirectUri,
                authority: authority
            )

            let applicationContext = try MSALPublicClientApplication(configuration: configuration)
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: parentViewController)

            return AuthViewModel(applicationContext: applicationContext, webViewParameters: webViewParameters)
        } catch {
            print("Failed to create MSAL instance: \(error)")
            return nil
        }
    }
}

//let authViewModel = AuthViewModelFactory.create(parentViewController: someVC)
//let authVC = AuthViewController(viewModel: authViewModel!)
