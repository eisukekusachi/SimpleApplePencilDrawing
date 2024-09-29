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
           let points = makeFirstCurvePoints(array) {
            curve.append(
                contentsOf: makeFirstCurve(
                    previousPoint: points.0,
                    startPoint: points.1,
                    endPoint: points.2
                )
            )
        }

        while let subsequence = next(range: range) {
            curve.append(
                contentsOf: makeCurve(
                    previousPoint: subsequence[0],
                    startPoint: subsequence[1],
                    endPoint: subsequence[2],
                    nextPoint: subsequence[3]
                )
            )
        }

        if atEnd,
           let points = makeLastCurvePoints(array) {
            curve.append(
                contentsOf: makeLastCurve(
                    startPoint: points.0,
                    endPoint: points.1,
                    nextPoint: points.2
                )
            )
        }

        return curve
    }

    func makeFirstCurvePoints(_ array: [T]) -> (T, T, T)? {
        guard array.count >= 3 else { return nil }

        return (
            array[0],
            array[1],
            array[2]
        )
    }

    func makeLastCurvePoints(_ array: [T]) -> (T, T, T)? {
        guard array.count >= 3 else { return nil }

        return (
            array[array.count - 3],
            array[array.count - 2],
            array[array.count - 1]
        )
    }

}

extension CanvasGrayscaleCurveIterator {

    private func makeFirstCurve(
        previousPoint: T,
        startPoint: T,
        endPoint: T
    ) -> [T] {

        var curve: [T] = []

        let locations = BezierCurve.getFirstCurvePoints(
            pointA: previousPoint.location,
            pointB: startPoint.location,
            pointC: endPoint.location,
            addLastPoint: false
        )

        let duration = locations.count

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.brightness,
            change: startPoint.brightness,
            duration: duration,
            addLastPoint: false
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.diameter,
            change: startPoint.diameter,
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

    private func makeCurve(
        previousPoint: T,
        startPoint: T,
        endPoint: T,
        nextPoint: T
    ) -> [T] {

        var curve: [T] = []

        let locations = BezierCurve.getCurvePoints(
            previousPoint: previousPoint.location,
            startPoint: startPoint.location,
            endPoint: endPoint.location,
            nextPoint: nextPoint.location,
            addLastPoint: false
        )

        let duration = locations.count

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.brightness,
            change: startPoint.brightness,
            duration: duration,
            addLastPoint: false
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.diameter,
            change: startPoint.diameter,
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

    private func makeLastCurve(
        startPoint: T,
        endPoint: T,
        nextPoint: T
    ) -> [T] {

        var curve: [T] = []

        let locations = BezierCurve.getLastCurvePoints(
            pointA: startPoint.location,
            pointB: endPoint.location,
            pointC: nextPoint.location,
            addLastPoint: true
        )

        // `let duration` should be set to `locations.count` minus 1 since the last value is added with `addLastPoint`
        let duration = locations.count - 1

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: startPoint.brightness,
            change: endPoint.brightness,
            duration: duration,
            addLastPoint: true
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: startPoint.diameter,
            change: endPoint.diameter,
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
