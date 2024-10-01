//
//  BezierCurvePoints.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/09/29.
//

import Foundation

/// A struct that defines the points needed to create a first Bézier curve
struct BezierCurveFirstPoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
}

/// A struct that defines the points needed to create a Bézier curve
struct BezierCurvePoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
    let nextPoint: CanvasGrayscaleDotPoint
}

/// A struct that defines the points needed to create a last Bézier curve
struct BezierCurveLastPoints {
    let previousPoint: CanvasGrayscaleDotPoint
    let startPoint: CanvasGrayscaleDotPoint
    let endPoint: CanvasGrayscaleDotPoint
}
