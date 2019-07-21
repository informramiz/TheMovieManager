//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Updated by Ramiz Raja on 14/07/19
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        loggingIn(true)
        getRequestToken {
            self.login()
        }
    }
    
    @IBAction func loginViaWebsiteTapped() {
        loggingIn(true)
        getRequestToken {
            print("OAuth url" + TMDBClient.Endpoints.webAuth.url.absoluteString)
            UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
        }
    }
    
    private func getRequestToken(successHandler: @escaping () -> Void) {
        TMDBClient.getRequestToken { (success, error) in
            guard success else {
                let errorMessage = error?.localizedDescription ?? ""
                self.showErrorAlert(message: errorMessage)
                self.loggingIn(false)
                return
            }
            
            print("Token created successfully: \(TMDBClient.Auth.requestToken)")
            successHandler()
        }
    }
    
    private func login() {
        let username = emailTextField.text!
        let password = passwordTextField.text!
        TMDBClient.login(username: username, password: password) { (success, error) in
            guard success else {
                self.showErrorAlert(message: error?.localizedDescription ?? "Login failed due to unknown error")
                self.loggingIn(false)
                return
            }
            
            print("Token verified with username+password: \(TMDBClient.Auth.requestToken)")
            self.createSessionId()
        }
    }
    
    func createSessionId() {
        TMDBClient.createSessionId { (success, error) in
            self.loggingIn(false)
            guard success else {
                self.showErrorAlert(message: error?.localizedDescription ?? "Login Failed due to unknown error")
                return
            }
            
            print("Successfully created session id: \(TMDBClient.Auth.sessionId)")
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }
    }
    
    func loggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn
    }
}
