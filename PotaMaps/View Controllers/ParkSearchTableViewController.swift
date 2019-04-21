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

class ParkSearchTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var parkData = ParkData()
    var parkList: [PotaParks] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.dataSource = self
    }

    private func failedToGetParkData() {
        // This is what I call a "KD5JGD moment"!
        print("Failed to get park data!")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }

        let destination = segue.destination as! ParkDetailView
        let park = parkList[indexPath.row]
        destination.selectedPark = park
    }

}

extension ParkSearchTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }

        parkList = parkData.searchParks(with: searchText)!

        searchBar.resignFirstResponder()
        tableView.reloadData()
    }

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

}

extension ParkSearchTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parkList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCell", for: indexPath) as! ParkTableViewCell

        let park = parkList[indexPath.row]

        cell.referenceLabel.text = park.reference
        cell.nameLabel.text = park.name
        cell.parkTypeLabel.text = park.parktypeDesc

        return cell
    }

}
