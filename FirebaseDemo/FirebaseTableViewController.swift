//
//  FirebaseTableViewController.swift
//  FirebaseDemo
//
//  Created by Jett Anderson on 4/18/18.
//  Copyright © 2018 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FirebaseTableViewController: UIViewController, UITableViewDataSource {
    
    var times: [Double] = []
    var numbers: [Double] = []
    var dataHandler: DatabaseHandle?
    
    @IBAction func exitToHome(_ sender: UIButton) {
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        dataRef.removeObserver(withHandle: dataHandler!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        //dataRef.setValue(numbers)
        //here is the for loop
        var i = 0
        dataHandler = dataRef.observe(.value, with: { (snapshot) in
            if let values = snapshot.value  {
                
                let castedArray = values as? [String:Double]
                if castedArray != nil {
                    //print(castedArray!)
                    //self.numbers = [:]
                    self.times = []
                    self.numbers = []
                    for level in castedArray! {
                        let time = level.key.replacingOccurrences(of: ",", with: ".")
                        self.times.append(Double(time)!)
                        self.numbers.append(Double(level.value))
                        //self.numbers[time] = level.value
                        //print(level)
                        //print(i)
                        i += 1
                    }
                }
                
            }
        })
        print("Times in Table Load: \(times)")
        print("Numbers in Table Load: \(numbers)")
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        //dataRef.setValue(numbers)
        //here is the for loop
        var i = 0
        dataHandler = dataRef.observe(.value, with: { (snapshot) in
            if let values = snapshot.value  {
                
                let castedArray = values as? [String:Double]
                if castedArray != nil {
                    //print(castedArray!)
                    //self.numbers = [:]
                    self.times = []
                    self.numbers = []
                    for level in castedArray! {
                        let time = level.key.replacingOccurrences(of: ",", with: ".")
                        self.times.append(Double(time)!)
                        self.numbers.append(Double(level.value))
                        //self.numbers[time] = level.value
                        //print(level)
                        //print(i)
                        i += 1
                    }
                }
                
            }
        })
        print("Times in Table Appear: \(times)")
        print("Numbers in Table Appear: \(numbers)")
        sortArrays()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return times.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ketone Reading \(section)"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelCellReuse")!
        let deconvertedTime = deconvertTime(times[indexPath.section + indexPath.row])
        cell.textLabel?.text = "\(deconvertedTime)\tValue: \(numbers[indexPath.section + indexPath.row])"
        return cell
    }
    
    func sortArrays() -> Void {
        let combined = zip(times, numbers).sorted(by: {$0.0 < $1.0})
        times = combined.map({$0.0})
        numbers = combined.map({$0.1})
    }
    
    func deconvertTime(_ time: Double) -> String {
        var deconvertedTime: String = ""
        // Time is MMDD.HHMMSS or MDD.HHMMSS
        let month = Int(time) / 100
        let day = Int(time) % 100
        let hour = Int(time * 100.0) % 100
        let minute = Int(time * 10000.0) % 100
        let second = Int(time * 1000000.0) % 100
        if month < 10 {
            deconvertedTime = deconvertedTime + "0\(month)"
        } else {
            deconvertedTime = deconvertedTime + "\(month)"
        }
        deconvertedTime = deconvertedTime + "-\(day) "
        if hour < 10 {
            deconvertedTime = deconvertedTime + "0\(hour)"
        } else {
            deconvertedTime = deconvertedTime + "\(hour)"
        }
        if minute < 10 {
            deconvertedTime = deconvertedTime + ":0\(minute)"
        } else {
            deconvertedTime = deconvertedTime + ":\(minute)"
        }
        if second < 10 {
            deconvertedTime = deconvertedTime + ":0\(second)"
        } else {
            deconvertedTime = deconvertedTime + ":\(second)"
        }
        return deconvertedTime
    }
}
