//
//  ViewController.swift
//  FirebaseDemo
//
//

import UIKit
import Firebase
import CoreBluetooth
import Foundation
import Darwin

class AddNewKetoneLevelViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ketoneLevelLabel: UILabel!
    var centralManager: CBCentralManager!
    var breathalyzer: CBPeripheral?
    var ketoneCharacteristic: CBCharacteristic?
    var scanning = false
    let timerScanInterval:TimeInterval = 2.0
    let timerPauseInterval:TimeInterval = 10.0
    let breathalyzerName = "SH-HC-08"
    var numbers = [Double]()
    let delay = 5.0
    var queueFlag = true
    var semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    let sensorResistance: Double = 10000
    let r0:Double = 4105
    
    @IBAction func cancelAdd(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var showMessage = true
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        case .unknown:
            message = "The state of the BLE Manager is unknown."
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        case .poweredOn:
            showMessage = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            print(message)
            ketoneLevelLabel.text = message
            ketoneLevelLabel.adjustsFontSizeToFitWidth = true
            scanning = true
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            if breathalyzer == nil {
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            } else {
                breathalyzer!.delegate = self
                centralManager.connect(breathalyzer!, options: nil)
                print("breathalyzer found, connecting")
                ketoneLevelLabel.text = "breathalyzer found, connecting"
                ketoneLevelLabel.adjustsFontSizeToFitWidth = true
            }
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
            
        }
        
        if showMessage {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the background gradient
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        semaphore = DispatchSemaphore(value: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    @objc func pauseScan() {
        print("pausing scan...")
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
    }
    
    @objc func resumeScan() {
        if scanning {
            print("resuming scan")
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == breathalyzerName {
                print("breathalyzer found, connecting")
                ketoneLevelLabel.text = "breathalyzer found, connecting"
                ketoneLevelLabel.adjustsFontSizeToFitWidth = true
                // to save power, stop scanning for other devices
                scanning = false
                
                // save a reference to the sensor tag
                breathalyzer = peripheral
                breathalyzer!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(breathalyzer!, options: nil)
            }
        }
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("successfully connected to the peripheral!")
        
        ketoneLevelLabel.text = "Connected"
        ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = "Please breathe out for \(delay) seconds"
        titleLabel.adjustsFontSizeToFitWidth = true
        
        // Now that we've successfully connected to the breathalyzer, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connection to breathalyzer failed")
        ketoneLevelLabel.text = "Fail to connect"
        ketoneLevelLabel.adjustsFontSizeToFitWidth = true
    }
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from breathalyzer")
        ketoneLevelLabel.text = "Disconnected"
        ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        if error != nil {
            print("disconnection details: \(error!.localizedDescription)")
        }
        breathalyzer = nil
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("error discovering services: \(error?.localizedDescription)")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service) \(service.uuid)")
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
                if ( service.uuid == CBUUID(string: "FFE0"))
                {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     
     If the characteristics of the specified service are successfully discovered, you can access
     them through the service's characteristics property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("error discovering characteristics: \(error?.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            //var enableValue:UInt8 = 1
            //let enableBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))
            
            for characteristic in characteristics {
                //Voltage Data Characteristic
                if characteristic.uuid == CBUUID(string: "FFE1") {
                    //Enable the IR Temperature Sensor notifications
                    ketoneLevelLabel.text = "Found Ketone Characteristic"
                    ketoneLevelLabel.adjustsFontSizeToFitWidth = true
                    ketoneCharacteristic = characteristic
                    let alertController = UIAlertController(title: "Press Yes to Continue Reading", message: "Press 'Yes' to begin reading, or press 'No' to return", preferredStyle: .alert)
                    let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { (alert) in
                        self.breathalyzer?.setNotifyValue(true, for: characteristic)
                    })
                    let noAction = UIAlertAction(title: "No", style: .cancel, handler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    })
                    alertController.addAction(yesAction)
                    alertController.addAction(noAction)
                    self.present(alertController, animated: true, completion: nil)
                    //self.breathalyzer?.setNotifyValue(true, for: characteristic)
                    break
                }
            }
        }
    }
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error on updating value of characteristic: \(characteristic) - \(error?.localizedDescription)")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            updateDisplay(dataBytes)
//            if characteristic.UUID == CBUUID(string: Device.TemperatureDataUUID) {
//                displayTemperature(dataBytes)
//            } else if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID) {
//                displayHumidity(dataBytes)
//            }
        }
    }

    func updateDisplay(_ data: Data) {
//        let value = data.withUnsafeBytes { (ptr: UnsafePointer<Double>) -> Double in
//            return ptr.pointee
//        }
//        var newValue = value
//        for i in 0...317 {
//            newValue = newValue * 10
//        }
        var value: Int = 0
        if let dataString = String(data: data, encoding: .utf8) {
            value = Int(dataString.trimmingCharacters(in: .whitespacesAndNewlines))!
            print("Data: \(dataString)")
        }
        let rS = (Double(5 - (Double(value) * 0.0048)) / Double(Double(value) * 0.0048)) * sensorResistance
        let logValue = ((log10(rS/r0) * -2.6) + 2.7)
        let newValue = pow(10, logValue)
        let ppmInMMOL = (newValue / 1000.0) / 58.08
        let scaledPPMInMMOL = ppmInMMOL * 1000.0
        print("Value: \(value)")
        print("Log Value: \(logValue)")
        print("New Value: \(newValue)")
        ketoneLevelLabel.text = "Ketone Level: \(scaledPPMInMMOL)"
        ketoneLevelLabel.adjustsFontSizeToFitWidth = true
        let ref = Database.database().reference().child("users")
        let childRef = ref.child((Auth.auth().currentUser?.uid)!)
        let dataRef = childRef.child("data")
        //var dataBlock = [Double]()
        //here is the for loop
        var i = 0
        var handle: DatabaseHandle?
//        if (newValue > 200000) {
//            return
//        }
        if (value == 0) {
            return
        }
        semaphore.wait()
        if (queueFlag) {
            queueFlag = false
            handle = dataRef.observe(.value, with: { (snapshot) in
                if let values = snapshot.value  {
                    let castedArray = values as? [Double]
                    if castedArray != nil {
                        //print(castedArray!)
                        for level in castedArray! {
                            //dataBlock.append(level)
                            //print(level)
                            //print(i)
                            i += 1
                            self.numbers.append(level)
                        }
                    }
                }
            })
            for second in 0..<Int(delay) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(second), execute: {
                    self.titleLabel.text = "Please breathe out for \(Int(self.delay) - second) seconds"
                    self.titleLabel.adjustsFontSizeToFitWidth = true
                })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                print (self.numbers)
                self.numbers.append(Double(scaledPPMInMMOL))
                dataRef.setValue(self.numbers)
                self.numbers = []
                self.centralManager.cancelPeripheralConnection(self.breathalyzer!)
                self.dismiss(animated: true, completion: nil)
            })
            semaphore.signal()
        } else {
            semaphore.signal()
            return
        }
        //self.dismiss(animated: true, completion: nil)
    }
    
}

