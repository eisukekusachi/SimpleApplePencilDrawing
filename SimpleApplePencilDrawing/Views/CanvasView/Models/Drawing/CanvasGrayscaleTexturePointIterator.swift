//
//  CanvasGrayscaleCurveIterator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

final class CanvasGrayscaleCurveIterator: Iterator<CanvasGrayscaleDotPoint> {

    typealias T = CanvasGrayscaleDotPoint

}

extension CanvasGrayscaleCurveIterator {
    func makeCurvePoints(
        atEnd: Bool = false
    ) -> [T] {

        var curve: [T] = []

        while let subsequence = next(range: 4) {

            if isFirstProcessing {
                curve.append(
                    contentsOf: makeFirstCurve(
                        previousPoint: array[0],
                        startPoint: array[1],
                        endPoint: array[2]
                    )
                )
            }

            curve.append(
                contentsOf: makeCurve(
                    previousPoint: subsequence[0],
                    startPoint: subsequence[1],
                    endPoint: subsequence[2],
                    nextPoint: subsequence[3]
                )
            )
        }

        if atEnd {
            if index == 0 && array.count >= 3 {
                curve.append(
                    contentsOf: makeFirstCurve(
                        previousPoint: array[0],
                        startPoint: array[1],
                        endPoint: array[2]
                    )
                )
            }

            if array.count >= 3 {

                let index0 = array.count - 3
                let index1 = array.count - 2
                let index2 = array.count - 1

                curve.append(
                    contentsOf: makeLastCurve(
                        startPoint: array[index0],
                        endPoint: array[index1],
                        nextPoint: array[index2]
                    )
                )
            }
        }

        return curve
    }

}

extension CanvasGrayscaleCurveIterator {

    private func makeFirstCurve(
        previousPoint: T,
        startPoint: T,
        endPoint: T
    ) -> [T] {

        var curve: [T] = []

        let locations = Drawing.getFirstCurvePoints(
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

        let locations = Drawing.getCurvePoints(
            previousPoint: previousPoint.location,
            startPoint: startPoint.location,
            endPoint: endPoint.location,
            nextPoint: nextPoint.location
        )

        let duration = locations.count

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.brightness,
            change: startPoint.brightness,
            duration: duration
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: previousPoint.diameter,
            change: startPoint.diameter,
            duration: duration
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

        let locations = Drawing.getLastCurvePoints(
            pointA: startPoint.location,
            pointB: endPoint.location,
            pointC: nextPoint.location,
            addLastPoint: true
        )

        // Since the last value is added with `addLastPoint`, `let duration` should be set to `locations.count` minus 1
        let duration = locations.count - 1
        let addLastPoint = true

        let brightnessArray = Interpolator.getLinearInterpolationValues(
            begin: startPoint.brightness,
            change: endPoint.brightness,
            duration: duration,
            addLastPoint: addLastPoint
        )

        let diameterArray = Interpolator.getLinearInterpolationValues(
            begin: startPoint.diameter,
            change: endPoint.diameter,
            duration: duration,
            addLastPoint: addLastPoint
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
