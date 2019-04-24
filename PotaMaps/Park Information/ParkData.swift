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
import SwiftyJSON
import Alamofire

enum ParkDataError: Error {
    case InitError
    case DataDownloadError(String)
    case DataFetchError(String)
    case DataParsingError(String)
}

class ParkData {

    struct SearchBounds {
        var latDelta: Double
        var longDelta: Double
    }

    struct ParkDataProgressMessage {
        var message: String
        var percent: Double?
        var failure: Bool = false

        init(withMessage message: String, done percent: Double) {
            self.message = message
            self.percent = percent
            self.failure = false
        }

        init(withMessage message: String, failure: Bool) {
            self.message = message
            self.percent = nil
            self.failure = failure
        }
    }

    /// URL to download park data as json.
    #if DEBUG
    private let parkDataUrl = "https://ckeigvfx4l.execute-api.us-west-2.amazonaws.com/Prod/park/program"
    #else
    private let parkDataUrl = "https://fuumou4zcf.execute-api.us-west-2.amazonaws.com/Prod/park/program"
    #endif

    private var observations = (
        [UUID: (ParkDataProgressMessage) -> Void]()
    )

    /// Download park data from the POTA API.
    ///
    /// - parameter progress: callback for download progress information
    func downloadParkData(forProgram program: String,
                          withProgress progress: @escaping (ParkDataProgressMessage) -> Void,
                          completion: @escaping (Swift.Result<Bool, ParkDataError>) -> Void) {
        // get the data from the api
        let url = self.parkDataUrl + "/" + program
        getParkDataFromApi(from: url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let filePath):
                // start parsing the data
                self.loadParkData(withFile: filePath) { result in
                    switch result {
                    case .success:
                        // successfully downloaded and parsed data
                        completion(.success(true))
                    case .failure(let error):
                        // failed to parse the data
                        completion(.failure(error))
                    }
                }
                return
            case .failure(let error):
                // failed to download the data
                completion(.failure(error))
            }
        }
    }

    /// Download park data from the AWS Lambda API.
    private func getParkDataFromApi(from url: String,
                                    completion: @escaping (Swift.Result<String, ParkDataError>) -> Void) {
        // temporary file location to store downloaded park data
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentURL.appendingPathComponent("park_data.json")

            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        // make the web request and download park info
        Alamofire.download(url, to: destination)
            .downloadProgress(queue: .main, closure: {[weak self] progress in
                guard let self = self else { return }
                let result = ParkDataProgressMessage(withMessage: "Downloading Park Database...",
                                                     done: progress.fractionCompleted)
                self.sendProgressUpdate(message: result)
            })
            .response { response in
                // check http status code is not 200
                if response.response?.statusCode != 200 {
                    completion(.failure(.DataDownloadError("Error from server")))
                    return
                }

                if response.error == nil, let filePath = response.destinationURL?.path {
                    completion(.success(filePath))
                } else {
                    guard let message = response.error?.localizedDescription else {
                        print("message not available")
                        completion(.failure(.DataDownloadError("message not available")))
                        return
                    }

                    print("Error in data request: \(message)")
                    completion(.failure(.DataDownloadError(message)))
                }
            }
    }

    /// Load park data into CoreData.
    ///
    /// - parameter filePath:
    func loadParkData(withFile filePath: String,
                      completion: @escaping (Swift.Result<Bool, ParkDataError>) -> Void) {
        // get managedobject context from persistent container
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let persistentContainer = appDelegate.persistentContainer
        let context = persistentContainer.viewContext

        // move processing to the utility QOS
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
                let parkJSON = try JSON(data: data)

                let batchSize = 256     // import 256 records at a time
                let count = parkJSON.count

                // determine total number of batches
                var numBatches = count / batchSize
                numBatches += count % batchSize > 0 ? 1 : 0

                for batchNumber in 0 ..< numBatches {
                    // determine range for this batch
                    let batchStart = batchNumber * batchSize
                    let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
                    let range = batchStart..<batchEnd

                    // create a batch for this range
                    let parksBatch = Array(parkJSON)[range]

                    // create new objects for each park record in the batch
                    for (_, park): (String, JSON) in parksBatch {
                        let newPark = PotaParks(context: context)

                        let parkId = park["parkId"].int
                        newPark.reference = park["reference"].string
                        newPark.name = park["name"].string
                        newPark.country = park["entityName"].string
                        newPark.locationDesc = park["locationDesc"].string
                        newPark.locationName = park["locationName"].string
                        newPark.parktypeDesc = park["parktypeDesc"].string

                        if let latitude = park["latitude"].double {
                            newPark.latitude = latitude
                        } else {
                            if parkId != nil {
                                print("parkId = \(parkId!) has no latitude")
                            } else {
                                print("didn't find a latitude and there is no parkId 🤷‍♂️")
                            }
                            continue
                        }

                        if let longitude = park["longitude"].double {
                            newPark.longitude = longitude
                        } else {
                            if parkId != nil {
                                print("parkId = \(parkId!) has no longitude")
                            } else {
                                print("didn't find a longitude and there is no parkId 🤷‍♂️")
                            }
                            continue
                        }
                    }

                    // save and cleanup for next batch
                    if context.hasChanges {
                        try context.save()
                        context.reset()
                    }

                    // report progress
                    let message = ParkDataProgressMessage(withMessage: "Processing Park Data...",
                                                          done: Double(batchNumber) / Double(numBatches))
                    self.sendProgressUpdate(message: message)
                }

                // put completion handler on the main thread
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.DataParsingError(error.localizedDescription)))
                }
            }
        }
    }

    /// Get an array of parks within a specified range of the device's current
    /// location.
    ///
    /// - parameter range: distance in meters
    /// - parameter location: center point of a circular region to find parks within
    func getParks(withinRange range: Double, ofLocation location: CLLocationCoordinate2D) throws -> [PotaParks] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
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

            // refine list of parks for requested range
            let searchRegion = CLCircularRegion(center: location, radius: CLLocationDistance(range), identifier: "parkSearchRadius")
            return initialResult.filter { searchRegion.contains($0.coordinate) }
        } catch {
            throw ParkDataError.DataFetchError(error.localizedDescription)
        }
    }

    /// Search for parks by name.
    ///
    /// - parameter name: the string to search for in park names
    func searchParks(with name: String) -> [PotaParks]? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let fetchRequest: NSFetchRequest<PotaParks> = PotaParks.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (reference CONTAINS %@)", name, name)

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

    /// Send progress update message to observers.
    ///
    /// - parameter message: `ParkDataProgressMessage` to send to observers.
    private func sendProgressUpdate(message: ParkDataProgressMessage) {
        observations.values.forEach { closure in
            closure(message)
        }
    }

}

extension ParkData {

    @discardableResult
    func addParkDataProgressObserver<T: AnyObject> (
    _ observer: T,
    closure: @escaping (ParkDataProgressMessage) -> Void
    ) -> ObservationToken {
        let id = UUID()

        observations[id] = { [weak self, weak observer] message in
            guard let _ = observer else {
                self?.observations.removeValue(forKey: id)
                return
            }

            closure(message)
        }

        return ObservationToken {[weak self] in
            self?.observations.removeValue(forKey: id)
        }
    }

}
