//
//  BezierCurvePoints.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/10/05.
//

import Foundation
/// A struct that defines the points needed to create a first Bézier curve
struct CanvasBezierCurveFirstPoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
}

/// A struct that defines the points needed to create a Bézier curve
struct CanvasBezierCurveIntermediatePoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
    let nextPoint: GrayscaleDotPoint
}

/// A struct that defines the points needed to create a last Bézier curve
struct CanvasBezierCurveLastPoints {
    let previousPoint: GrayscaleDotPoint
    let startPoint: GrayscaleDotPoint
    let endPoint: GrayscaleDotPoint
}
