//
//  ViewController.swift
//  GPSTrack
//
//  Created by Sergey Orekhov on 16.10.2019.
//  Copyright © 2019 so. All rights reserved.
//

import UIKit
import CoreLocation
import MessageUI

class ViewController: UIViewController,
                      CLLocationManagerDelegate,
                      MFMailComposeViewControllerDelegate {

    @IBOutlet weak var runBtn: UIButton!
    @IBOutlet weak var coordinatesLbl: UILabel!
    @IBOutlet weak var speedLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var countLbl: UILabel!
    
    var locationManager: CLLocationManager? = nil
    var coordinates: [CLLocation] = []
    var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||
            CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
        else if (CLLocationManager.authorizationStatus() == .notDetermined) {
            locationManager?.requestWhenInUseAuthorization()
        }
        else {
            showAlert("Allow using location in settings.")
        }
    }

    func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Notice", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        runBtn.isHidden = true
        coordinatesLbl.isHidden = true
        speedLbl.isHidden = true
        timeLbl.isHidden = true
        countLbl.isHidden = true
        
        if locations.count > 0 {
            runBtn.isHidden = false
            
            let location = locations[0]
            
            coordinatesLbl.isHidden = false
            coordinatesLbl.text = String(format: "%.5f  %.5f", location.coordinate.latitude, location.coordinate.longitude)
            
            if isRunning {
                if let prevLocation = coordinates.last {
                    let time = location.timestamp.timeIntervalSince(prevLocation.timestamp)
                    let dist = location.distance(from: prevLocation)
                    let speed = dist / time * 3.6
                    speedLbl.isHidden = false
                    speedLbl.text = String(format: "%.2f km/h", speed)
                }

                if let firstLocation = coordinates.first {
                    let time = location.timestamp.timeIntervalSince(firstLocation.timestamp)
                    
                    let formatter = DateComponentsFormatter()
                    formatter.unitsStyle = .abbreviated
                    formatter.allowedUnits = [ .second, .minute, .hour ]
                    
                    timeLbl.isHidden = false
                    timeLbl.text = formatter.string(from: time)
                }
                
                coordinates.append(location)
                
                countLbl.isHidden = false
                countLbl.text = String("\(coordinates.count) frs")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    @IBAction func runTapped(_ sender: Any) {
        if isRunning {
            isRunning = false
            
            sendEmail()
            
            runBtn.setTitle("Start", for: .normal)
            
            UIApplication.shared.isIdleTimerDisabled = true
        }
        else {
            isRunning = true
            runBtn.setTitle("Stop", for: .normal)
            coordinates = []
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func serializeLocations() -> String {
        var outString =  "latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy, course, speed,  timestemp\n"
        outString.append("double  , double   , double  , double            , double          , double, double, double(seconds from 1970)\n\n")
        
        for l in coordinates {
            outString.append("\(l.coordinate.latitude), ")
            outString.append("\(l.coordinate.longitude), ")
            outString.append("\(l.altitude), ")
            outString.append("\(l.horizontalAccuracy), ")
            outString.append("\(l.verticalAccuracy), ")
            outString.append("\(l.course), ")
            outString.append("\(l.speed), ")
            outString.append("\(l.timestamp), \n")
        }
        
        return outString;
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let str = serializeLocations()
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["sergeyorekhovm@gmail.com"])
            mail.setMessageBody("<p>Hi this is a GPS track</p>", isHTML: true)
            mail.addAttachmentData(str.data(using: .utf8)!, mimeType: "text/plain", fileName: "gpstrack.so")
            /*mail.addAttachmentData(try Data(contentsOf: file, options: [.alwaysMapped , .uncached ]), mimeType: "text/plain", fileName: name)*/
            present(mail, animated: true)
        } else {
            showAlert("Unable to send an email.")
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

