//
//  ParkData.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/15/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import Alamofire
import Kanna

protocol ParkDataDelegate: AnyObject {
    func parkDataDidUpdate(_ parkData: ParkStats)
}

class ParkStats: NSObject {

    /// POTA park ID (i.e. K-1234).
    var reference: String
    var data: [[String: Any]]?
    /// Indicates if this park has been activated.
    var isActivated: Bool = false
    var delegate: ParkDataDelegate?

    /// URL for Parks on the Air stats.
    private let statsUrl = "https://stats.parksontheair.com/reports/park-activity-history.php"

    init(for parkReference: String) {
        self.reference = parkReference

        super.init()

        getParkData()
    }

    private func getParkData() {
        let parkId = String(reference.split(separator: "-")[1])
        let parameters: Parameters = ["parkId": parkId]
        let utilityQueue = DispatchQueue.global(qos: .utility)

        Alamofire.request(statsUrl, method: .post, parameters: parameters)
            .validate()
            .responseString(queue: utilityQueue) { [weak self] response in
                guard let self = self else { return }

                switch response.result {
                case .success:
                    if let html = response.result.value {
                        self.parseHtml(html: html)
                    }
                    break
                case .failure(let error):
                    print(error)
                }
        }
    }

    private func parseHtml(html: String) {
        if let doc = try? Kanna.HTML(html: html, encoding: .utf8) {

            var parkActivities: [[String: Any]] = []
            if doc.xpath("//tr").count > 0 {
                for row in doc.xpath("//tr") {
                    var activation = [String: Any]()
                    let data = row.xpath("td")

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd"
                    if let dateString = data[0].content {
                        activation["date"] = dateFormatter.date(from: dateString)
                    }

                    if let totalString = data[1].content {
                        activation["totalQso"] = Int(totalString)
                    }

                    if let cwString = data[2].content {
                        activation["cwQso"] = Int(cwString)
                    }

                    if let dataString = data[3].content {
                        activation["dataQso"] = Int(dataString)
                    }

                    if let phoneString = data[4].content {
                        activation["phoneQso"] = Int(phoneString)
                    }

                    if let callString = data[5].content {
                        activation["callsign"] = callString
                    }

                    parkActivities.append(activation)
                }

                isActivated = true
            }

            self.data = parkActivities

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.parkDataDidUpdate(self)
            }
        }
    }

}
