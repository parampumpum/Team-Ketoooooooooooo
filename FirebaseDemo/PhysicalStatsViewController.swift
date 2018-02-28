//
//  PhysicalStatsViewController.swift
//  FirebaseDemo
//
//  Created by Jett Anderson on 2/26/18.
//  Copyright © 2018 Robert Canton. All rights reserved.
//

//
//  SignUpViewController.swift
//  CloudFunctions
//
//

import Foundation
import UIKit
import Firebase

class PhysicalStatsViewController:UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var heightField: UITextField!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var ageField: UITextField!
    
    var continueButton:RoundedWhiteButton!
    var activityView:UIActivityIndicatorView!
    
    @IBAction func handleDismiss(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
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
        continueButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        view.addSubview(continueButton)
        setContinueButton(enabled: false)
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.color = secondaryColor
        activityView.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        
        view.addSubview(activityView)
        
        heightField.delegate = self
        weightField.delegate = self
        ageField.delegate = self
        
        heightField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        weightField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        ageField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightField.becomeFirstResponder()
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        heightField.resignFirstResponder()
        weightField.resignFirstResponder()
        ageField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
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
        let height = heightField.text
        let weight = weightField.text
        let age = ageField.text
        let formFilled = height != nil && height != "" && weight != nil && weight != "" && age != nil && age != "" && (false)
        setContinueButton(enabled: formFilled)
    }
    
}

