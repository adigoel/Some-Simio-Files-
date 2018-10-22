//
//  calibration.swift
//  Smart Camera
//
//  Created by Aditya Goel on 09/09/2018.
//  Copyright © 2018 Aditya Goel. All rights reserved.
//

import UIKit
import CoreLocation
class calibration: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var circleLabel: UILabel!
    var dotLabels:[UILabel] = Array()
    var locationManager = CLLocationManager()
    var dotLabel2:[Int] = Array()
    @IBOutlet var proceedButton: UIButton!
    var headingLabel = UILabel()
    
    override func viewWillAppear(_ animated: Bool) {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingHeading()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .black
        titleLabel.backgroundColor = UIColor.white
        titleLabel.layer.borderWidth = 2
        titleLabel.layer.cornerRadius = 5
        titleLabel.layer.borderColor = UIColor.white.cgColor
        titleLabel.textColor = UIColor.black
        titleLabel.numberOfLines = 0
        titleLabel.alpha = 0.80
        titleLabel.textAlignment = .center
        titleLabel.clipsToBounds = true
        titleLabel.text = "Compass Calibration"
        titleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        self.view.addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 35).isActive = true
        titleLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60.0).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        for x in 0...35 {
            var dx = Double(20 + self.circleLabel.frame.width/2)*cos(Double(x*10)*Double.pi/180.0)
            var dy = Double(20 + self.circleLabel.frame.width/2)*sin(Double(x*10)*Double.pi/180.0)
            dx = dx - 5.0 + Double(self.view.frame.width/2)
            dy = dy - 5.0 + Double(self.view.frame.height/2)
            var pointLabel = UILabel(frame: CGRect(x: CGFloat(dx), y: CGFloat(dy), width: 10, height: 10))
            pointLabel.alpha = 0.80
            pointLabel.clipsToBounds = true
            pointLabel.backgroundColor = UIColor.white
            pointLabel.layer.cornerRadius = 5
            self.dotLabels.append(pointLabel)
        }
        
        self.headingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.headingLabel.textColor = .black
        self.headingLabel.backgroundColor = UIColor.white
        self.headingLabel.layer.borderWidth = 2
        self.headingLabel.layer.cornerRadius = 5
        self.headingLabel.layer.borderColor = UIColor.white.cgColor
        self.headingLabel.textColor = UIColor.black
        self.headingLabel.numberOfLines = 0
        self.headingLabel.alpha = 0.80
        self.headingLabel.textAlignment = .center
        self.headingLabel.clipsToBounds = true
        self.headingLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        self.view.addSubview(self.headingLabel)
        self.headingLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.headingLabel.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -120).isActive = true
        self.headingLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        self.headingLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let angleValue:CLLocationDirection = manager.heading!.trueHeading
        let angle = newHeading.trueHeading
        deviceBearing = Double(angle)
        //print("\(angle) - ang")
        
        self.headingLabel.text = "\(Int(deviceBearing))º"
        
        if Int(deviceBearing)%10 == 0 || Int(deviceBearing)%10 == 1 {
            self.view.insertSubview(self.dotLabels[Int(deviceBearing)/10], aboveSubview: self.circleLabel)
            dotLabel2.append(Int(deviceBearing)/10)
        }
        if dotLabel2.count > 68 {
            self.proceedButton.setTitle("Proceed", for: .normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
