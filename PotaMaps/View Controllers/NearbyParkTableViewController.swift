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
    var parkList: [Int: [PotaParks]] = [:]

    private var locationService: LocationService {
        return AppDelegate.locationManager
    }
    private var locationObservationToken: ObservationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        locationService.addLocationChangeObserver(self) { observer, service, location in
            do {
                let parks = try observer.parkData.getParks(withinRange: 90000.0, ofLocation: location.coordinate)

                // within 5 miles
                var parksWithinFive = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance <= (8047.0)
                }
                parksWithinFive.sort {
                    return observer.sortParkByDistance($0, $1, location)
                }
                observer.parkList[5] = parksWithinFive

                // within 25 miles
                var parksWithinTwentyFive = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance > (8047.0) && distance <= (40234.0)
                }
                parksWithinTwentyFive.sort {
                    return observer.sortParkByDistance($0, $1, location)
                }
                observer.parkList[25] = parksWithinTwentyFive

                // within 50 miles
                var parksWithinFiftyMiles = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance > (40234.0) && distance <= (80468.0)
                }
                parksWithinFiftyMiles.sort {
                    return observer.sortParkByDistance($0, $1, location)
                }
                observer.parkList[50] = parksWithinFiftyMiles

                observer.tableView.reloadData()
            } catch {
                observer.failedToGetParkData()
            }
        }
        locationService.startService(for: .whenInUse)
    }

    private func failedToGetParkData() {
        // This is what I call a "KD5JGD moment"!
        print("Failed to get park data!")
    }

    private func distanceToPark(_ park: PotaParks, from location: CLLocation) -> CLLocationDistance {
        let parkLocation = CLLocation(latitude: park.latitude, longitude: park.longitude)
        return parkLocation.distance(from: location)
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
        let sortedKeys = parkList.keys.sorted()
        let parks = parkList[sortedKeys[indexPath.section]]
        let park = parks?[indexPath.row]
        destination.selectedPark = park
    }

}

extension NearbyParkTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return parkList.keys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = parkList.keys.sorted()
        return parkList[sortedKeys[section]]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sortedKeys = parkList.keys.sorted()
        let distanceString = String(sortedKeys[section])
        return "parks within \(distanceString) miles"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCellWithDistance", for: indexPath) as! ParkTableViewCellWithDistance

        let sortedKeys = parkList.keys.sorted()
        let parks = parkList[sortedKeys[indexPath.section]]
        let park = parks?[indexPath.row]

        cell.referenceLabel.text = park?.reference
        cell.nameLabel.text = park?.name
        cell.parkTypeLabel.text = park?.parktypeDesc

        // set park distance info, if possible
        if let parkLatitude = park?.coordinate.latitude, let parkLongitude = park?.coordinate.longitude {
            if locationService.currentLocation != nil {
                let parkLocation = CLLocation(latitude: parkLatitude, longitude: parkLongitude)
                let distanceInMeters = parkLocation.distance(from: locationService.currentLocation!)
                let distanceInMiles = distanceInMeters / 1609.344

                cell.distanceLabel.text = String(format: "%.2f Mi", distanceInMiles)
                cell.distanceLabel.isHidden = false
            }
        }

        return cell
    }

}
