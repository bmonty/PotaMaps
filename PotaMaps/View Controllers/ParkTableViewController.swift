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

class ParkTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    private var parksFetchedResultsController: NSFetchedResultsController<PotaParks>?
    private let countryPredicate = NSPredicate(format: "country == %@", "United States of America")

    private var selectedPark: PotaParks?

    private var states = ["AL": "US-AL", "AK": "Alaska", "AZ": "US-AZ", "AR": "US-AR",
                          "CA": "US-CA", "CO": "US-CO", "CT": "US-CT", "DE": "US-DE",
                          "FL": "US-FL", "GA": "US-GA", "HI": "US-HI", "ID": "US-ID",
                          "IL": "US-IL", "IN": "US-IN", "IA": "US-IA", "KS": "US-KS",
                          "KY": "US-KY", "LA": "US-LA", "ME": "US-ME", "MD": "US-MD",
                          "MA": "US-MA", "MI": "US-MI", "MN": "US-MN", "MS": "US-MS",
                          "MO": "US-MO", "MT": "US-MT", "NE": "US-NE", "NV": "US-NV",
                          "NH": "US-NH", "NJ": "US-NJ", "NM": "US-NM", "NY": "US-NY",
                          "NC": "US-NC", "ND": "US-ND", "OH": "US-OH", "OK": "US-OK",
                          "OR": "US-OR", "PA": "US-PA", "RI": "US-RI", "SC": "US-SC",
                          "SD": "US-SD", "TN": "US-TN", "TX": "US-TX", "UT": "US-UT",
                          "VT": "US-VT", "VA": "US-VA", "WA": "US-WA", "WV": "US-WV",
                          "WI": "US-WI", "WY": "US-WY"]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureFetchedResultsController()
    }

    private func configureFetchedResultsController() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let fetchRequest: NSFetchRequest<PotaParks> = PotaParks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "locationName", ascending: true)]
        fetchRequest.predicate = countryPredicate

        parksFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: appDelegate.persistentContainer.viewContext,
                                                              sectionNameKeyPath: "locationName",
                                                              cacheName: nil)

        do {
            try parksFetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }

        let destination = segue.destination as! ParkDetailView
        destination.selectedPark = parksFetchedResultsController?.object(at: indexPath)
    }

}

extension ParkTableViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }

}

extension ParkTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }

        parksFetchedResultsController?.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            countryPredicate,
            NSPredicate(format: "name CONTAINS[c] %@ OR reference CONTAINS[c] %@", searchText, searchText)
            ])

        searchBar.resignFirstResponder()

        do {
            try parksFetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        parksFetchedResultsController?.fetchRequest.predicate = countryPredicate

        searchBar.resignFirstResponder()

        do {
            try parksFetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }

}

extension ParkTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = parksFetchedResultsController?.sections else {
            return 0
        }

        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = parksFetchedResultsController?.sections else {
            return 0
        }

        let rowCount = sections[section].numberOfObjects

        return rowCount
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sections = parksFetchedResultsController?.sections else {
            return "ERROR"
        }

        return sections[section].name
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return parksFetchedResultsController?.sectionIndexTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard let sectionIndex = parksFetchedResultsController?.section(forSectionIndexTitle: title, at: index) else {
            return 0
        }
        return sectionIndex
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParkCell", for: indexPath) as! ParkTableViewCell

        let park = parksFetchedResultsController?.object(at: indexPath)

        cell.referenceLabel.text = park?.reference
        cell.nameLabel.text = park?.name
        cell.parkTypeLabel.text = park?.parktypeDesc

        return cell
    }

}
