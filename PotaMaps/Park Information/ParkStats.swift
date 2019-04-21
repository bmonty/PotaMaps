//
//  ParkData.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/15/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - ParkStatsError Enum
/// Errors for `ParkStats`.
enum ParkStatsError: Error {
    case DataDownloadError(String)
    case DataParseError(String)
}

// MARK: - ParkActivity Struct
/// Stuct to store information for a park activation.
struct ParkActivity {
    /// the callsign of the activator
    var callsign: String
    /// date of the activation
    var date: Date
    /// the park's reference (i.e. "K-3503")
    var reference: String
    /// the name of the park (i.e. "Government Canyon")
    var name: String
    /// the type of the park (i.e. "State Natural Area")
    var parkTypeDesc: String
    /// the park's location (i.e. "US-TX")
    var locationDesc: String
    /// the total number of QSOs in the activation
    var totalQSO: Int
    /// the number of CW QSOs in the activation
    var cwQSO: Int
    /// the number of data QSOs in the activation
    var dataQSO: Int
    /// the number of phone QSOs in the activation
    var phoneQSO: Int
}

/**
 Provides activation information on a specified park.  The park reference
 (i.e. K-3503) provided in the intiializer is used to get activation
 information from the POTA API.  All park information is stored as an array
 of `ParkActivity` in the `activities` property.

 Use `addParkStatsDownloadedObserver` to get notifications when the API
 call is complete.

 Use `isLoaded` to check if data is available.
 */
// MARK: - Main Class
// TODO: Add caching for this??
class ParkStats: NSObject {

    // MARK: - Properties
    /// POTA park reference for this instance.
    var reference: String

    /// Indicates if data has been loaded from the API.
    var isLoaded: Bool = false
    /// Indicates if data load failed.
    var loadFailed: Bool = false

    /// Array of activities at this park.  Data is available when `isLoaded`
    /// is `true`.
    var activities = [ParkActivity]()

    /// Indicates if this park has been activated (read-only).
    var isActivated: Bool {
        get {
            return activities.count > 0
        }
    }

    /// URL to download park data as json.
    #if DEBUG
    private let parkDataUrl = "https://ckeigvfx4l.execute-api.us-west-2.amazonaws.com/Prod/park/activityhistory/"
    #else
    private let parkDataUrl = "https://fuumou4zcf.execute-api.us-west-2.amazonaws.com/Prod/park/activityhistory/"
    #endif

    /// Dictionary of observers for the `ParkStats` instance.
    private var observations = (
        [UUID: (ParkStats) -> Void]()
    )

    // MARK: - Methods
    /**
     Get Park Statistics for the given reference.

     - parameter parkReference: get info for this park reference (i.e. K-3503)
     */
    init(for parkReference: String) {
        self.reference = parkReference

        super.init()

        getParkStats()
    }

    /// Get park activation information for the park id stored in `reference`.
    private func getParkStats() {
        let url = parkDataUrl + reference
        let utilityQueue = DispatchQueue.global(qos: .utility)

        Alamofire.request(url).responseJSON(queue: utilityQueue) { [weak self] response in
                guard let self = self else { return }

                switch response.result {
                case .success(let value):
                    // convert the data from the API to SwiftyJSON
                    let json = JSON(value)

                    // this is for a park that has no activations
                    if json.count == 0 {
                        self.isLoaded = true
                        self.notifyFetchParkStatsComplete()
                        break
                    }

                    // loop through json records and create ParkActivity structs
                    for (_, activity) in json {
                        if let activeCallsign = activity["activeCallsign"].string,
                           let dateString = activity["qso_date"].string,
                           let reference = activity["reference"].string,
                           let name = activity["name"].string,
                           let parkTypeDesc = activity["parktypeDesc"].string,
                           let locationDesc = activity["locationDesc"].string,
                           let totalQSO = activity["totalQSOs"].int,
                           let cwQSO = activity["qsosCW"].int,
                           let dataQSO = activity["qsosDATA"].int,
                           let phoneQSO = activity["qsosPHONE"].int
                        {
                            // set up to parse the data information
                            let dateFormatter = DateFormatter()
                            dateFormatter.timeStyle = .none
                            dateFormatter.dateFormat = "yyyyMMdd"

                            // if the date is correctly parsed, create the struct
                            if let date = dateFormatter.date(from: dateString) {
                                let activation = ParkActivity(callsign: activeCallsign,
                                                              date: date,
                                                              reference: reference,
                                                              name: name,
                                                              parkTypeDesc: parkTypeDesc,
                                                              locationDesc: locationDesc,
                                                              totalQSO: totalQSO,
                                                              cwQSO: cwQSO,
                                                              dataQSO: dataQSO,
                                                              phoneQSO: phoneQSO)
                                self.activities.append(activation)
                            }
                        }
                    }

                    // sort activations by newest to oldest
                    self.activities.sort(by: { first, second in
                        return first.date > second.date
                    })

                    // update isLoaded and notify observers
                    self.isLoaded = true
                    self.notifyFetchParkStatsComplete()

                    break

                case .failure:
                    self.loadFailed = true
                    self.notifyFetchParkStatsComplete()
                }
        }
    }

    func notifyFetchParkStatsComplete() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.observations.values.forEach { closure in
                closure(self)
            }
        }
    }

}

// MARK: - Observer Functions
extension ParkStats {

    @discardableResult func addParkStatsDownloadedObserver<T: AnyObject> (
        _ observer: T,
        closure: @escaping (T, ParkStats) -> Void
        ) -> ObservationToken {
        let id = UUID()

        observations[id] = { [weak self, weak observer] parkStats in
            guard let observer = observer else {
                self?.observations.removeValue(forKey: id)
                return
            }

            closure(observer, self!)
        }

        return ObservationToken {[weak self] in
            self?.observations.removeValue(forKey: id)
        }
    }

}
