//
//  AuthViewModelFactory.swift
//  MSALiOS
//
//  Created by Hafiz Saad on 27/03/2025.
//  Copyright © 2025 Microsoft. All rights reserved.
//


import MSAL

class AuthViewModelFactory {
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
