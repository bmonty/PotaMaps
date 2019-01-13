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

class ParkData {

    struct SearchBounds {
        var latDelta: Double
        var longDelta: Double
    }

    /// Get an array of parks within a specified range of the device's current
    /// location.
    func getParks(withinRange range: Double, ofLocation currentLocation: CLLocation) -> [PotaParks]? {
        // get initial list of parks from CoreData
        let searchBounds = calculateSearchDelta(forRange: range, atLatitude: currentLocation.coordinate.latitude)
        let fetchRequest: NSFetchRequest<PotaParks> = PotaParks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "locationName", ascending: true)]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "latitude < %@", currentLocation.coordinate.latitude + searchBounds.latDelta),
            NSPredicate(format: "latitude > %@", currentLocation.coordinate.latitude - searchBounds.latDelta),
            NSPredicate(format: "longitude < %@", currentLocation.coordinate.longitude + searchBounds.longDelta),
            NSPredicate(format: "longitude > %@", currentLocation.coordinate.longitude - searchBounds.longDelta)
        ])

        var initialResult: [PotaParks]
        do {
            initialResult = try fetchRequest.execute()
        } catch {
            return nil
        }

        // refine list of parks for requested range
        let searchRegion = CLCircularRegion(center: currentLocation.coordinate, radius: CLLocationDistance(range), identifier: "parkSearchRadius")

        var finalParkList: [PotaParks] = []
        for park in initialResult {
            if searchRegion.contains(park.coordinate) {
                finalParkList.append(park)
            }
        }

        return finalParkList
    }

    private func calculateSearchDelta(forRange range: Double, atLatitude latitude: Double) -> SearchBounds {
        // get latitude delta
        let latDelta = (range / 69)

        // get longitude delta
        let longDelta = range / (abs(cos(latitude)) * 69.172)

        return SearchBounds(latDelta: latDelta, longDelta: longDelta)
    }

}
