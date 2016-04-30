//
//  LoginViewController.swift
//  TouchMobile
//
//  Created by ican on 4/25/16.
//  Copyright © 2016 ThemBoyz. All rights reserved.
//

import Foundation
import UIKit
import Parse

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var mainViewController:ViewController?

    @IBAction func tappedLoginBtn(sender: AnyObject) {
        
        if (usernameTextField.text == nil || usernameTextField.text == nil) {
            let myAlert = UIAlertController(title: "Problem with Login", message: "You need to enter username and password.", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            myAlert.addAction(okAction)
            self.presentViewController(myAlert, animated: true, completion: nil)
            return
        }

        PFUser.logInWithUsernameInBackground(usernameTextField.text!, password:passwordTextField.text!) {
            (user: PFUser?, error: NSError?) -> Void in
            if user != nil {
                self.mainViewController!.retrieveAllNodes()
                self.dismissViewControllerAnimated(true, completion: nil)
                
            } else {
                let myAlert = UIAlertController(title: "Problem with Login", message: "Invalid Credentials", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                myAlert.addAction(okAction)
                self.presentViewController(myAlert, animated: true, completion: nil)
            }
        }

    }
    
}