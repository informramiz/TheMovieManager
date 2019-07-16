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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        TMDBClient.getRequestToken { (success, error) in
            guard success else {
                let errorMessage = error?.localizedDescription ?? ""
                self.showErrorAlertOnMain(message: errorMessage)
                return
            }
            
            print("Token created successfully: \(TMDBClient.Auth.requestToken)")
            DispatchQueue.main.async {
                self.login()
            }
        }
    }
    
    private func login() {
        let username = emailTextField.text!
        let password = passwordTextField.text!
        TMDBClient.login(username: username, password: password) { (success, error) in
            guard success else {
                self.showErrorAlertOnMain(message: error?.localizedDescription ?? "Login failed due to unknown error")
                return
            }
            
            print("Token verified with username+password: \(TMDBClient.Auth.requestToken)")
            self.createSessionId()
        }
    }
    
    private func createSessionId() {
        TMDBClient.createSessionId { (success, error) in
            guard success else {
                self.showErrorAlertOnMain(message: error?.localizedDescription ?? "Login Failed due to unknown error")
                return
            }
            
            print("Successfully created session id: \(TMDBClient.Endpoints.createSessionId)")
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
            }
        }
    }
    
    @IBAction func loginViaWebsiteTapped() {
        performSegue(withIdentifier: "completeLogin", sender: nil)
    }
    
}
