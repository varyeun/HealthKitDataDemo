//
//  ViewController.swift
//  HealthKitDataDemo
//
//  Created by ADUP on 2020/07/22.
//  Copyright © 2020 ADUP. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation
import CoreMotion

let healthKitStore: HKHealthStore = HKHealthStore()

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var lblBloodgroup: UILabel!
    @IBOutlet weak var lblAge: UILabel!
    @IBOutlet weak var lblWeight: UILabel!
    @IBOutlet weak var lblHeart: UILabel!
    
    let value: String = "your ip:port"

    let uid: String = String(describing:UIDevice.current.identifierForVendor!)
    
    var locationManager: CLLocationManager!
    let motionManager = CMMotionManager()
    var timer: Timer!
    let corey = CMAltimeter()
    let dateFormatter = DateFormatter()
    
    var formData = [String: Any]()
    var gyroInserted: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        print(uid)
        formData["uid"] = uid
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        self.getPressure()
     
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: false)
        //repeats: true로 하면 계속해서 측정됨. 지금은 샘플 임의상 false로 구현
        
    }
    
    @objc func getPressure() {
        corey.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
            self.corey.stopRelativeAltitudeUpdates()
            print("pressure 기압 : \(altitudeData!.pressure), \(self.dateFormatter.string(from: Date()))")
               //kPa (킬로파스칼 단위)
        })
    }
    
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData {
            print("accelerometer 가속도 : x \(accelerometerData.acceleration.x), y \(accelerometerData.acceleration.y), z \(accelerometerData.acceleration.z), \(self.dateFormatter.string(from: Date()))")
        }
        if let gyroData = motionManager.gyroData {
            print("gyro 자이로 : x \(gyroData.rotationRate.x), y \(gyroData.rotationRate.y), z \(gyroData.rotationRate.z), \(self.dateFormatter.string(from: Date()))")
            
            self.formData["gyro"] = """
            {"x":"\(gyroData.rotationRate.x)","y":"\(gyroData.rotationRate.y)","z":"\(gyroData.rotationRate.z)"}
            """
        }
    }
    
    //CMAltitudeDate에서 받아오는 고도 데이터는 change in altitude (in meters)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        let altitude = currentLocation.altitude
        locationManager.stopUpdatingLocation()
        print("altitude 고도 : \(altitude), \(self.dateFormatter.string(from: Date()))") //in meters
    }
    
    @IBAction func authrizeKitclicked(_ sender: Any){
        self.authorizeHealthKitApp()
    }
    
    @IBAction func getDetails(_ sender: Any){
        let (age, bloodtype) = self.readProfile()
        self.lblAge.text = "\(String(describing: age!))"
        self.lblBloodgroup.text = self.getReadablebloodType(bloodType: bloodtype?.bloodType)
        self.readMostRecentSample()
        self.getTodaysSteps(completion: { (step, now) in
            self.formData["stepcount"] = step
            print("step count 걸음 수 : \(step), \(self.dateFormatter.string(from: now))")})
    }
    
    @IBAction func selectData(_sender: Any?) {
        let url = URL(string: value+"/list?uid="+uid)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "select error")
                return
            }
            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
            print(json["data"]!)

        }
        task.resume()    }
    
    @IBAction func insertData(_sender: Any?) {
        let urlString = value+"/insert"
        let url = URL(string: urlString)
        var urlRequest = URLRequest(url: url!)
        //formData 구성은 각 데이터들 추출/출력 하는 곳에서 틈틈히 add 해놓았다.
        self.formData["date"] = self.dateFormatter.string(from: Date())
        print(self.formData)
        let formDataString = (formData.compactMap({ (key, value) -> String in return "\(key)=\(value)"})
            as Array).joined(separator: "&")
        let formEncodedData = formDataString.data(using: .utf8)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = formEncodedData
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            print(error?.localizedDescription ?? "inserted successfully")})
        task.resume()
    }
    
    func getTodaysSteps(completion: @escaping (Double, Date) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0, now)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()), now)
        }

        healthKitStore.execute(query)
    }
    
    func getReadablebloodType(bloodType: HKBloodType?)->String{
        var bloodTypeText = "";
        
        if bloodType != nil {
            switch (bloodType!) {
            case .aPositive:
                bloodTypeText = "A+"
            case .aNegative:
                bloodTypeText = "A-"
            case .bPositive:
                bloodTypeText = "B+"
            case .bNegative:
                bloodTypeText = "B-"
            case .abPositive:
                bloodTypeText = "AB+"
            case .abNegative:
                bloodTypeText = "AB-"
            case .oPositive:
                bloodTypeText = "O+"
            case .oNegative:
                bloodTypeText = "O-"
            default:
                break;
            }
        }
        return bloodTypeText;
    }
    
    func readProfile() -> ( age:Int?, bloodtype:HKBloodTypeObject?){
        var age: Int?
        var bloodType: HKBloodTypeObject?
        
        do {
            let birthDay = try healthKitStore.dateOfBirthComponents()
            let calendar = Calendar.current
            let currentyear = calendar.component(.year, from: Date())
            age = currentyear - birthDay.year!
        }
        catch{}
        
        do{
            bloodType = try healthKitStore.bloodType()
        }catch{}
        return (age,bloodType)
    }
    
    func authorizeHealthKitApp(){
        
        let healthKitTypesToRead : Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
             HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)!
            ]
        /*
        let healthKitTypesToWrite : Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!]
        */
        
        if !HKHealthStore.isHealthDataAvailable(){
            print("Error occured")
            return
        }
        
        healthKitStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead){
            (success, error) -> Void in
            print("Read Authorization succeeded")
        }
    }
    /*
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead){
            (success, error) -> Void in
            print("Read Write Authorization succeeded")
        }

    @IBAction func writeDataToHealthkit(_ sender: Any){
        self.writeToKit()
        self.txtWeight.text = ""
    }
    
    func writeToKit(){
        let weight = Double(self.txtWeight.text!)
        
        let today = NSDate()
        if let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass){
            
            let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: Double(weight!))
            
            let sample = HKQuantitySample(type: type, quantity: quantity, start: today as Date, end: today as Date)
            healthKitStore.save(sample, withCompletion: { (success, error) in print("Saved \(success), error \(String(describing: error))")
                
            })
        }
    }
    */
    
    func readMostRecentSample(){
        let weightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let heartType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let temperatureType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)!

        let heartRateQuery = HKSampleQuery(sampleType: heartType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (heartRateQuery, results, error) in
            if let result = results?.last as? HKQuantitySample{
                DispatchQueue.main.async(execute: { () -> Void in
                    self.lblHeart.text = "\(result.quantity)"
                    self.formData["heartrate"] = result.quantity
                });
                print("heartrate 심박수 : \(String(describing: result.quantity)), \(self.dateFormatter.string(from: result.endDate))")
            }else{
                print("error comes out => \(String(describing: results)), error => \(String(describing: error))")
            }
        }
        
        let weightQuery = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (weightQuery, results, error) in
            if let result = results?.last as? HKQuantitySample{
                DispatchQueue.main.async(execute: { () -> Void in
                    self.lblWeight.text = "\(result.quantity)"
                });
            } else{
                print("error comes out => \(String(describing: results)), error => \(String(describing: error))")
            }
        }
        
        let temperatureQuery = HKSampleQuery(sampleType: temperatureType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (temperatureQuery, results, error) in
            //print(results?.last?.endDate)
            if let result = results?.last as? HKQuantitySample{
                print("temperature 체온 : \(String(describing: result.quantity)), \(self.dateFormatter.string(from: result.endDate))")
            }else{
                print("error comes out => \(String(describing: results)), error => \(String(describing: error))")
            }
        }
  
        healthKitStore.execute(heartRateQuery)
        healthKitStore.execute(weightQuery)
        healthKitStore.execute(temperatureQuery)
}
}
