//
//  NearbyParkTableViewController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/8/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class NearbyParkTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var parkData = ParkData()
    var parkList = [PotaParks]()
    var distance = 5

    private var locationService: LocationService {
        return AppDelegate.locationManager
    }
    private var locationObservationToken: ObservationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        locationService.addLocationChangeObserver(self) { [unowned self] observer, service, location in
            observer.loadParkData(forNearByParks: location, atDistance: self.distance)
        }
        locationService.startService(for: .whenInUse)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Range", style: .plain, target: self, action: #selector(changeRange))

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(newDataLoaded),
                                               name: .dataLoaded,
                                               object: nil)
    }

    /// Called to handle a notification that new park data is loaded.
    @objc private func newDataLoaded(_ notification: Notification) {
        if locationService.isAuthorized {
            guard let location = locationService.currentLocation else { return }
            loadParkData(forNearByParks: location, atDistance: distance)
        }
    }

    @objc func changeRange() {
        let ac = UIAlertController(title: "Select Range", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "5 miles", style: .default, handler: changeDistance))
        ac.addAction(UIAlertAction(title: "25 miles", style: .default, handler: changeDistance))
        ac.addAction(UIAlertAction(title: "50 miles", style: .default, handler: changeDistance))
        ac.addAction(UIAlertAction(title: "100 miles", style: .default, handler: changeDistance))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(ac, animated: true)
    }

    func changeDistance(action: UIAlertAction) {
        if locationService.isAuthorized {
            guard let location = locationService.currentLocation else { return }

            let distance = String(action.title?.split(separator: " ")[0] ?? "5")
            self.distance = Int(string: distance) ?? 5
            loadParkData(forNearByParks: location, atDistance: self.distance)
        }
    }

    private func failedToGetParkData() {
        // This is what I call a "KD5JGD moment"!
        print("Failed to get park data!")
    }

    private func loadParkData(forNearByParks location: CLLocation, atDistance distance: Int) {
        do {
            let distanceInMeters = Double(distance + 10) * 1609.344
            let parks = try parkData.getParks(withinRange: distanceInMeters, ofLocation: location.coordinate)

            parkList = parks.filter {
                let distance = distanceToPark($0, from: location)
                return distance <= Double(self.distance) * 1609.344
            }

            parkList.sort { [unowned self] in
                let first = self.distanceToPark($0, from: self.locationService.currentLocation!)
                let second = self.distanceToPark($1, from: self.locationService.currentLocation!)
                return first < second
            }

            tableView.reloadData()
        } catch {
            failedToGetParkData()
        }
    }

    private func distanceToPark(_ park: PotaParks, from location: CLLocation) -> CLLocationDistance {
        return CLLocation(latitude: park.latitude, longitude: park.longitude).distance(from: location)
    }

    private func sortParkByDistance(_ first: PotaParks, _ second: PotaParks, _ location: CLLocation) -> Bool {
        let firstDistance = distanceToPark(first, from: location)
        let secondDistance = distanceToPark(second, from: location)
        if firstDistance < secondDistance {
            return true
        } else {
            return false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }

        let destination = segue.destination as! ParkDetailView
        destination.selectedPark = parkList[indexPath.row]
    }

}

extension NearbyParkTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parkList.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "parks within \(distance) miles"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCellWithDistance", for: indexPath) as! ParkTableViewCellWithDistance

        let park = parkList[indexPath.row]

        cell.referenceLabel.text = park.reference
        cell.nameLabel.text = park.name
        cell.parkTypeLabel.text = park.parktypeDesc

        // set park distance info, if possible
        if locationService.currentLocation != nil {
            let parkLocation = CLLocation(latitude: park.coordinate.latitude, longitude: park.coordinate.longitude)
            let distanceInMeters = parkLocation.distance(from: locationService.currentLocation!)
            let distanceInMiles = distanceInMeters / 1609.344

            cell.distanceLabel.text = String(format: "%.2f Mi", distanceInMiles)
            cell.distanceLabel.isHidden = false
        }

        return cell
    }

}
