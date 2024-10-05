//
//  CanvasBezierCurvePoints.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/10/05.
//

import Foundation
/// A struct that defines the points needed to create a first Bézier curve
struct CanvasBezierCurveFirstPoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
}

/// A struct that defines the points needed to create a Bézier curve
struct CanvasBezierCurveIntermediatePoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
    let nextPoint: CanvasGrayscaleDotPoint
}

/// A struct that defines the points needed to create a last Bézier curve
struct CanvasBezierCurveLastPoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
}
