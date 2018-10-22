//
//  ViewController.swift
//  Smart Camera
//
//  Created by Aditya Goel on 13/07/2018.
//  Copyright © 2018 Aditya Goel. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit
import CoreLocation
import Foundation

var lat:CLLocationDegrees?
var long:CLLocationDegrees?
var resultsArray:[Dictionary<String, AnyObject>] = Array()
var placesLat:[Double] = Array()
var placesLong:[Double] = Array()
var placesName:[String] = Array()
var nonNumVicinities:[String] = Array()
var placesId:[String] = Array()
var placesVicinity:[String] = Array()
var placesDistance:[Double] = Array()
var placesBearing:[Double] = Array()
var placesOpeningTimes:[Bool] = Array()
let earthRadius:Double = 6378100
var deviceBearing = Double()
var placeToRequestId = String()
var placeToRequestBearing = Double()
var placeToRequestOpenStatus = Bool()
var nameToPresent = String()
var addressToPresent = String()
var numberToPresent = String()
var ratingToPresent = String()
var gMapsToPresent = String()
var websiteToPresent = String()
var openStatusToPresent = String()
var isInfoLabelActive:Int = 0
var label0 = UILabel()
var nameExtraInfo = String()
var addressExtraInfo = String()
var numberExtraInfo = String()
var ratingExtraInfo = String()
var gMapsExtraInfo = String()
var websiteExtraInfo = String()
var openStatusExtraInfo = String()
var reviewArray:[Dictionary<String, AnyObject>] = Array()
var wikiText = String()
var wikiUrlString = String()
var wikiTitle = String()
var wikiError = Bool()
var wikiSummary = String()
var nameForWiki = String()
var placeLat:CLLocationDegrees?
var placeLong:CLLocationDegrees?

class ViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    var locationManager = CLLocationManager()
    var captureSession = AVCaptureSession()
    var backCamera:AVCaptureDevice?
    var frontCamera:AVCaptureDevice?
    var currentCamera:AVCaptureDevice?
    var photoOutput:AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var image:UIImage?
    var add:String = ""

    @IBOutlet var activitySpinner: UIActivityIndicatorView!
    var usesLeftLabel = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activitySpinner.isHidden = true
        self.activitySpinner.stopAnimating()
        IAPService.shared.getProducts()
        IAPService.shared.restorePurchases()
        setupPreviewLayer()
        startRunningCaptureSession()

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.wasDragged))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.wasDragged))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.wasDragged))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        self.view.addGestureRecognizer(swipeUp)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        wikiError = false
        resultsArray.removeAll(keepingCapacity: true)
        placesDistance.removeAll(keepingCapacity: true)
        placesBearing.removeAll(keepingCapacity: true)
        placesLat.removeAll(keepingCapacity: true)
        placesLong.removeAll(keepingCapacity: true)
        placesName.removeAll(keepingCapacity: true)
        placesId.removeAll(keepingCapacity: true)
        placesVicinity.removeAll(keepingCapacity: true)
        placesOpeningTimes.removeAll(keepingCapacity: true)
        UserDefaults.standard.set(true, forKey: "toCamera")
        isInfoLabelActive = 0
        //print("ok")
        let launchedBefore = UserDefaults.standard.bool(forKey: "StartValue")
        if launchedBefore == false {
            //first time
            UserDefaults.standard.set(0, forKey: "UsageCount")
            UserDefaults.standard.set(true, forKey: "StartValue")
        }
        else {
            //not first time
            //used while testing purchasee functionality
            //UserDefaults.standard.set(true, forKey: "Unlimited")
        }
        
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
        }
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: "Unlimited") == false {
                self.usesLeftLabel.translatesAutoresizingMaskIntoConstraints = false
                self.usesLeftLabel.textColor = .black
                self.usesLeftLabel.backgroundColor = UIColor.white
                self.usesLeftLabel.layer.borderWidth = 2
                self.usesLeftLabel.layer.cornerRadius = 5
                self.usesLeftLabel.layer.borderColor = UIColor.white.cgColor
                self.usesLeftLabel.textColor = UIColor.black
                self.usesLeftLabel.numberOfLines = 0
                self.usesLeftLabel.alpha = 0.80
                self.usesLeftLabel.textAlignment = .center
                self.usesLeftLabel.clipsToBounds = true
                self.usesLeftLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
                let usesLeft:Int = 12-UserDefaults.standard.integer(forKey: "UsageCount")
                if usesLeft == 0 {
                    self.usesLeftLabel.text = "0 uses left"
                }
                else if usesLeft == 1 {
                    self.usesLeftLabel.text = "1 use left"
                }
                else if usesLeft < 0 {
                    self.usesLeftLabel.text = "0 uses left"
                }
                else {
                    self.usesLeftLabel.text = "\(usesLeft) uses left"
                }
                self.view.addSubview(self.usesLeftLabel)
                self.usesLeftLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                self.usesLeftLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
                self.usesLeftLabel.widthAnchor.constraint(equalToConstant: 105).isActive = true
                self.usesLeftLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
        UIView.animate(withDuration: 6, animations: {
            self.usesLeftLabel.alpha = 0.0
            })
    }
   
    @IBAction func gestureAct(_ sender: Any) {
        //print("longpress")
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        placesLat = Array(placesLat.prefix(20))
        placesLong = Array(placesLong.prefix(20))
        placesName = Array(placesName.prefix(20))
        placesVicinity = Array(placesVicinity.prefix(20))
        placesId = Array(placesId.prefix(20))
        //print("\(placesLat)")
        if isInfoLabelActive == 0 {
            //print("pp")
            searchPlaceFromGoogle()
            //print("erer ----\(wikiError)")
        }
        else {
            //print(" ")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let angleValue:CLLocationDirection = manager.heading!.trueHeading
        let angle = newHeading.trueHeading
        deviceBearing = Double(angle)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationValue:CLLocationCoordinate2D = manager.location!.coordinate
        ////print("\(locationValue.latitude), \(locationValue.longitude)")
        lat = locationValue.latitude
        long =  locationValue.longitude
        let userLocation = locations.last
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        //print("dev - \(devices)")
        
        for device in devices{
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        }
        catch{
            //print(error)
        }
    }
    
    func setupPreviewLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        cameraPreviewLayer!.frame = self.view.frame
        
    }
    
    func startRunningCaptureSession() {
        captureSession.startRunning()
    }
    
    func searchPlaceFromGoogle() {
        self.activitySpinner.isHidden = false
        self.activitySpinner.startAnimating()
        //print("Fasaaa")
        var strGoogleApi = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(Double(lat!)),\(Double(long!))&rankby=distance&key=AIzaSyBThkAusFd__r3B690LLGNFV97ZaukWuWQ"
        //var strGoogleApi = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=51.5133,-0.0988&rankby=distance&key=AIzaSyBThkAusFd__r3B690LLGNFV97ZaukWuWQ"
        strGoogleApi = strGoogleApi.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        var urlRequest = URLRequest(url: URL(string: strGoogleApi)!)
        urlRequest.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, resopnse, error) in
            if error == nil {
                if let responseData = data {
                    let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                    if let dict = jsonDict as? Dictionary<String, AnyObject>{
                        if let results = dict["results"] as? [Dictionary<String, AnyObject>] {
                            ////print("json == \(results)")
                            resultsArray.removeAll()
                            for dct in results {
                                resultsArray.append(dct)
                            }
                        }
                        if let requestStatus = dict["status"] as? String {
                            //print("req status - \(requestStatus)")
                            if requestStatus == "OVER_QUERY_LIMIT" {
                                //print("over limit")
                                DispatchQueue.main.async {
                                    self.activitySpinner.isHidden = true
                                    self.activitySpinner.stopAnimating()
                                    //generate new api key
                                }
                            }
                        }
                    }
                }
                for place in resultsArray {
                    //print("k")
                    if let locationGeometry = place["geometry"] as? Dictionary<String, AnyObject> {
                        if let location = locationGeometry["location"] as? Dictionary<String, AnyObject> {
                            if let latitude = location["lat"] as? Double {
                                if let longitude = location["lng"] as? Double {
                                    ////print("lat - \(latitude), long - \(longitude)")
                                    placesLat.append(latitude)
                                    placesLong.append(longitude)
                                }
                            }
                        }
                    }
                    if let name = place["name"] as? String {
                        placesName.append(name)
                    }
                    //print("ee \(placesName)")
                    if let vicinity = place["vicinity"] as? String {
                        placesVicinity.append(vicinity)
                    }
                    //print("\(placesVicinity)")
                    if let placeID = place["place_id"] as? String {
                        placesId.append(placeID)
                    }
                    //print("\(placesId)")
                    if let openingHours = place["opening_hours"] as? Dictionary<String, AnyObject> {
                        if let openNow = openingHours["open_now"] as? Bool {
                            placesOpeningTimes.append(openNow)
                            //print("p - \(placesOpeningTimes)")
                        }
                    }
                }
                //print("\(placesLat)")
                self.placeToPresent()
            }
            else {
                DispatchQueue.main.async {
                    //print("errorjson")
                    self.activitySpinner.isHidden = true
                    self.activitySpinner.stopAnimating()
                    //we have error connection google api
                }
            }
        }
        task.resume()
        
    }
    
    func placeToPresent() {
        if placesLat.isEmpty == false {
            placesLat = Array(placesLat.prefix(20))
            placesLong = Array(placesLong.prefix(20))
            placesName = Array(placesName.prefix(20))
            placesVicinity = Array(placesVicinity.prefix(20))
            placesId = Array(placesId.prefix(20))
            placesOpeningTimes = Array(placesOpeningTimes.prefix(20))

            for x in 0...(placesLat.count) {
                //print("startloop")
                if lat == nil || long == nil {
                    //print("lat & long of user not determined")
                    self.viewDidLoad()
                }
                else {
                    /*var dLat:Double = abs(placesLat[x] - Double(lat!))
                    var dLong:Double = abs(placesLong[x] - Double(long!))*/
                    if x < placesLat.count-1 && x < placesLong.count-1 {
                        var latUser:Double = Double(lat!)
                        var longUser:Double = Double(long!)
                        //For testing purposes only:
                        //var latUser:Double = 51.5133
                        //var longUser:Double = -0.0988
                        var userBearing: Double = deviceBearing
                        var dLat:Double = placesLat[x] - latUser
                        var dLong:Double = placesLong[x] - longUser

                        dLat = dLat*Double.pi/180
                        dLong = dLong*Double.pi/180
                        var dy:Double = earthRadius*dLat
                        var dx:Double = (2*earthRadius*dLong)/(cos(Double(latUser)*Double.pi/180) + cos(Double(placesLat[x])*Double.pi/180))
                        let distance:Double = sqrt((dx*dx)+(dy*dy))
                        var dangle:Double
                        dangle = 50

                        if dx > 0.0 && dy > 0.0 {
                            //print("Q1 PLACE -* \(placesName[x])")
                            dangle = 180*atan(abs(dx/dy))/Double.pi
                        }
                        else if dx > 0.0 && dy < 0.0 {
                            //print("Q2 PLACE -* \(placesName[x])")
                            dangle = 180*atan(abs(dy/dx))/Double.pi
                            dangle = dangle + 90
                        }
                        else if dx < 0.0 && dy < 0.0 {
                            //print("Q3 PLACE -* \(placesName[x])")
                            dangle = 180*atan(abs(dx/dy))/Double.pi
                            dangle = dangle + 180
                        }
                        else if dx < 0.0 && dy > 0.0 {
                            //print("Q4 PLACE -* \(placesName[x])")
                            dangle = 180*atan(abs(dy/dx))/Double.pi
                            dangle = dangle + 270
                        }
                        dangle = abs(dangle - userBearing)
                        if dangle < 360.0 && dangle > 180.0 {
                            dangle = 360 - dangle
                        }
                        //print("\(dangle) *** \(placesName[x])")

                        placesBearing.append(dangle)
                        placesDistance.append(distance)
                        nonNumVicinities.append("\((placesVicinity[x].components(separatedBy: CharacterSet.decimalDigits)).joined(separator: ""))")
                        
                    }
                    else {
                        //print("counterror")
                        DispatchQueue.main.async {
                            self.activitySpinner.isHidden = true
                            self.activitySpinner.stopAnimating()
                        }
                        //performSegue(withIdentifier: "reboot", sender: self)
                    }
                }
            }
            nonNumVicinities = Array(nonNumVicinities.prefix(20))
            placesBearing = Array(placesBearing.prefix(20))
            placesDistance = Array(placesDistance.prefix(20))
            placesVicinity = Array(placesVicinity.prefix(20))
            
            if placesBearing.min() == nil {
                nameExtraInfo = ""
                addressExtraInfo = ""
                openStatusExtraInfo = ""
                ratingExtraInfo = ""
                gMapsExtraInfo = ""
                websiteExtraInfo = ""
                numberExtraInfo = ""
                nameToPresent = ""
                addressToPresent = ""
                numberToPresent = ""
                ratingToPresent = ""
                gMapsToPresent = ""
                websiteToPresent = ""
                openStatusToPresent = ""
                wikiText = ""
                wikiUrlString = ""
                wikiSummary = ""
                nameForWiki = ""
                reviewArray.removeAll()
                placesDistance.removeAll()
                placesBearing.removeAll()
                placesLat.removeAll()
                placesLong.removeAll()
                placesName.removeAll()
                placesId.removeAll()
                placesVicinity.removeAll()
                placesOpeningTimes.removeAll()
                placeToRequestId = ""
                self.activitySpinner.isHidden = true
                self.activitySpinner.stopAnimating()
            }
            else {
                if placesBearing.min()! < 30 {
                    var sortedBearings:[Double] = placesBearing.sorted()
                    sortedBearings.removeSubrange(2...(sortedBearings.count-1))
                    //print(sortedBearings)
                    let d1:Double = abs(sortedBearings[0] - sortedBearings[1])
                    //print("d1 --> \(d1)")
                    var indexMinBearing = placesBearing.index(of: placesBearing.min()!)
                    if d1 > 12 {
                        //old pure bearing system
                    }
                    else {
                        //point system
                        var vicinityPerms = [[[[[String]]]]]()
                        for vicinity in placesVicinity {
                            var str = "\(vicinity)"
                            str = str.replacingOccurrences(of: ",", with: "")
                            var strArr:[String]
                            strArr = str.components(separatedBy: " ")
                            var allPerms = [[[[String]]]]()
                            for x in 0...(strArr.count-1) {
                                //start word
                                var onePerm = [[[String]]]()
                                for m in 0...(strArr.count-1-x) {
                                    //length of word
                                    var uPerm = [[String]]()
                                    for i in 0...m {
                                        var aPerm = [String]()
                                        aPerm.append(strArr[x+i])
                                        uPerm.append(aPerm)
                                    }
                                    onePerm.append(uPerm)
                                }
                                allPerms.append(onePerm)
                            }
                            vicinityPerms.append(allPerms)
                        }
                        // print(vicinityPerms)
                        
                        var substringArray:[String] = Array()
                        
                        for vicinity in vicinityPerms {
                            for address in vicinityPerms {
                                for startWord in address {
                                    for substring in startWord {
                                        var substringToExtract:String = ""
                                        for word in substring {
                                            substringToExtract += " \(word[0])"
                                        }
                                        substringArray.append(substringToExtract)
                                    }
                                }
                            }
                        }
                        // print("substrings --> ")
                        // find faster way this is O(n^2)
                        // print(substringArray)

                        //BREAK
                        
                        var namesPerms = [[[[[String]]]]]()
                        for name in placesName {
                            var str = "\(name)"
                            str = str.replacingOccurrences(of: ",", with: "")
                            var strArr:[String]
                            strArr = str.components(separatedBy: " ")
                            var allPerms = [[[[String]]]]()
                            for x in 0...(strArr.count-1) {
                                //start word
                                var onePerm = [[[String]]]()
                                for m in 0...(strArr.count-1-x) {
                                    //length of word
                                    var uPerm = [[String]]()
                                    for i in 0...m {
                                        var aPerm = [String]()
                                        aPerm.append(strArr[x+i])
                                        uPerm.append(aPerm)
                                    }
                                    onePerm.append(uPerm)
                                }
                                allPerms.append(onePerm)
                            }
                            namesPerms.append(allPerms)
                        }
                        ////print(namesPerms)
                        
                        var substringArrayName:[[String]] = Array()
                        
                        for name in namesPerms {
                            for address in namesPerms {
                                var substringAddress:[String] = Array()
                                for startWord in address {
                                    for substring in startWord {
                                        var substringToExtract:String = ""
                                        for word in substring {
                                            substringToExtract += " \(word[0])"
                                        }
                                        substringAddress.append(substringToExtract)
                                    }
                                }
                                substringArrayName.append(substringAddress)
                            }
                        }
                        substringArrayName = Array(substringArrayName.prefix(placesName.count))
                        ////print("substringsName --> ")
                        ////print(substringArrayName)
                        placesLat = Array(placesLat.prefix(19))
                        placesLong = Array(placesLong.prefix(19))
                        placesName = Array(placesName.prefix(19))
                        placesBearing = Array(placesBearing.prefix(19))
                        placesId = Array(placesId.prefix(19))
                        placesDistance = Array(placesDistance.prefix(19))
                        var placesScore:[Int] = Array()
                        var placeAddressMatchCount:[Int] = Array()
                        var placeBearingCount:[Int] = Array()
                        var placeDistanceCount:[Int] = Array()
                        for x in 0...(placesName.count-1) {
                            placeAddressMatchCount.append(0)
                            placeBearingCount.append(0)
                            placeDistanceCount.append(0)
                            placesScore.append(0)
                        }
                        for i in 0...(placesName.count-1) {
                            for permutation in substringArrayName[i] {
                                placeAddressMatchCount[i] += substringArray.filter{$0 == permutation}.count
                            }
                            if placeAddressMatchCount[i] < 75 {
                                placeAddressMatchCount[i] = 0
                            }
                            else if placeAddressMatchCount[i] > 600 {
                                placeAddressMatchCount[i] = 600
                            }
                            let avoidNameArray = ["Park"]
                            let keyNameArray = ["Palace", "Temple", "Museum", "Gallery", "College", "School", "Pyramids", "Tomb", "Mausoleum", "Parliament", "Memorial", "Tower", "White House", "Cricket Ground", "Football Ground", "Football Stadium", "Olympic", "Clocktower", "Church", "Mosque", "Musee", "Monument", "Embassy", "Castle", "Skyscraper", "Statue", "Colosseum", "Basilica", "Arc de Triomphe", "Cathedral", "Taj Mahal", "Capitol", "Trevi", "Buckingham Palace", "Towers", "Abbey", "Hagia Sophia", "Gate", "Chapel", "Parthenon"]
                            let midNameArray = ["Sports Ground", "Bridge", "Fountain", "Wall", "National Park"]
                            for permutation in substringArrayName[i] {
                                if (keyNameArray.filter{$0 == permutation}.count) > 0 {
                                    placeAddressMatchCount[i] += 300
                                }
                                if (avoidNameArray.filter{$0 == permutation}.count) > 0 {
                                    placeAddressMatchCount[i] -= 150
                                }
                                if (midNameArray.filter{$0 == permutation}.count) > 0 {
                                    placeAddressMatchCount[i] += 150
                                }
                            }
                        }
                        for x in 0...(placesDistance.count-1) {
                            if placesDistance[x] > 20 && placesDistance[x] < 40 {
                                placeDistanceCount[x] = 100
                            }
                            else if placesDistance[x] > 10 && placesDistance[x] < 15 {
                                placeDistanceCount[x] = 350
                            }
                            else if placesDistance[x] > 5 && placesDistance[x] < 10 {
                                placeDistanceCount[x] = 550
                            }
                            else if placesDistance[x] < 5 {
                                placeDistanceCount[x] = 600
                            }
                            else {
                                placeDistanceCount[x] = 0
                            }
                        }
                        let sortedBearingArray:[Double] = placesBearing.sorted()
                        for x in 0...(placesBearing.count-1) {
                            if placesBearing[x] > 30 {
                                placeBearingCount[x] = 0
                            }
                            else if placesBearing[x] < 40 && placesBearing[x] > 30 {
                                placeBearingCount[x] = 500
                            }
                            else if placesBearing[x] < 30 && placesBearing[x] > 15 {
                                placeBearingCount[x] = 1050
                            }
                            else if placesBearing[x] < 15 && placesBearing[x] > 0 {
                                placeBearingCount[x] = 1300
                            }
                        }
                        for x in 0...(placesScore.count-1) {
                            placesScore[x] = placeAddressMatchCount[x] + placeBearingCount[x] + placeDistanceCount[x]
                        }
                        indexMinBearing = placesScore.index(of: placesScore.max()!)
                    }
                    if indexMinBearing! < placesId.count && indexMinBearing! < placesBearing.count {
                        placeToRequestId = placesId[indexMinBearing!]
                        placeToRequestBearing = placesBearing[indexMinBearing!]
                        placeLat = placesLat[indexMinBearing!]
                        placeLong = placesLong[indexMinBearing!]
                        self.presentInformationAboutPlace()
                    }
                    else {
                        //print("Priorly reboot situation")
                        nameExtraInfo = ""
                        addressExtraInfo = ""
                        openStatusExtraInfo = ""
                        ratingExtraInfo = ""
                        gMapsExtraInfo = ""
                        websiteExtraInfo = ""
                        numberExtraInfo = ""
                        nameToPresent = ""
                        addressToPresent = ""
                        numberToPresent = ""
                        ratingToPresent = ""
                        gMapsToPresent = ""
                        websiteToPresent = ""
                        openStatusToPresent = ""
                        wikiText = ""
                        wikiUrlString = ""
                        wikiSummary = ""
                        nameForWiki = ""
                        reviewArray.removeAll()
                        placesDistance.removeAll()
                        placesBearing.removeAll()
                        placesLat.removeAll()
                        placesLong.removeAll()
                        placesName.removeAll()
                        placesId.removeAll()
                        placesVicinity.removeAll()
                        placesOpeningTimes.removeAll()
                        placeToRequestId = ""
                        self.activitySpinner.isHidden = true
                        self.activitySpinner.stopAnimating()
                        //Priorly reboot situation

                    }
                    //print(placeToRequestId)
                    ////print("\(placesName[indexMinBearing!])")
                }
                else {
                    //print("dangle too large")
                    placeToRequestId = ""
                    placesDistance.removeAll(keepingCapacity: true)
                    placesBearing.removeAll(keepingCapacity: true)
                    placesLat.removeAll(keepingCapacity: true)
                    placesLong.removeAll(keepingCapacity: true)
                    placesName.removeAll(keepingCapacity: true)
                    placesId.removeAll(keepingCapacity: true)
                    placesVicinity.removeAll(keepingCapacity: true)
                    placesOpeningTimes.removeAll(keepingCapacity: true)
                    DispatchQueue.main.async {
                        self.activitySpinner.isHidden = true
                        self.activitySpinner.stopAnimating()
                    }
                }
            }
        }
        else {
            print("")
        }
    }
    
    func presentInformationAboutPlace() { 
        if placeToRequestId == "" {
            //print("no place to req id")
        }
        else {
            var url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeToRequestId)&fields=name,rating,formatted_phone_number,photo,opening_hours,website,url,rating,review,formatted_address&key=AIzaSyBThkAusFd__r3B690LLGNFV97ZaukWuWQ"
            //print(url)
            //print(placeToRequestId)
            //ChIJN8X3fVwFdkgR4F_fdQ5HQSU
            //var url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJN8X3fVwFdkgR4F_fdQ5HQSU&fields=name,rating,formatted_phone_number,opening_hours,website,url,rating,review,formatted_address&key=AIzaSyBThkAusFd__r3B690LLGNFV97ZaukWuWQ"
            url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            var urlRequest = URLRequest(url: URL(string: url)!)
            urlRequest.httpMethod = "GET"
            //print("zapora")
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                if error == nil {
                    if let responseData = data {
                        let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                        if let dict = jsonDict as? Dictionary<String, AnyObject>{
                            if let requestStatus = dict["status"] as? String {
                                //print("req status - \(requestStatus)")
                                if requestStatus == "OVER_QUERY_LIMIT" {
                                    print("over limit2")
                                }
                            }
                            if let result = dict["result"] as? Dictionary<String, AnyObject> {
                                ////print("json2 == \(result)")
                                if let name = result["name"] as? String {
                                    nameToPresent = name
                                    //print("name - \(nameToPresent)")
                                    nameForWiki = name
                                    //print("name - \(nameForWiki)")
                                    
                                }
                                if let address = result["formatted_address"] as? String {
                                    addressToPresent = address
                                    //print(address)
                                }
                                if let phoneNumber = result["formatted_phone_number"] as? String {
                                    numberToPresent = phoneNumber
                                    //print(numberToPresent)
                                }
                                if let rating = result["rating"] as? Double {
                                    ratingToPresent = "\(rating)"
                                    //print(ratingToPresent)
                                }
                                if let gMapsUrl = result["url"] as? String {
                                    gMapsToPresent = gMapsUrl
                                    //print(gMapsToPresent)
                                }
                                if let website = result["website"] as? String {
                                    websiteToPresent = website
                                    //print(websiteToPresent)
                                }
                                if let photos = result["photos"] as? [Dictionary<String, AnyObject>] {
                                    if let photo = photos.last as? Dictionary<String, AnyObject> {
                                        if let photoReference = photo["photo_reference"] as? String {
                                            //print(photoReference)
                                        }
                                    }
                                }
                                if let openingHours = result["opening_hours"] as? Dictionary<String, AnyObject> {
                                    if let openNow = openingHours["open_now"] as? Bool {
                                        if openNow == false {
                                            openStatusToPresent = "Closed Right Now"
                                        }
                                        else if openNow == true {
                                            openStatusToPresent = "Open Right Now"
                                        }
                                        else {
                                            openStatusToPresent = "No Data As To Whether Open"
                                        }
                                        //print(openStatusToPresent)
                                        
                                    }
                                if let reviews = result["reviews"] as? [Dictionary<String, AnyObject>] {
                                    for review in reviews {
                                        reviewArray.append(review)
                                    }
                                }
                                }
                            }
                        }
                    }
                    if addressToPresent == "" {
                        addressToPresent = "No Address Available"
                    }
                    if numberToPresent == "" {
                        numberToPresent = "No Telephone Number Available"
                    }
                    
                    self.generateLabel()
                }
                else {
                    //print("error connecting to place description api")
                }
            }
            task.resume()
        }
    }
   
    @objc func wasDragged(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                if isInfoLabelActive == 0 {
                    print("")
                }
                else if isInfoLabelActive > 0 {
                    nameExtraInfo = ""
                    addressExtraInfo = ""
                    openStatusExtraInfo = ""
                    ratingExtraInfo = ""
                    gMapsExtraInfo = ""
                    websiteExtraInfo = ""
                    numberExtraInfo = ""
                    nameToPresent = ""
                    addressToPresent = ""
                    numberToPresent = ""
                    ratingToPresent = ""
                    gMapsToPresent = ""
                    websiteToPresent = ""
                    openStatusToPresent = ""
                    wikiText = ""
                    wikiUrlString = ""
                    wikiSummary = ""
                    nameForWiki = ""
                    reviewArray.removeAll()
                    placesDistance.removeAll()
                    placesBearing.removeAll()
                    placesLat.removeAll()
                    placesLong.removeAll()
                    placesName.removeAll()
                    placesId.removeAll()
                    placesVicinity.removeAll()
                    placesOpeningTimes.removeAll()
                    wikiError = false
                    isInfoLabelActive = 0
                    //print("\(placesName)")
                    //print("\(placesLat), \(placesLong)")
                    //print("\(placesId)")
                    DispatchQueue.main.async {
                        if UserDefaults.standard.bool(forKey: "Unlimited") == false {
                            self.usesLeftLabel.translatesAutoresizingMaskIntoConstraints = false
                            self.usesLeftLabel.textColor = .black
                            self.usesLeftLabel.backgroundColor = UIColor.white
                            self.usesLeftLabel.layer.borderWidth = 2
                            self.usesLeftLabel.layer.cornerRadius = 5
                            self.usesLeftLabel.layer.borderColor = UIColor.white.cgColor
                            self.usesLeftLabel.textColor = UIColor.black
                            self.usesLeftLabel.numberOfLines = 0
                            self.usesLeftLabel.alpha = 0.80
                            self.usesLeftLabel.textAlignment = .center
                            self.usesLeftLabel.clipsToBounds = true
                            self.usesLeftLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
                            let usesLeft:Int = 12-UserDefaults.standard.integer(forKey: "UsageCount")
                            if usesLeft == 0 {
                                self.usesLeftLabel.text = "0 uses left"
                            }
                            else if usesLeft == 1 {
                                self.usesLeftLabel.text = "1 use left"
                            }
                            else if usesLeft < 0 {
                                self.usesLeftLabel.text = "0 uses left"
                            }
                            else {
                                self.usesLeftLabel.text = "\(usesLeft) uses left"
                            }
                            self.view.addSubview(self.usesLeftLabel)
                            self.usesLeftLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                            self.usesLeftLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50).isActive = true
                            self.usesLeftLabel.widthAnchor.constraint(equalToConstant: 105).isActive = true
                            self.usesLeftLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        }
                        UIView.animate(withDuration: 1.0, animations: {
                            label0.frame.origin.x += UIScreen.main.bounds.width - 25
                        })
                        //isInfoLabelActive = isInfoLabelActive - 1
                        isInfoLabelActive = 0
                        UIView.animate(withDuration: 6, animations: {
                            self.usesLeftLabel.alpha = 0.0
                        })
                        
                    }
                }
            case UISwipeGestureRecognizerDirection.down:
                print("Swiped down")
                if isInfoLabelActive == 0 {
                    print("")
                }
                else if isInfoLabelActive > 0 {
                    performSegue(withIdentifier: "segueExtraInfo", sender: self)
                }
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
            case UISwipeGestureRecognizerDirection.up:
                print("Swiped up")
                if isInfoLabelActive == 0 {
                    print("")
                }
                else if isInfoLabelActive > 0 {
                    performSegue(withIdentifier: "segueExtraInfo", sender: self)
                }
                
            default:
                break
            }
        }
        //print("dragged")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto_Segue" {
            let previewVC = segue.destination as! PreviewViewController
            previewVC.image = self.image
        }
    }
    
    func generateLabel() {
        DispatchQueue.main.async {
            self.activitySpinner.isHidden = true
            self.activitySpinner.stopAnimating()
        }
        var attributedString = NSMutableAttributedString()
        var noItemsToDisplay = Int()
        nameExtraInfo = nameToPresent
        nameForWiki = nameExtraInfo
        addressExtraInfo = addressToPresent
        numberExtraInfo = numberToPresent
        ratingExtraInfo = ratingToPresent
        gMapsExtraInfo = gMapsToPresent
        websiteExtraInfo = websiteToPresent
        openStatusExtraInfo = openStatusToPresent
        nameToPresent = ""
        addressToPresent = ""
        numberToPresent = ""
        ratingToPresent = ""
        gMapsToPresent = ""
        websiteToPresent = ""
        openStatusToPresent = ""
        
        if wikiError == false {
            nameForWiki = nameExtraInfo
            //print("no wiki error there")
            var overviewItems:[String] = [nameExtraInfo, addressExtraInfo, openStatusExtraInfo, numberExtraInfo]
            var att:String = ""
            for item in overviewItems {
                if item == "" || item == " " {
                    print("")
                }
                else {
                    if item == overviewItems.first! {
                        att.append("\n\(item)  ")
                    }
                    else {
                        att.append("\n\(item)  ")
                    }
                }
            }
            noItemsToDisplay = overviewItems.count
            attributedString = NSMutableAttributedString(string: "Quick Overview  \n\(att)")
            //print("\(attributedString)")
        }
        
        else if wikiError == true {
            
            var overviewItems:[String] = [nameExtraInfo, addressExtraInfo, numberExtraInfo, ratingExtraInfo]
            
            var att:String = ""
            for item in overviewItems {
                if item == "" || item == " " {
                    print("")
                }
                else {
                    if item == overviewItems.first! {
                        att.append("\(item)  ")
                    }
                    else {
                        att.append("\n\(item)  ")
                    }
                }
            }
            noItemsToDisplay = overviewItems.count
            attributedString = NSMutableAttributedString(string: "Quick Overview  \(att)")
        }
        
        //print("text - \(attributedString)")
        DispatchQueue.main.async {
            if isInfoLabelActive == 0 {
                //print("generate")
                if wikiError == true {
                    label0 = UILabel(frame: CGRect(x: self.view.frame.width/2, y: self.view.frame.height/2, width: UIScreen.main.bounds.width - 50, height: CGFloat(noItemsToDisplay*30 + 80)))
                }
                else {
                    label0 = UILabel(frame: CGRect(x: self.view.frame.width/2, y: self.view.frame.height/2, width: UIScreen.main.bounds.width - 50, height: CGFloat(noItemsToDisplay*30 + 80)))
                }
                //print("-------\(noItemsToDisplay)")
                label0.center = CGPoint(x: self.view.center.x, y: self.view.center.y+20)
                label0.textAlignment = .center
                label0.backgroundColor = UIColor.lightGray
                label0.layer.cornerRadius = 5
                label0.layer.borderWidth = 0
                label0.textColor = UIColor.black
                label0.adjustsFontSizeToFitWidth = true
                label0.numberOfLines = 0
                label0.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
                label0.alpha = 0.80
                label0.clipsToBounds = true
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                attributedString.addAttribute(kCTParagraphStyleAttributeName as NSAttributedStringKey, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
                label0.attributedText = attributedString
                var usageCountNew:Int = Int(UserDefaults.standard.integer(forKey: "UsageCount"))
                var isUnlimited:Bool = Bool(UserDefaults.standard.bool(forKey: "Unlimited"))
                //print("\(usageCountNew) - usage counts")
                if usageCountNew < 12 || isUnlimited == true {
                    self.view.addSubview(label0)
                    label0.isUserInteractionEnabled = true
                    usageCountNew = usageCountNew + 1
                    UserDefaults.standard.set(usageCountNew, forKey: "UsageCount")
                }
                else {
                    //print("In App Purchase")
                    self.inAppPurchaseUnlimitedUse()
                }
            }
            else {
                //print("overfull/nodata")
            }
            isInfoLabelActive = isInfoLabelActive + 1
            //print("label no. \(isInfoLabelActive)")
        }
        /*nameExtraInfo = nameToPresent
        addressExtraInfo = addressToPresent
        numberExtraInfo = numberToPresent
        ratingExtraInfo = ratingToPresent
        gMapsExtraInfo = gMapsToPresent
        websiteExtraInfo = websiteToPresent
        openStatusExtraInfo = openStatusToPresent
        nameToPresent = ""
        addressToPresent = ""
        numberToPresent = ""
        ratingToPresent = ""
        gMapsToPresent = ""
        websiteToPresent = ""
        openStatusToPresent = ""*/
        
        self.wikipediaDataDownload()
    }
    
    func wikipediaDataDownload() {
        //print("\(wikiError) -m- \(nameForWiki)")
        wikiText = ""
        if nameForWiki == "" || nameForWiki == " " {
            //print("name error")
        }
        else {
            var formattedPlaceName:String = nameForWiki.replacingOccurrences(of: " ", with: "_")
            var url = "https://en.wikipedia.org/w/api.php?format=json&&redirects=1&action=query&prop=extracts&exintro=&explaintext=&titles=\(formattedPlaceName)"
            ////print("wikiurl - \(url)")
            url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            var urlRequest = URLRequest(url: URL(string: url)!)
            urlRequest.httpMethod = "GET"
            //print("zazz")
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                if error == nil {
                    if let responseData = data {
                        let jsonDict = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
                        if let dict = jsonDict as? Dictionary<String, AnyObject>{
                            if let query = dict["query"] as? Dictionary<String, AnyObject> {
                                ////print("json3 == \(query)")
                                if let pages = query["pages"] as? Dictionary<String, AnyObject> {
                                    ////print("pages - \(pages)")
                                    var firstKey:String = String(Array(pages.keys).first!)
                                    //print("mario - \(firstKey)")
                                    if firstKey == "-1" {
                                        wikiError = true
                                        //print("wiki fail")
                                        //print("\(wikiError)")
                                    }
                                    if let numberPoint = pages[firstKey] as? Dictionary<String, AnyObject> {
                                        if let extract = numberPoint["extract"] as? String {
                                            //print("extract - \(extract)")
                                            wikiText = extract
                                            wikiUrlString = "https://en.wikipedia.org/wiki/\(formattedPlaceName)"
                                            
                                            if wikiText.components(separatedBy: "").contains(".") {
                                                wikiSummary = wikiText.substring(to: wikiText.index(of: ".")!)
                                            }
                                            else {
                                                wikiSummary = String(wikiText.characters.prefix(150))
                                            }
                                            //print("wikitext - \(wikiText)")
                                            //print("wikiSummary - \(wikiSummary)")
                                        }
                                        if let title = numberPoint["title"] as? String {
                                            //print("title - \(title)")
                                            wikiTitle = title
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    //print("error connecting to wikipedia api")
                }
            }
            task.resume()
            //print("\(wikiError)")
        }
    }
    
    func inAppPurchaseUnlimitedUse() {
        let alert = UIAlertController(title: "Free Use Limit", message: "Unfortunately you've reached the free use limit. Unlimited use passes can be bought below.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Purchase", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                IAPService.shared.purchase(product: .nonConsumable)
            case .cancel:
                print("cancel")
            case .destructive:
                print("destructive")
            }}))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            switch action.style{
            case .default:
                print("default")
            case .cancel:
                print("cancel")
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraButton_TouchUpInside(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        //performSegue(withIdentifier: "showPhoto_Segue", sender: nil)
    }
}

extension ViewController:AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            image = UIImage(data: imageData)
            performSegue(withIdentifier: "showPhoto_Segue", sender: nil)
        }
    }
}

