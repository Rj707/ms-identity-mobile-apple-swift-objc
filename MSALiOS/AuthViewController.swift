//
//  AuthViewController.swift
//  MSALiOS
//
//  Created by Hafiz Saad on 25/03/2025.
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit
import MSAL
import Combine

class AuthViewController: UIViewController {
    
    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var loggingText: UITextView!
    var signOutButton: UIButton!
    var callGraphButton: UIButton!
    var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupBindings()
        viewModel.initMSAL(parentViewController: self)
        viewModel.loadCurrentAccount()
        viewModel.refreshDeviceMode()
        platformViewDidLoadSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadCurrentAccount()
    }
    
    func platformViewDidLoadSetup() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appCameToForeGround(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func appCameToForeGround(notification: Notification) {
        viewModel.loadCurrentAccount()
    }
    
    private func setupBindings() {
        viewModel.onLogUpdate = { [weak self] text in
            self?.updateLogging(text: text)
        }
        
        viewModel.onAccountUpdate = { [weak self] account in
            self?.updateAccountLabel(account: account)
        }
        
        viewModel.onSignOutStatusChange = { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.signOutButton.isEnabled = isEnabled
            }
        }
        
        viewModel.$deviceModeMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message = message else { return }
                self?.updateLogging(text: message)
            }
            .store(in: &cancellables)
    }
    
    @objc func callGraphAPI(_ sender: UIButton) {
        viewModel.callGraphAPI()
    }
    
    @objc func signOut(_ sender: UIButton) {
        viewModel.signOut()
    }
    
    @objc func getDeviceMode(_ sender: UIButton) {
        viewModel.getDeviceMode()
    }
    
    func updateLogging(text: String) {
        DispatchQueue.main.async {
            self.loggingText.text = text
        }
    }
    
    func updateAccountLabel(account: MSALAccount?) {
        DispatchQueue.main.async {
            self.usernameLabel.text = account?.username ?? "Signed out"
        }
    }
    
    func initUI() {
        
        usernameLabel = UILabel()
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = ""
        usernameLabel.textColor = .darkGray
        usernameLabel.textAlignment = .right
        
        self.view.addSubview(usernameLabel)
        
        usernameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add call Graph button
        callGraphButton  = UIButton()
        callGraphButton.translatesAutoresizingMaskIntoConstraints = false
        callGraphButton.setTitle("Call Microsoft Graph API", for: .normal)
        callGraphButton.setTitleColor(.blue, for: .normal)
        callGraphButton.addTarget(self, action: #selector(callGraphAPI(_:)), for: .touchUpInside)
        self.view.addSubview(callGraphButton)
        
        callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120.0).isActive = true
        callGraphButton.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        callGraphButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add sign out button
        signOutButton = UIButton()
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.blue, for: .normal)
        signOutButton.setTitleColor(.gray, for: .disabled)
        signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
        self.view.addSubview(signOutButton)
        
        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        let deviceModeButton = UIButton()
        deviceModeButton.translatesAutoresizingMaskIntoConstraints = false
        deviceModeButton.setTitle("Get device info", for: .normal);
        deviceModeButton.setTitleColor(.blue, for: .normal);
        deviceModeButton.addTarget(self, action: #selector(getDeviceMode(_:)), for: .touchUpInside)
        self.view.addSubview(deviceModeButton)
        
        deviceModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        deviceModeButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0).isActive = true
        deviceModeButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        deviceModeButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add logging textfield
        loggingText = UITextView()
        loggingText.isUserInteractionEnabled = false
        loggingText.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(loggingText)
        
        loggingText.topAnchor.constraint(equalTo: deviceModeButton.bottomAnchor, constant: 10.0).isActive = true
        loggingText.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0).isActive = true
        loggingText.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10.0).isActive = true
        loggingText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10.0).isActive = true
    }
}


