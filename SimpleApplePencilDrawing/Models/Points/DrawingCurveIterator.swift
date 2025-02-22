//
//  DrawingCurveIterator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import UIKit

/// An iterator for real-time drawing with `UITouch.Phase`
final class DrawingCurveIterator: Iterator<GrayscaleDotPoint> {

    var touchPhase: UITouch.Phase?

    /// Is the drawing finished
    var isDrawingFinished: Bool {
        [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase)
    }

    var isCurrentlyDrawing: Bool {
        !isDrawingFinished
    }

    var shouldDrawFirstCurve: Bool {
        hasNoFirstCurve && self.array.count >= 3
    }

    private var hasNoFirstCurve: Bool = true

    func append(points: [GrayscaleDotPoint], touchPhase: UITouch.Phase) {
        self.append(points)
        self.touchPhase = touchPhase
    }

    func getPoints() -> [GrayscaleDotPoint] {
        var newArray: [GrayscaleDotPoint] = []

        if shouldDrawFirstCurve {
            newArray.append(contentsOf: makeFirstCurvePoints())
            hasNoFirstCurve = false
        }

        newArray.append(contentsOf: makeIntermediateCurvePoints(shouldIncludeEndPoint: false))

        if isDrawingFinished {
            newArray.append(contentsOf: makeLastCurvePoints())
        }

        return newArray
    }

    override func reset() {
        super.reset()
        hasNoFirstCurve = false
        touchPhase = nil
    }

}

extension DrawingCurveIterator {

    /// Makes an array of first curve points from an iterator
    func makeFirstCurvePoints() -> [GrayscaleDotPoint] {
        var curve: [GrayscaleDotPoint] = []

        if self.array.count >= 3,
           let points = getBezierCurveFirstPoints() {

            let bezierCurvePoints = BezierCurve.makeFirstCurvePoints(
                pointA: points.previousPoint.location,
                pointB: points.startPoint.location,
                pointC: points.endPoint.location,
                shouldIncludeEndPoint: false
            )
            curve.append(
                contentsOf: GrayscaleDotPoint.interpolateToMatchPointCount(
                    targetPoints: bezierCurvePoints,
                    interpolationStart: points.previousPoint,
                    interpolationEnd: points.startPoint,
                    shouldIncludeEndPoint: false
                )
            )
        }
        return curve
    }

    /// Makes an array of intermediate curve points from an iterator, setting the range to 4
    func makeIntermediateCurvePoints(
        shouldIncludeEndPoint: Bool
    ) -> [GrayscaleDotPoint] {
        var curve: [GrayscaleDotPoint] = []

        let pointArray = getBezierCurveIntermediatePointsWithFixedRange4()

        pointArray.enumerated().forEach { (index, points) in
            let shouldIncludeEndPoint = index == pointArray.count - 1 ? shouldIncludeEndPoint : false

            let bezierCurvePoints = BezierCurve.makeIntermediateCurvePoints(
                previousPoint: points.previousPoint.location,
                startPoint: points.startPoint.location,
                endPoint: points.endPoint.location,
                nextPoint: points.nextPoint.location,
                shouldIncludeEndPoint: shouldIncludeEndPoint
            )
            curve.append(
                contentsOf: GrayscaleDotPoint.interpolateToMatchPointCount(
                    targetPoints: bezierCurvePoints,
                    interpolationStart: points.startPoint,
                    interpolationEnd: points.endPoint,
                    shouldIncludeEndPoint: shouldIncludeEndPoint
                )
            )
        }
        return curve
    }

    /// Makes an array of last curve points from an iterator
    func makeLastCurvePoints() -> [GrayscaleDotPoint] {
        var curve: [GrayscaleDotPoint] = []

        if self.array.count >= 3,
           let points = getBezierCurveLastPoints() {

            let bezierCurvePoints = BezierCurve.makeLastCurvePoints(
                pointA: points.previousPoint.location,
                pointB: points.startPoint.location,
                pointC: points.endPoint.location,
                shouldIncludeEndPoint: true
            )
            curve.append(
                contentsOf: GrayscaleDotPoint.interpolateToMatchPointCount(
                    targetPoints: bezierCurvePoints,
                    interpolationStart: points.startPoint,
                    interpolationEnd: points.endPoint,
                    shouldIncludeEndPoint: true
                )
            )
        }
        return curve
    }

}
