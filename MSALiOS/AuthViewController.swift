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
    
    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private var loggingText: UITextView!
    private var signOutButton: UIButton!
    private var callGraphButton: UIButton!
    private var usernameLabel: UILabel!
    
    /// Initializes the view controller programmatically with a default or injected ViewModel.
    init(viewModel: AuthViewModel = AuthViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    /// Initializes the view controller when loaded from a storyboard or XIB.
    required init?(coder: NSCoder) {
        self.viewModel = AuthViewModel()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.initMSAL(parentViewController: self)
        viewModel.loadCurrentAccount()
        viewModel.refreshDeviceMode()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadCurrentAccount()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        setupUsernameLabel()
        setupButtons()
        setupLoggingTextView()
    }
    
    private func setupUsernameLabel() {
        usernameLabel = UILabel()
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = ""
        usernameLabel.textColor = .darkGray
        usernameLabel.textAlignment = .right
        
        view.addSubview(usernameLabel)
        
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0),
            usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0),
            usernameLabel.widthAnchor.constraint(equalToConstant: 300.0),
            usernameLabel.heightAnchor.constraint(equalToConstant: 50.0)
        ])
    }
    
    private func setupButtons() {
        callGraphButton = createButton(title: "Sign In & Get Claims", action: #selector(callGraphAPI))
        signOutButton = createButton(title: "Sign Out", action: #selector(signOut))
        signOutButton.setTitleColor(.gray, for: .disabled)
        let deviceModeButton = createButton(title: "Get device info", action: #selector(getDeviceMode))
        
        view.addSubview(callGraphButton)
        view.addSubview(signOutButton)
        view.addSubview(deviceModeButton)
        
        NSLayoutConstraint.activate([
            callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120.0),
            callGraphButton.widthAnchor.constraint(equalToConstant: 300.0),
            callGraphButton.heightAnchor.constraint(equalToConstant: 50.0),
            
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0),
            signOutButton.widthAnchor.constraint(equalToConstant: 150.0),
            signOutButton.heightAnchor.constraint(equalToConstant: 50.0),
            
            deviceModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deviceModeButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0),
            deviceModeButton.widthAnchor.constraint(equalToConstant: 150.0),
            deviceModeButton.heightAnchor.constraint(equalToConstant: 50.0)
        ])
    }
    
    private func setupLoggingTextView() {
        loggingText = UITextView()
        loggingText.isUserInteractionEnabled = false
        loggingText.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(loggingText)
        
        NSLayoutConstraint.activate([
            loggingText.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 50.0),
            loggingText.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10.0),
            loggingText.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0),
            loggingText.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10.0)
        ])
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        viewModel.logUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.updateLogging(text: message)
            }
            .store(in: &cancellables)
        
        viewModel.accountUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.updateAccountLabel(account: account)
            }
            .store(in: &cancellables)
        
        viewModel.signOutStatusChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.signOutButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)
        
        viewModel.$deviceModeMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message = message else { return }
                self?.updateLogging(text: message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func callGraphAPI() {
        viewModel.callGraphAPI()
    }
    
    @objc private func signOut() {
        viewModel.signOut()
    }
    
    @objc private func getDeviceMode() {
        viewModel.getDeviceMode()
    }
    
    // MARK: - UI Updates
    
    private func updateLogging(text: String) {
        DispatchQueue.main.async {
            self.loggingText.text = text
        }
    }
    
    private func updateAccountLabel(account: MSALAccount?) {
        DispatchQueue.main.async {
            self.usernameLabel.text = account?.username ?? "Signed out"
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appCameToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appCameToForeground() {
        viewModel.loadCurrentAccount()
    }
}
