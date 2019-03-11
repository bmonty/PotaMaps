//
//  ParkData.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 1/11/19.
//  Copyright © 2019 Benjamin Montgomery. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation

enum ParkDataErrors: Error {
    case InitError
    case DataFetchError(msg: String)
}

class ParkData {

    struct SearchBounds {
        var latDelta: Double
        var longDelta: Double
    }

    /// Get an array of parks within a specified range of the device's current
    /// location.
    ///
    /// - parameter range: distance in meters
    /// - parameter ofLocation: center point of a circular region to find parks within
    func getParks(withinRange range: Double, ofLocation location: CLLocationCoordinate2D) throws -> [PotaParks] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw ParkDataErrors.InitError
        }
        
        // set initial search bounds
        let searchBounds = calculateSearchDelta(forDistance: range, atLatitude: location.latitude)
        var searchCriteria = [String: Double]()
        searchCriteria["latUpper"] = location.latitude + (searchBounds.latDelta / 2.0)
        searchCriteria["latLower"] = location.latitude - (searchBounds.latDelta / 2.0)
        searchCriteria["longUpper"] = location.longitude + (searchBounds.longDelta / 2.0)
        searchCriteria["longLower"] = location.longitude - (searchBounds.longDelta / 2.0)

        // get initial list of parks from CoreData
        let fetchRequest: NSFetchRequest<PotaParks> = PotaParks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "latitude BETWEEN {%lf, %lf}", searchCriteria["latLower"]!, searchCriteria["latUpper"]!),
            NSPredicate(format: "longitude BETWEEN {%lf, %lf}", searchCriteria["longLower"]!, searchCriteria["longUpper"]!),
        ])

        var initialResult: [PotaParks]
        do {
            initialResult = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            throw ParkDataErrors.DataFetchError(msg: error.localizedDescription)
        }

        // refine list of parks for requested range
        let searchRegion = CLCircularRegion(center: location, radius: CLLocationDistance(range), identifier: "parkSearchRadius")
        return initialResult.filter { searchRegion.contains($0.coordinate) }
    }

    /// Search for parks by name.
    ///
    /// - parameter name: the string to search for in park names
    func searchParks(with name: String) -> [PotaParks]? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let fetchRequest: NSFetchRequest<PotaParks> = PotaParks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)

        var searchResult: [PotaParks]
        do {
            searchResult = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            return nil
        }

        return searchResult
    }

    /**
     Calculate a specified distance in degrees of latitude and longitude.
     - parameter range: distance in meters
     - parameter latitude: the latitude of the location where the delta is calculated
     - returns: a `SearchBounds` struct with distances in degrees
    */
    private func calculateSearchDelta(forDistance distance: Double, atLatitude latitude: Double) -> SearchBounds {
        // get latitude delta
        let latDelta = (distance / 110574.0)

        // get longitude delta
        let longDelta = distance / (abs(cos(latitude)) * 110574.0)

        return SearchBounds(latDelta: latDelta, longDelta: longDelta)
    }

}
