//
//  CanvasGrayscaleCurveIterator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

final class CanvasGrayscaleCurveIterator: Iterator<CanvasGrayscaleDotPoint> {
    typealias T = CanvasGrayscaleDotPoint

    let range: Int = 4

}

extension CanvasGrayscaleCurveIterator {
    func makeCurvePoints(
        atEnd: Bool = false
    ) -> [T] {

        var curve: [T] = []

        if array.count == 3,
           let points = makeFirstBezierCurvePoints() {
            curve.append(contentsOf: makeFirstCurvePoints(points))
        }

        makeBezierCurvePoints().forEach { points in
            curve.append(contentsOf: makeCurvePoints(points))
        }

        if atEnd,
           let points = makeLastBezierCurvePoints() {
            curve.append(contentsOf: makeLastCurvePoints(points))
        }

        return curve
    }

    func makeFirstBezierCurvePoints() -> BezierCurveFirstPoints? {
        guard array.count >= 3 else { return nil }
        return .init(
            previousPoint: array[0],
            startPoint: array[1],
            endPoint: array[2]
        )
    }

    func makeBezierCurvePoints() -> [BezierCurvePoints] {
        var array: [BezierCurvePoints] = []
        while let subsequence = next(range: range) {
            array.append(
                .init(
                    previousPoint: subsequence[0],
                    startPoint: subsequence[1],
                    endPoint: subsequence[2],
                    nextPoint: subsequence[3]
                )
            )
        }
        return array
    }

    func makeLastBezierCurvePoints() -> BezierCurveLastPoints? {
        guard array.count >= 3 else { return nil }
        return .init(
            previousPoint: array[array.count - 3],
            startPoint: array[array.count - 2],
            endPoint: array[array.count - 1]
        )
    }

}

extension CanvasGrayscaleCurveIterator {

    private func makeFirstCurvePoints(_ points: BezierCurveFirstPoints) -> [T] {
        var curve: [T] = []

        let locations = BezierCurve.getFirstCurvePoints(
            pointA: points.previousPoint.location,
            pointB: points.startPoint.location,
            pointC: points.endPoint.location,
            addLastPoint: false
        )

        let duration = locations.count

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: points.previousPoint.brightness,
            change: points.startPoint.brightness,
            duration: duration,
            addLastPoint: false
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: points.previousPoint.diameter,
            change: points.startPoint.diameter,
            duration: duration,
            addLastPoint: false
        )

        for i in 0 ..< locations.count {
            curve.append(
                .init(
                    location: locations[i],
                    diameter: diameterArray[i],
                    brightness: brightnessArray[i]
                )
            )
        }

        return curve
    }

    private func makeCurvePoints(_ points: BezierCurvePoints) -> [T] {
        var curve: [T] = []

        let locations = BezierCurve.getCurvePoints(
            previousPoint: points.previousPoint.location,
            startPoint: points.startPoint.location,
            endPoint: points.endPoint.location,
            nextPoint: points.nextPoint.location,
            addLastPoint: false
        )

        let duration = locations.count

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: points.previousPoint.brightness,
            change: points.startPoint.brightness,
            duration: duration,
            addLastPoint: false
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: points.previousPoint.diameter,
            change: points.startPoint.diameter,
            duration: duration,
            addLastPoint: false
        )

        for i in 0 ..< locations.count {
            curve.append(
                .init(
                    location: locations[i],
                    diameter: diameterArray[i],
                    brightness: brightnessArray[i]
                )
            )
        }

        return curve
    }

    private func makeLastCurvePoints(_ points: BezierCurveLastPoints) -> [T] {
        var curve: [T] = []

        let locations = BezierCurve.getLastCurvePoints(
            pointA: points.previousPoint.location,
            pointB: points.startPoint.location,
            pointC: points.endPoint.location,
            addLastPoint: true
        )

        // `let duration` should be set to `locations.count` minus 1 since the last value is added with `addLastPoint`
        let duration = locations.count - 1

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: points.startPoint.brightness,
            change: points.endPoint.brightness,
            duration: duration,
            addLastPoint: true
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: points.startPoint.diameter,
            change: points.endPoint.diameter,
            duration: duration,
            addLastPoint: true
        )

        for i in 0 ..< locations.count {
            curve.append(
                .init(
                    location: locations[i],
                    diameter: diameterArray[i],
                    brightness: brightnessArray[i]
                )
            )
        }

        return curve
    }

}
