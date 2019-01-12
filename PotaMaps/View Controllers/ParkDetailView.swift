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
    var parkData: ParkStats?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let park = selectedPark else {
            return
        }

        self.title = park.reference
        parkNameLabel.text = park.name
        parkTypeLabel.text = park.parktypeDesc

        let region = MKCoordinateRegion(center: park.coordinate,
                                        latitudinalMeters: 40000,
                                        longitudinalMeters: 40000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(park)

        tableView.dataSource = self

        parkData = ParkStats(for: park.reference!)
        parkData?.delegate = self
    }

    @IBAction func directionsToParkPressed(_ sender: Any) {
        guard let park = selectedPark else { return }

        let placeMark = MKPlacemark(coordinate: park.coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.openInMaps(launchOptions: nil)
    }

}

extension ParkDetailView: ParkDataDelegate {

    func parkDataDidUpdate(_ parkData: ParkStats) {
        tableView.reloadData()
    }

}

extension ParkDetailView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let parkData = parkData else { return 0 }
        guard let data = parkData.data else { return 0 }

        if !parkData.isActivated {
            return 1
        }

        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let parkData = parkData else { return tableView.dequeueReusableCell(withIdentifier: "ParkActivationNoData")! }

        // return "no data" cell if the park has never been activated
        if !parkData.isActivated {
            return tableView.dequeueReusableCell(withIdentifier: "ParkActivationNoData")!
        }

        // return a cell with data
        if let cellData = parkData.data?[indexPath.row] {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParkActivationDetail", for: indexPath) as! ParkActivationDetailCell
            cell.callsignLabel.text = cellData["callsign"] as? String

            if let date = cellData["date"] as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .none
                dateFormatter.dateStyle = .medium
                cell.dateLabel.text = dateFormatter.string(from: date)
            } else {
                cell.dateLabel.text = "Unk"
            }

            if let cwQsos = cellData["cwQso"] as? Int {
                cell.cwQsoLabel.text = String(cwQsos)
            } else {
                cell.cwQsoLabel.text = "Unk"
            }

            if let dataQsos = cellData["dataQso"] as? Int {
                cell.dataQsoLabel.text = String(dataQsos)
            } else {
                cell.dataQsoLabel.text = "Unk"
            }

            if let phoneQsos = cellData["phoneQso"] as? Int {
                cell.phoneQsoLabel.text = String(phoneQsos)
            } else {
                cell.phoneQsoLabel.text = "Unk"
            }

            if let totalQsos = cellData["totalQso"] as? Int {
                cell.totalQsoLabel.text = String(totalQsos)
            } else {
                cell.totalQsoLabel.text = "Unk"
            }

            return cell
        }

        // default is to return the "no data" cell
        return tableView.dequeueReusableCell(withIdentifier: "ParkActivationNoData")!
    }

}
