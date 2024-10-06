//
//  CanvasDrawingCurve.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/10/06.
//

import Foundation
/// An enum that defines methods used for curves drawn during drawing
enum CanvasDrawingCurve {

    /// Makes curve points used during drawing from an iterator
    static func makeCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator,
        shouldIncludeLastCurve: Bool
    ) -> [CanvasGrayscaleDotPoint] {
        var array: [CanvasGrayscaleDotPoint] = []

        if iterator.hasArrayThreeElementsButNoFirstCurveDrawn {
            iterator.setIsNoFirstCurveDrawnToFalse()
            array.append(contentsOf: makeFirstCurvePoints(from: iterator))
        }

        array.append(contentsOf: makeIntermediateCurvePoints(from: iterator, shouldIncludeEndPoint: false))

        if shouldIncludeLastCurve {
            array.append(contentsOf: makeLastCurvePoints(from: iterator))
        }

        return array
    }

    /// Makes an array of first curve points from an iterator
    static func makeFirstCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator
    ) -> [CanvasGrayscaleDotPoint] {
        var curve: [CanvasGrayscaleDotPoint] = []

        if iterator.array.count >= 3,
           let points = iterator.getFirstBezierCurvePoints() {

            let bezierCurvePoints = BezierCurve.makeFirstCurvePoints(
                pointA: points.previousPoint.location,
                pointB: points.startPoint.location,
                pointC: points.endPoint.location,
                shouldIncludeEndPoint: false
            )
            curve.append(
                contentsOf: interpolateToMatchPointCount(
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
    static func makeIntermediateCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator,
        shouldIncludeEndPoint: Bool
    ) -> [CanvasGrayscaleDotPoint] {
        var curve: [CanvasGrayscaleDotPoint] = []

        let pointArray = iterator.getIntermediateBezierCurvePointsWithFixedRange4()

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
                contentsOf: interpolateToMatchPointCount(
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
    static func makeLastCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator
    ) -> [CanvasGrayscaleDotPoint] {
        var curve: [CanvasGrayscaleDotPoint] = []

        if iterator.array.count >= 3,
           let points = iterator.getLastBezierCurvePoints() {

            let bezierCurvePoints = BezierCurve.makeLastCurvePoints(
                pointA: points.previousPoint.location,
                pointB: points.startPoint.location,
                pointC: points.endPoint.location,
                shouldIncludeEndPoint: true
            )
            curve.append(
                contentsOf: interpolateToMatchPointCount(
                    targetPoints: bezierCurvePoints,
                    interpolationStart: points.startPoint,
                    interpolationEnd: points.endPoint,
                    shouldIncludeEndPoint: true
                )
            )
        }
        return curve
    }

    /// Interpolates the values to match the number of elements in `targetPoints` array with that of the other elements array
    static func interpolateToMatchPointCount(
        targetPoints: [CGPoint],
        interpolationStart: CanvasGrayscaleDotPoint,
        interpolationEnd: CanvasGrayscaleDotPoint,
        shouldIncludeEndPoint: Bool
    ) -> [CanvasGrayscaleDotPoint] {
        var curve: [CanvasGrayscaleDotPoint] = []

        var numberOfInterpolations = targetPoints.count

        if shouldIncludeEndPoint {
            // Subtract 1 from `numberOfInterpolations` because the last point will be added to the arrays
            numberOfInterpolations = numberOfInterpolations - 1
        }

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: interpolationStart.brightness,
            change: interpolationEnd.brightness,
            duration: numberOfInterpolations,
            shouldIncludeEndPoint: shouldIncludeEndPoint
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: interpolationStart.diameter,
            change: interpolationEnd.diameter,
            duration: numberOfInterpolations,
            shouldIncludeEndPoint: shouldIncludeEndPoint
        )

        let blurArray = Interpolator.getLinearInterpolationValues(
            begin: interpolationStart.blurSize,
            change: interpolationEnd.blurSize,
            duration: numberOfInterpolations,
            shouldIncludeEndPoint: shouldIncludeEndPoint
        )

        for i in 0 ..< targetPoints.count {
            curve.append(
                .init(
                    location: targetPoints[i],
                    diameter: diameterArray[i],
                    brightness: brightnessArray[i],
                    blurSize: blurArray[i]
                )
            )
        }

        return curve
    }

}
