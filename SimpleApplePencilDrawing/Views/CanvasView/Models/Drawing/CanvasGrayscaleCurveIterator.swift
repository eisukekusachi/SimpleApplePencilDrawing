//
//  CanvasGrayscaleCurveIterator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

final class CanvasGrayscaleCurveIterator: Iterator<CanvasGrayscaleDotPoint> {
    typealias T = CanvasGrayscaleDotPoint

    private var isNoFirstCurveDrawn: Bool = true

}

extension CanvasGrayscaleCurveIterator {
    /// Set to true when three elements are added to the array while `isNoFirstCurveDrawn` is true
    var hasArrayThreeElementsButNoFirstCurveDrawn: Bool {
        array.count >= 3 && isNoFirstCurveDrawn
    }

    func setIsNoFirstCurveDrawnToFalse() {
        isNoFirstCurveDrawn = false
    }

}

extension CanvasGrayscaleCurveIterator {

    func getFirstBezierCurvePoints() -> CanvasFirstBezierCurvePoints? {
        guard array.count >= 3 else { return nil }
        return .init(
            previousPoint: array[0],
            startPoint: array[1],
            endPoint: array[2]
        )
    }

    func getIntermediateBezierCurvePointsWithFixedRange4() -> [CanvasIntermediateBezierCurvePoints] {
        var array: [CanvasIntermediateBezierCurvePoints] = []
        while let subsequence = next(range: 4) {
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

    func getLastBezierCurvePoints() -> CanvasLastBezierCurvePoints? {
        guard array.count >= 3 else { return nil }
        return .init(
            previousPoint: array[array.count - 3],
            startPoint: array[array.count - 2],
            endPoint: array[array.count - 1]
        )
    }

}
