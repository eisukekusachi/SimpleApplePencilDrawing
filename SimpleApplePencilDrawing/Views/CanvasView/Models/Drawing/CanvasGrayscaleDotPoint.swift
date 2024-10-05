//
//  CanvasGrayscaleDotPoint.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

struct CanvasGrayscaleDotPoint: Equatable {

    let location: CGPoint
    let diameter: CGFloat
    let brightness: CGFloat

    var blurSize: CGFloat = 2.0

}

extension CanvasGrayscaleDotPoint {

    init(
        touchPoint: CanvasTouchPoint,
        diameter: CGFloat,
        blurSize: CGFloat = 2.0
    ) {
        self.location = touchPoint.location
        self.diameter = diameter
        self.brightness = touchPoint.maximumPossibleForce != 0 ? min(touchPoint.force, 1.0) : 1.0
        self.blurSize = blurSize
    }

}

extension CanvasGrayscaleDotPoint {
    /// Calculate the average of two values
    static func average(_ left: Self, _ right: Self) -> Self {
        .init(
            location: left.location == right.location ? left.location : CGPoint(
                x: (left.location.x + right.location.x) * 0.5,
                y: (left.location.y + right.location.y) * 0.5
            ),
            diameter: left.diameter == right.diameter ? left.diameter : (left.diameter + right.diameter) * 0.5,
            brightness: left.brightness == right.brightness ? left.brightness : (left.brightness + right.brightness) * 0.5,
            blurSize: left.blurSize == right.blurSize ? left.blurSize : (left.blurSize + right.blurSize) * 0.5
        )
    }

    static func makeCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator,
        shouldIncludeLastCurve: Bool
    ) -> [Self] {
        var array: [Self] = []

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

    /// Make an array of first curve points from an iterator
    static func makeFirstCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator
    ) -> [Self] {
        var curve: [Self] = []

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

    /// Make an array of curve points from an iterator with a range of 4 set
    static func makeIntermediateCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator,
        shouldIncludeEndPoint: Bool
    ) -> [Self] {
        var curve: [Self] = []

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

    /// Make an array of last curve points from an iterator
    static func makeLastCurvePoints(
        from iterator: CanvasGrayscaleCurveIterator
    ) -> [Self] {
        var curve: [Self] = []

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

    /// Interpolate the values to match the number of elements in `targetPoints` array with that of the other elements array
    static func interpolateToMatchPointCount(
        targetPoints: [CGPoint],
        interpolationStart: Self,
        interpolationEnd: Self,
        shouldIncludeEndPoint: Bool
    ) -> [Self] {
        var curve: [Self] = []

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
