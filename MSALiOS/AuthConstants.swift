//
//  AuthConstants.swift
//  MSALiOS
//
//  Created by Hafiz Saad on 27/03/2025.
//  Copyright © 2025 Microsoft. All rights reserved.
//

enum AuthConstants {
    static let clientID = "5e4e4817-67f8-4e91-9cf2-3b13a8e86761"
    static let graphEndpoint = "https://graph.microsoft.com/v1.0/me/"
    static let authority = "https://login.microsoftonline.com/443fdb4d-77c8-482a-961a-4c2fee164ef5"
    static let redirectUri = "msauth.com.microsoft.identitysample.MSALiOS://auth"
    static let scopes = ["api://5e4e4817-67f8-4e91-9cf2-3b13a8e86761/NX.User.Read"]
}
