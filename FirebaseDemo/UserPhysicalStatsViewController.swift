//
//  UserPhysicalStatsViewController.swift
//  FirebaseDemo
//
//  Created by Jett Anderson on 2/28/18.
//  Copyright © 2018 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

class UserPhysicalStatsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var heightField: UITextField!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var ageField: UITextField!
    
    var continueButton:RoundedWhiteButton!
    var activityView:UIActivityIndicatorView!
    
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
        continueButton.addTarget(self, action: #selector(registerPhysicalStats), for: .touchUpInside)
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
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
    
    @objc func keyboardWillAppear(notification: NSNotification) {
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        continueButton.center = CGPoint(x: view.center.x, y: view.frame.height - keyboardFrame.height - 16.0 - continueButton.frame.height / 2)
        activityView.center = continueButton.center
    }
    
    /**
     Enables the continue button if the **height**, **weight**, and **age** fields are all non-empty.
     
     - Parameter target: The targeted **UITextField**.
     */
    
    @objc func textFieldChanged(_ target:UITextField) {
        let height = heightField.text
        let weight = weightField.text
        let age = ageField.text
        let formFilled = height != nil && height != "" && weight != nil && weight != "" && age != nil && age != ""
        if formFilled {
            let unwrappedHeight = height!
            let unwrappedWeight = weight!
            let unwrappedAge = age!
            let formComplete = (unwrappedHeight.matches("[0-9].[0-9]{1,2}") || unwrappedHeight.matches("[0-9]'")) && unwrappedWeight.matches("[0-9]+") && unwrappedAge.matches("[0-9]+")
            setContinueButton(enabled: formComplete)
        } else {
            setContinueButton(enabled: formFilled)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Resigns the target textField and assigns the next textField in the form.
        
        switch textField {
        case heightField:
            heightField.resignFirstResponder()
            weightField.becomeFirstResponder()
            break
        case weightField:
            weightField.resignFirstResponder()
            ageField.becomeFirstResponder()
            break
        case ageField:
            registerPhysicalStats()
            break
        default:
            break
        }
        return true
    }
    
    /**
     Enables or Disables the **continueButton**
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
    
    @objc func registerPhysicalStats() {
        guard let heightString = heightField.text else { return }
        guard let weightString = weightField.text else { return }
        guard let ageString = ageField.text else { return }
        
        let height = heightString.matches("[0-9].[0-9]{1,2}") ? heightString : nil
        let weight = weightString.matches("[0-9]+") ? Int(weightString) : nil
        let age = ageString.matches("[0-9]+") ? Int(ageString) : nil
        
        setContinueButton(enabled: false)
        continueButton.setTitle("", for: .normal)
        activityView.startAnimating()
        
        if height == nil || weight == nil || age == nil {
            print("Error, could not parse height, weight, or age")
            self.dismiss(animated: false, completion: nil)
        }
        
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let statsRef = childRef.child("stats")
        let dataRef = childRef.child("data")
        let statBlock = ["height": height! as String, "weight": String(weight!), "age": String(age!)]
        //let dataBlock = ["0": 32.4, "1": 35.6, "2": 3.4]
        let dict = ["0": 2.4, "1": 3.6, "2": 1.2]
        statsRef.setValue(statBlock)
        dataRef.setValue(dict)
        self.performSegue(withIdentifier: "statsToMain", sender: self)
    }
}
