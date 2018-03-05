//
//  LoginViewController.swift
//  CloudFunctions
//
//

import Foundation
import UIKit
import Firebase

class LoginViewController:UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var dismissButton: UIButton!
    
    var continueButton:RoundedWhiteButton!
    var activityView:UIActivityIndicatorView!
    var errorLabel:UILabel = UILabel()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        
        continueButton = RoundedWhiteButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        continueButton.setTitleColor(secondaryColor, for: .normal)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.bold)
        continueButton.center = CGPoint(x: view.center.x, y: view.frame.height - continueButton.frame.height - 24)
        continueButton.highlightedColor = UIColor(white: 1.0, alpha: 1.0)
        continueButton.defaultColor = UIColor.white
        continueButton.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
        continueButton.alpha = 0.5
        view.addSubview(continueButton)
        setContinueButton(enabled: false)
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.color = secondaryColor
        activityView.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        
        view.addSubview(activityView)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailField.becomeFirstResponder()
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    @IBAction func handleDismissButton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    /**
     Adjusts the center of the **continueButton** above the keyboard.
     - Parameter notification: Contains the keyboardFrame info.
     */
    
    @objc func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        continueButton.center = CGPoint(x: view.center.x,
                                        y: view.frame.height - keyboardFrame.height - 16.0 - continueButton.frame.height / 2)
        activityView.center = continueButton.center
    }
    
    /**
     Enables the continue button if the **username**, **email**, and **password** fields are all non-empty.
     
     - Parameter target: The targeted **UITextField**.
     */
    
    @objc func textFieldChanged(_ target:UITextField) {
        let email = emailField.text
        let password = passwordField.text
        let formFilled = email != nil && email != "" && password != nil && password != ""
        setContinueButton(enabled: formFilled)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Resigns the target textField and assigns the next textField in the form.
        
        switch textField {
        case emailField:
            emailField.resignFirstResponder()
            passwordField.becomeFirstResponder()
            break
        case passwordField:
            handleSignIn()
            break
        default:
            break
        }
        return true
    }
    
    /**
     Enables or Disables the **continueButton**.
     */
    
    func setContinueButton(enabled:Bool) {
        if enabled {
            continueButton.alpha = 1.0
            continueButton.isEnabled = true
        } else {
            continueButton.alpha = 0.5
            continueButton.isEnabled = false
        }
    }
    
    @objc func handleSignIn() {
        guard let email = emailField.text else { return }
        guard let pass = passwordField.text else { return }
        
        setContinueButton(enabled: false)
        continueButton.setTitle("", for: .normal)
        activityView.startAnimating()
        
        Auth.auth().signIn(withEmail: email, password: pass)    { user, error in
            if error == nil && user != nil {
                self.dismiss(animated: false, completion: nil)
            } else {
                if error?.localizedDescription == "The password is invalid or the user does not have a password." {
                    self.errorLabel.removeFromSuperview()
                    self.errorLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 100))
                    self.errorLabel.text = "The password is invalid."
                    self.errorLabel.textColor = UIColor.yellow
                    self.errorLabel.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - self.errorLabel.frame.height - 200)
                    self.errorLabel.adjustsFontSizeToFitWidth = true
                    self.errorLabel.textAlignment = NSTextAlignment.center
                    self.emailField.text = ""
                    self.passwordField.text = ""
                    self.view.addSubview(self.errorLabel)
                } else if error?.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted." {
                    self.errorLabel.removeFromSuperview()
                    self.errorLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 100))
                    self.errorLabel.text = "There is no user record corresponding to this identifier."
                    self.errorLabel.textColor = UIColor.yellow
                    self.errorLabel.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - self.errorLabel.frame.height - 200)
                    self.errorLabel.adjustsFontSizeToFitWidth = true
                    self.errorLabel.textAlignment = NSTextAlignment.center
                    self.emailField.text = ""
                    self.passwordField.text = ""
                    self.view.addSubview(self.errorLabel)
                } else if error?.localizedDescription == "The email address is badly formatted." {
                    self.errorLabel.removeFromSuperview()
                    self.errorLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
                    self.errorLabel.text = "The email address is badly formatted."
                    self.errorLabel.textColor = UIColor.yellow
                    self.errorLabel.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - self.errorLabel.frame.height - 200)
                    self.errorLabel.adjustsFontSizeToFitWidth = true
                    self.errorLabel.textAlignment = NSTextAlignment.center
                    self.emailField.text = ""
                    self.passwordField.text = ""
                    self.view.addSubview(self.errorLabel)
                }
                print("Error logging in: \(error?.localizedDescription)")
                self.continueButton.setTitle("Continue", for: .normal)
            }
        }
    }
}
