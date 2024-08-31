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
                        endPoint: array[2],
                        addLastPoint: false
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
                        endPoint: array[2],
                        addLastPoint: false
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
                        nextPoint: array[index2],
                        addLastPoint: true
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
        endPoint: T,
        addLastPoint: Bool = false
    ) -> [T] {

        var curve: [T] = []

        let locations = Interpolator.firstCurve(
            pointA: previousPoint.location,
            pointB: startPoint.location,
            pointC: endPoint.location,
            addLastPoint: addLastPoint
        )

        let duration = locations.count

        let brightnessArray = Interpolator.linear(
            begin: previousPoint.brightness,
            change: startPoint.brightness,
            duration: duration
        )

        let diameterArray = Interpolator.linear(
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

    private func makeCurve(
        previousPoint: T,
        startPoint: T,
        endPoint: T,
        nextPoint: T
    ) -> [T] {

        var curve: [T] = []

        let locations = Interpolator.curve(
            previousPoint: previousPoint.location,
            startPoint: startPoint.location,
            endPoint: endPoint.location,
            nextPoint: nextPoint.location
        )

        let duration = locations.count

        let brightnessArray = Interpolator.linear(
            begin: previousPoint.brightness,
            change: startPoint.brightness,
            duration: duration
        )

        let diameterArray = Interpolator.linear(
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
        nextPoint: T,
        addLastPoint: Bool = false
    ) -> [T] {

        var curve: [T] = []

        let locations = Interpolator.lastCurve(
            pointA: startPoint.location,
            pointB: endPoint.location,
            pointC: nextPoint.location,
            addLastPoint: addLastPoint
        )

        let duration = locations.count

        let brightnessArray = Interpolator.linear(
            begin: startPoint.brightness,
            change: endPoint.brightness,
            duration: duration
        )

        let diameterArray = Interpolator.linear(
            begin: startPoint.diameter,
            change: endPoint.diameter,
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

}
