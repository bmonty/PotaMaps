//
//  LocationManager.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/10/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Location Service
class LocationService: NSObject {

    /// Internal core location manager
    private lazy var manager: CLLocationManager = {
        $0.delegate = self
        if let value = self.desiredAccuracy { $0.desiredAccuracy = value }
        if let value = self.distanceFilter { $0.distanceFilter = value }
        if let value = self.activityType { $0.activityType = value }
        return $0
    }(CLLocationManager())

    // current location
    var currentLocation: CLLocation?

    // default location manager options
    private let desiredAccuracy: CLLocationAccuracy?
    private let distanceFilter: Double?
    private let activityType: CLActivityType?

    // observers
    private var observations = (
        authorizationDidChange: [UUID : (LocationService, CLAuthorizationStatus) -> Void](),
        locationDidUpdate: [UUID : (LocationService, CLLocation) -> Void]()
    )

    private var isStarted = false

    init(
        withAccuracy desiredAccuracy: CLLocationAccuracy? = nil,
        forDistance distanceFilter: Double? = nil,
        forActivity activityType: CLActivityType? = nil
    ) {
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilter = distanceFilter
        self.activityType = activityType

        super.init()
    }

    func startService(for type: AuthorizationType) {
        switch type {
        case .whenInUse: manager.requestWhenInUseAuthorization()
        case .always: manager.requestAlwaysAuthorization()
        }
    }

}

// MARK: - Public Nested types
extension LocationService {

    /// Permission types to use with location services.
    ///
    /// - `whenInUse`: while the app is in the foreground
    /// - `always`: whenever the app is running
    enum AuthorizationType {
        case whenInUse
        case always
    }

}

// MARK: - Public observer functions
extension LocationService {

    @discardableResult
    func addLocationChangeObserver<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, LocationService, CLLocation) -> Void
    ) -> ObservationToken {
        let id = UUID()

        observations.locationDidUpdate[id] = { [weak self, weak observer] locationService, location in
            guard let observer = observer else {
                self?.observations.locationDidUpdate.removeValue(forKey: id)
                return
            }

            closure(observer, locationService, location)
        }

        return ObservationToken { [weak self] in
            self?.observations.locationDidUpdate.removeValue(forKey: id)
        }
    }

    @discardableResult
    func addAuthorizationChangeObserver<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, LocationService, CLAuthorizationStatus) -> Void
    ) -> ObservationToken {
        let id = UUID()

        observations.authorizationDidChange[id] = { [weak self, weak observer] locationService, authorizationType in
            guard let observer = observer else {
                self?.observations.authorizationDidChange.removeValue(forKey: id)
                return
            }

            closure(observer, locationService, authorizationType)
        }

        return ObservationToken { [weak self] in
            self?.observations.authorizationDidChange.removeValue(forKey: id)
        }
    }

}

// MARK: - CLLocationManagerDelegate functions
extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location
        
        observations.locationDidUpdate.values.forEach { closure in
            closure(self, location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if isAuthorized {
            isStarted = true
            startUpdating()
            manager.requestLocation()

            observations.authorizationDidChange.values.forEach { closure in
                closure(self, status)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

// MARK: - CLLocationManager wrappers
extension LocationService {

    /// A boolean value indicating if location services is authorized.
    var isAuthorized: Bool {
        return CLLocationManager.locationServicesEnabled()
            && [.authorizedAlways, .authorizedWhenInUse].contains(
                CLLocationManager.authorizationStatus())
    }

    /// Determines if location services is enabled and authorized for the specified authorization type.
    func isAuthorized(for type: AuthorizationType) -> Bool {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return (type == .whenInUse && CLLocationManager.authorizationStatus() == .authorizedWhenInUse)
            || (type == .always && CLLocationManager.authorizationStatus() == .authorizedAlways)
    }

    /// Starts the generation of updates that report the user’s current location.
    func startUpdating(enableBackground: Bool = false) {
        manager.allowsBackgroundLocationUpdates = enableBackground
        manager.startUpdatingLocation()
    }

    /// Stops the generation of location updates.
    func stopUpdating() {
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()
    }

}

private extension Dictionary where Key == UUID {

    mutating func insert(_ value: Value) -> UUID {
        let id = UUID()
        self[id] = value
        return id
    }

}

//// MARK: - Single requests
//extension LocationService {
//
//    /// Requests permission to use location services.
//    ///
//    /// - Parameters:
//    ///   - type: Type of permission required, whether in the foreground (.whenInUse) or while running (.always).
//    ///   - startUpdating: Starts the generation of updates that report the user’s current location.
//    ///   - completion: True if the authorization succeeded for the authorization type, false otherwise.
//    func requestAuthorization(for type: AuthorizationType = .whenInUse, startUpdating: Bool = false, completion: ((Bool) -> Void)? = nil) {
//        // Request appropiate authorization before exit
//        defer {
//            switch type {
//            case .whenInUse: manager.requestWhenInUseAuthorization()
//            case .always: manager.requestAlwaysAuthorization()
//            }
//        }
//
//        // Handle authorized and exit
//        guard !isAuthorized(for: type) else {
//            if startUpdating { self.startUpdating() }
//            completion?(true)
//            return
//        }
//
//        if startUpdating {
//            didChangeAuthorizationSingle += { _ in self.startUpdating() }
//        }
//
//        // Handle denied and exit
//        guard CLLocationManager.authorizationStatus() == .notDetermined
//            else { completion?(false); return }
//
//        if let completion = completion {
//            didChangeAuthorizationSingle += completion
//        }
//    }
//
//    /// Request the one-time delivery of the user’s current location.
//    ///
//    /// - Parameter completion: The completion with the location object.
//    func requestLocation(completion: @escaping LocationHandler) {
//        didUpdateLocationsSingle += completion
//        manager.requestLocation()
//    }
//
//}

/// Manages location manager and handles permission requests.
//class LocationManager: NSObject {
//
//    /// Shared instance of the LocationManager.
//    static let sharedInstance: LocationManager = {
//        let instance = LocationManager(NotificationCenter.default)
//        instance.checkLocationServices()
//        return instance
//    }()
//
//    /// Returns true if location services are authorized.
//    var isLocationAuthorized = false
//
//    private let locationManager = CLLocationManager()
//    private let notificationCenter: NotificationCenter
//    private var currentLocation = CLLocation()
//
//    private init(_ notificationCenter: NotificationCenter = .default) {
//        self.notificationCenter = notificationCenter
//
//        super.init()
//    }
//
//    /// Returns the current location or `nil` if location isn't authorized.
//    func getCurrentLocation() -> CLLocation? {
//        if isLocationAuthorized {
//            return currentLocation
//        }
//
//        return nil
//    }
//
//    private func setupLocationManager() {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    }
//
//    private func checkLocationServices() {
//        if CLLocationManager.locationServicesEnabled() {
//            setupLocationManager()
//            checkLocationAuthorization()
//        } else {
//            // show alert letting the user know they have to turn this on.
//        }
//    }
//
//    private func checkLocationAuthorization() {
//        switch CLLocationManager.authorizationStatus() {
//        case .authorizedWhenInUse:
//            isLocationAuthorized = true
//            locationManager.startUpdatingLocation()
//            guard let currentLocation = locationManager.location else { return }
//            self.currentLocation = currentLocation
//            break
//        case .denied:
//            // Show alert instructing them how to turn on permissions
//            break
//        case .notDetermined:
//            locationManager.requestWhenInUseAuthorization()
//            break
//        case .restricted:
//            // Show an alert letting them know location is restricted
//            break
//        case .authorizedAlways:
//            // this permission is not used
//            break
//        }
//    }
//
//}
//
//extension Notification.Name {
//
//    static var locationUpdated: Notification.Name {
//        return .init(rawValue: "LocationManager.locationUpdated")
//    }
//
//}
//
//extension LocationManager: CLLocationManagerDelegate {
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        currentLocation = location
//        notificationCenter.post(name: .locationUpdated, object: nil)
//    }
//
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        checkLocationAuthorization()
//    }
//
//}
