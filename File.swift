//
//  File.swift
//  mapbox-maps-ios
//
//  Created by Mateusz Szlosek on 22/11/2022.
//

import Foundation
import Turf

extension MapboxMap {
    public func point(for coordinate: LocationCoordinate2D) -> CGPoint {
        return self.point(for: coordinate.coordinate2D)
    }
}
