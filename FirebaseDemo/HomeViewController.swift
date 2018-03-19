//
//  HomeViewController.swift
//  FirebaseDemo
//
//  Created by Param Nayar on 11/2/17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreBluetooth
import Charts

class HomeViewController:UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate   {
    
    var centralManager: CBCentralManager!
    var timer = Timer()
    let BLEService_UUID = CBUUID(string: "09fc6363-0292-447a-9757-0210f9a728ed")
    let BLECharacteristic_UUID_RX = CBUUID(string: "09fc6364-0292-447a-9757-0210f9a728ed")
    let BLECharacteristic_UUID_TX = CBUUID(string: "09fc6365-0292-447a-9757-0210f9a728ed")
    var peripherals: [CBPeripheral] = []
    var RSSIs = [NSNumber]()
    var blePeripheral: CBPeripheral?
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    var data = NSMutableData()
    var characteristicASCIIValue = NSString()
    
    @IBOutlet weak var txtTextBox: UITextField!
    @IBOutlet weak var chtChart: LineChartView!
    
    var numbers : [Double] = [] //This is where we are going to store all the numbers. This can be a set of numbers that come from a Realm database, Core data, External API's or where ever else
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //centralManager = CBCentralManager(delegate: self, queue: nil)
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        //updateGraph()
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        
        
        //here is the for loop
        var i = 0
        var handle: DatabaseHandle?
        handle = dataRef.observe(.value, with: { (snapshot) in
            if let values = snapshot.value  {
                let castedArray = values as! [Double]
                print(castedArray)
                self.numbers = []
                for level in castedArray {
                    self.numbers.append(level)
                    print(level)
                    print(i)
                    i += 1
                }
            }
        })
        //updateGraph()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        
        
        //here is the for loop
        var i = 0
        var handle: DatabaseHandle?
        handle = dataRef.observe(.value, with: { (snapshot) in
            if let values = snapshot.value  {
                let castedArray = values as! [Double]
                print(castedArray)
                self.numbers = []
                for level in castedArray {
                    self.numbers.append(level)
                    print(level)
                    print(i)
                    i += 1
                }
            }
        })
        updateGraph()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func handleLogout(_ sender: UIButton) {
        try! Auth.auth().signOut()
        self.performSegue(withIdentifier: "backToHomePortal", sender: self)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("Bluetooth powered on and enabled")
            startScan()
        } else {
            print("Bluetooth disabled, please turn on")
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction) -> Void in self.dismiss(animated: true, completion: nil)})
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    func startScan() {
        print("Scanning")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //centralManager?.stopScan()
        self.peripherals.append(peripheral)
        self.RSSIs.append(RSSI)
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
        if blePeripheral == nil {
            print("We found a new pheripheral devices with services")
            print("Peripheral name: \(peripheral.name)")
            print("**********************************")
            print ("Advertisement Data : \(advertisementData)")
            blePeripheral = peripheral
        }
    }
    
    func connectToDevice() {
        centralManager?.connect(blePeripheral!, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(blePeripheral)")
        
        centralManager?.stopScan()
        print("Scan stopped")
        data.length = 0
        
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
        
    }
    
    @objc func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("Error discovering services: \(error!.localizedDescription)")
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics")
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BLECharacteristic_UUID_RX) {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLECharacteristic_UUID_TX) {
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func disconnectFromDevice() {
        if blePeripheral != nil {
            centralManager?.cancelPeripheralConnection(blePeripheral!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                characteristicASCIIValue = ASCIIstring
                print("Value received: \(characteristicASCIIValue as String)")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            }
        }
    }
    
    @IBAction func btnButton(_ sender: Any) {
        //let input  = Double(txtTextBox.text!) //gets input from the textbox - expects input as double/int
        //numbers.append(input!) //here we add the data to the array.
        updateGraph()
    }
    
    func updateGraph(){
        var lineChartEntry  = [ChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        
        for i in 0..<numbers.count {
            let value = ChartDataEntry(x: Double(i), y: numbers[i]) // here we set the X and Y status in a data chart entry
            lineChartEntry.append(value) // here we add it to the data set
        }
        
        let line1 = LineChartDataSet(values: lineChartEntry, label: "Number") //Here we convert lineChartEntry to a LineChartDataSet
        line1.colors = [NSUIColor.yellow] //Sets the colour to blue
        
        let data = LineChartData() //This is the object that will be added to the chart
        data.addDataSet(line1) //Adds the line to the dataSet
        
        
        chtChart.data = data //finally - it adds the chart data to the chart and causes an update
        chtChart.chartDescription?.text = "My awesome chart" // Here we set the description for the graph
    }

    
    
    
}
