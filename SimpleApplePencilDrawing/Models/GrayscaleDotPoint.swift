//
//  GrayscaleDotPoint.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

struct GrayscaleDotPoint: Equatable {

    let location: CGPoint
    let diameter: CGFloat
    let brightness: CGFloat

    let blurSize: CGFloat = 2.0

    init(
        location: CGPoint,
        diameter: CGFloat,
        brightness: CGFloat
    ) {
        self.location = location
        self.diameter = diameter
        self.brightness = brightness
    }

    init(
        touchPoint: TouchPoint,
        diameter: CGFloat
    ) {
        self.location = touchPoint.location
        self.diameter = diameter
        self.brightness = touchPoint.maximumPossibleForce != 0 ? min(touchPoint.force, 1.0) : 1.0
    }

}

extension GrayscaleDotPoint {

    static func average(_ left: Self, _ right: Self) -> Self {
        .init(
            location: left.location == right.location ? left.location : CGPoint(
                x: (left.location.x + right.location.x) * 0.5,
                y: (left.location.y + right.location.y) * 0.5
            ),
            diameter: left.diameter == right.diameter ? left.diameter : (left.diameter + right.diameter) * 0.5,
            brightness: left.brightness == right.brightness ? left.brightness : (left.brightness + right.brightness) * 0.5
        )
    }

}
