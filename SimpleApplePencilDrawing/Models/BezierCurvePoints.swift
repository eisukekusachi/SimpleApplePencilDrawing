//
//  BezierCurvePoints.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/10/05.
//

import Foundation
/// A struct that defines the points needed to create a first Bézier curve
struct BezierCurveFirstPoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
}

/// A struct that defines the points needed to create a Bézier curve
struct BezierCurveIntermediatePoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
    let nextPoint: GrayscaleDotPoint
}

/// A struct that defines the points needed to create a last Bézier curve
struct BezierCurveLastPoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
}
