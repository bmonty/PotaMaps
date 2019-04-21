//
//  ParkDetailView.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/9/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import UIKit
import MapKit

class ParkDetailView: UIViewController {

    @IBOutlet weak var parkNameLabel: UILabel!
    @IBOutlet weak var parkTypeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!

    var selectedPark: PotaParks?
    var parkStats: ParkStats?
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // get the park data from the segue
        guard let park = selectedPark else { return }

        // set up the header labels
        self.title = park.reference
        parkNameLabel.text = park.name
        parkTypeLabel.text = park.parktypeDesc

        // set up the map
        let region = MKCoordinateRegion(center: park.coordinate,
                                        latitudinalMeters: 40000,
                                        longitudinalMeters: 40000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(park)

        // create the parkStats object and set up the observer
        parkStats = ParkStats(for: park.reference!)
        parkStats?.addParkStatsDownloadedObserver(self, closure: { observer, parkStats in
            observer.tableView.reloadData()
        })

        // set up tableView
        tableView.tableFooterView = UIView()
        tableView.dataSource = self

        // setup load timer
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(cancelDownload), userInfo: nil, repeats: false)
    }

    /// Handles the user pressing the "Get Directions to Park" button.
    @IBAction func directionsToParkPressed(_ sender: Any) {
        guard let park = selectedPark else { return }

        let placeMark = MKPlacemark(coordinate: park.coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.openInMaps(launchOptions: nil)
    }

    /// Handles a timeout for the API load.
    @objc func cancelDownload() {
        parkStats = nil
        tableView.reloadData()
    }

}

extension ParkDetailView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if parkStats isn't available, return 1 so info can be shown
        guard let parkStats = parkStats else { return 1 }

        // return 1, to show the appropriate info cell
        if !parkStats.isActivated || !parkStats.isLoaded {
            return 1
        }

        // data is available, so return the actual number of activations
        return parkStats.activities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // return "no data" cell if parkStats isn't avilable
        guard let parkStats = parkStats else { return tableView.dequeueReusableCell(withIdentifier: "ParkActivationNoData", for: indexPath) }

        // return "data loading" cell if park data is not loaded
        if !parkStats.isLoaded {
            return tableView.dequeueReusableCell(withIdentifier: "ParkActivationLoading", for: indexPath)
        }

        // if code gets here, the park data has been loaded and the timer is no
        // longer required
        timer?.invalidate()

        // return "never activated" cell if the park has never been activated
        if !parkStats.isActivated {
            return tableView.dequeueReusableCell(withIdentifier: "ParkActivationNeverActivated", for: indexPath)
        }

        // return a cell with data
        tableView.separatorStyle = .singleLine
        let cellData = parkStats.activities[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkActivationDetail", for: indexPath) as! ParkActivationDetailCell

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short

        cell.callsignLabel.text = cellData.callsign
        cell.dateLabel.text = dateFormatter.string(from: cellData.date)
        cell.cwQsoLabel.text = "\(cellData.cwQSO)"
        cell.dataQsoLabel.text = "\(cellData.dataQSO)"
        cell.phoneQsoLabel.text = "\(cellData.phoneQSO)"
        cell.totalQsoLabel.text = "\(cellData.totalQSO)"

        return cell
    }

}
