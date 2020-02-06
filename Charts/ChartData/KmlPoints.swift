//
//  KmlPoints.swift
//  Charts
//
//  Created by aleksey.belousov on 06/02/2020.
//  Copyright © 2020 aleksey.belousov. All rights reserved.
//

import Foundation
import CoreLocation

struct KmlPoint {
  let location: CLLocation
  let alt: Int
  init(_ rawString: String) {
    let components = rawString.split(separator: ",")
    let lon = Double(components[0])!
    let lat = Double(components[1])!
    location = CLLocation(latitude: lat, longitude: lon)
    alt = Int(components[2])!
  }
}

struct ChartPoint {
  let distance: Double
  let altitude: Int
}

struct KmlPoints {
  let points: [ChartPoint]
  init(_ rawString: String) {
    let kmlPoints = rawString.split(separator: " ").map {
      KmlPoint(String($0))
    }

    var result: [ChartPoint] = []
    var lastPoint: KmlPoint? = nil
    var distance: Double = 0
    for kmlPoint in kmlPoints {
      if let p = lastPoint {
        distance += p.location.distance(from: kmlPoint.location)
      }
      result.append(ChartPoint(distance: distance, altitude: kmlPoint.alt))
      lastPoint = kmlPoint
    }
    points = result
  }
}

