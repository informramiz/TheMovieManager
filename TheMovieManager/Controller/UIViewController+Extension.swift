//
//  UIViewController+Extension.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Updated by Ramiz Raja on 14/07/19
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

extension UIViewController {
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func showErrorAlert(message: String) {
        let alertController = UIAlertController()
        alertController.message = message
        
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showErrorAlertOnMain(message: String) {
        DispatchQueue.main.async {
            self.showErrorAlert(message: message)
        }
    }
}
