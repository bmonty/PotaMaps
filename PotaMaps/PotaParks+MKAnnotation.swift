//
//  PotaParks+MKAnnotation.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/7/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import MapKit

extension PotaParks: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude),
                                      longitude: CLLocationDegrees(longitude))
    }

    public var title: String? {
        return reference
    }

    public var subtitle: String? {
        return name
    }
}
