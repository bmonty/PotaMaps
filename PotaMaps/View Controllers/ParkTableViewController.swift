//
//  ParkTableViewController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/8/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class NearbyParkTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

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
                observer.parkList[5] = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance <= (8047.0)
                }

                // within 25 miles
                observer.parkList[25] = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance > (8047.0) && distance <= (40234.0)
                }

                // within 50 miles
                observer.parkList[50] = parks.filter {
                    let distance = observer.distanceToPark($0, from: location)
                    return distance > (40234.0) && distance <= (80468.0)
                }

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

//extension ParkTableViewController: UISearchBarDelegate {
//
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let searchText = searchBar.text else {
//            return
//        }
//
//        parksFetchedResultsController?.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//            countryPredicate,
//            NSPredicate(format: "name CONTAINS[c] %@ OR reference CONTAINS[c] %@", searchText, searchText)
//            ])
//
//        searchBar.resignFirstResponder()
//
//        do {
//            try parksFetchedResultsController?.performFetch()
//            tableView.reloadData()
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        parksFetchedResultsController?.fetchRequest.predicate = countryPredicate
//
//        searchBar.resignFirstResponder()
//
//        do {
//            try parksFetchedResultsController?.performFetch()
//            tableView.reloadData()
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//
//}

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCell", for: indexPath) as! ParkTableViewCell

        let sortedKeys = parkList.keys.sorted()
        let parks = parkList[sortedKeys[indexPath.section]]
        let park = parks?[indexPath.row]

        cell.referenceLabel.text = park?.reference
        cell.nameLabel.text = park?.name
        cell.parkTypeLabel.text = park?.parktypeDesc

        return cell
    }

}
