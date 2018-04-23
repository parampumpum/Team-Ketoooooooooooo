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
    var cells: [UITableViewCell] = []
    var numCells = 13
    
    @IBAction func exitToHome(_ sender: UIButton) {
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        dataRef.removeObserver(withHandle: dataHandler!)
        times = []
        numbers = []
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
        tableView.register(FirebaseTableViewCell.self, forCellReuseIdentifier: "labelCellReuse")
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
        sortArrays()
        print("Times in Table Appear: \(times)")
        print("Numbers in Table Appear: \(numbers)")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return times.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return "Ketone Reading \(section)"
        if let name = Auth.auth().currentUser?.displayName! {
            return "Ketone Readings for \(name)"
        } else {
            return "Ketone Readings"
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        sortArrays()
        //print("Numbers 0: \(numbers)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelCellReuse", for: indexPath)
        let deconvertedTime = deconvertTime(times[indexPath.section + indexPath.row])
        //print("Numbers 1: \(numbers)")
        cell.textLabel?.text = "\(deconvertedTime)\tValue: \(numbers[indexPath.section + indexPath.row])"
        //print("Numbers 2: \(numbers)")
        print("Grabbing cell: \(indexPath.section) \(indexPath.row) \(numbers[indexPath.row])")
        //print("Numbers 3: \(numbers)")
        //print(numbers)
        //print("Numbers 4: \(numbers)")
        return cell
    }
    
    func sortArrays() -> Void {
        let combined = zip(times, numbers).sorted(by: {$0.0 < $1.0})
        times = combined.map({$0.0})
        numbers = combined.map({$0.1})
        //print("Sort called")
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
