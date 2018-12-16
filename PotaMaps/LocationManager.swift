//
//  LocationManager.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/10/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import CoreLocation

/// Manages location manager and handles permission requests.
class LocationManager: NSObject {

    private let locationManager = CLLocationManager()

    /// Returns true if location services are authorized.
    var isLocationAuthorized = false

    /// Shared instance of the LocationManager.
    static let sharedInstance: LocationManager = {
        let instance = LocationManager()
        instance.checkLocationServices()
        return instance
    }()

    private var currentLocation = CLLocation()

    func getCurrentLocation() -> CLLocation? {
        if isLocationAuthorized {
            return currentLocation
        }

        return nil
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // show alert letting the user know they have to turn this on.
        }
    }

    private func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            isLocationAuthorized = true
            locationManager.startUpdatingLocation()
            guard let currentLocation = locationManager.location else { return }
            self.currentLocation = currentLocation
            break
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            // Show an alert letting them know location is restricted
            break
        case .authorizedAlways:
            // this permission is not used
            break
        }
    }

}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }

}
