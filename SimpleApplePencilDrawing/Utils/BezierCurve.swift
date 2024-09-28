//
//  BezierCurve.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/09/22.
//

import Foundation

enum BezierCurve {
    /// A value slightly longer than half of half of the line
    private static let handleLengthAdjustmentRatio: CGFloat = 0.38

    static func getFirstCurvePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool
    ) -> [CGPoint] {
        // This is used to reduce the effect of the curve when the angle becomes narrower.
        let approachStraightValue = handleLengthRatioBasedOnRadian(
            pointA: pointA,
            pointB: pointB,
            pointC: pointC
        )
        let handlePoints = getFirstBezierCurveHandlePoints(
            pointA: pointA,
            pointB: pointB,
            pointC: pointC,
            handleLengthRatio: handleLengthAdjustmentRatio * approachStraightValue
        )

        let duration = Int(round(
            Calculator.getTotalLength(points: [pointA, handlePoints.handleA, handlePoints.handleB, pointB])
        ))

        return Interpolator.getCubicCurvePoints(
            movePoint: pointA,
            controlPoint1: handlePoints.handleA,
            controlPoint2: handlePoints.handleB,
            endPoint: pointB,
            duration: max(1, duration),
            addLastPoint: addLastPoint
        )
    }

    static func getCurvePoints(
        previousPoint: CGPoint,
        startPoint: CGPoint,
        endPoint: CGPoint,
        nextPoint: CGPoint,
        addLastPoint: Bool
    ) -> [CGPoint] {
        // They are used to reduce the effect of the curve when the angle becomes narrower.
        let approachStraightValueA = handleLengthRatioBasedOnRadian(
            pointA: previousPoint,
            pointB: startPoint,
            pointC: endPoint
        )
        let approachStraightValueB = handleLengthRatioBasedOnRadian(
            pointA: startPoint,
            pointB: endPoint,
            pointC: nextPoint
        )

        let handlePoints = getBezierCurveHandlePoints(
            previousPoint: previousPoint,
            startPoint: startPoint,
            endPoint: endPoint,
            nextPoint: nextPoint,
            handleLengthRatioA: handleLengthAdjustmentRatio * approachStraightValueA,
            handleLengthRatioB: handleLengthAdjustmentRatio * approachStraightValueB
        )

        let duration = Int(round(
            Calculator.getTotalLength(points: [startPoint, handlePoints.handleA, handlePoints.handleB, endPoint])
        ))

        return Interpolator.getCubicCurvePoints(
            movePoint: startPoint,
            controlPoint1: handlePoints.handleA,
            controlPoint2: handlePoints.handleB,
            endPoint: endPoint,
            duration: max(1, duration),
            addLastPoint: addLastPoint
        )
    }

    static func getLastCurvePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool
    ) -> [CGPoint] {
        // This is used to reduce the effect of the curve when the angle becomes narrower.
        let approachStraightValue = handleLengthRatioBasedOnRadian(
            pointA: pointA,
            pointB: pointB, 
            pointC: pointC
        )
        let handlePoints = getLastBezierCurveHandlePoints(
            pointA: pointA,
            pointB: pointB,
            pointC: pointC,
            handleLengthRatio: handleLengthAdjustmentRatio * approachStraightValue
        )

        let duration = Int(round(
            Calculator.getTotalLength(points: [pointB, handlePoints.handleA, handlePoints.handleB, pointC])
        ))

        return Interpolator.getCubicCurvePoints(
            movePoint: pointB,
            controlPoint1: handlePoints.handleA,
            controlPoint2: handlePoints.handleB,
            endPoint: pointC,
            duration: max(1, duration),
            addLastPoint: addLastPoint
        )
    }

}

extension BezierCurve {
    /// Returns a ratio between 0.0 and 1.0 that represents how the handle shortens as the angle approaches 0.
    static func handleLengthRatioBasedOnRadian(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint
    ) -> CGFloat {
        let vectorAB = CGVector(origin: pointA, to: pointB)
        let vectorBC = CGVector(origin: pointB, to: pointC)

        return max(0.0, min(Calculator.getRadian(vectorAB, Calculator.getReversedVector(vectorBC)) / .pi, 1.0))
    }

    /// A method that returns two handle positions for the Bézier curve used in the first curve
    static func getFirstBezierCurveHandlePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        handleLengthRatio: CGFloat
    ) -> BezierCurveHandlePoints {
        // `handleA` is the handle extending from `pointA`, and `handleB` is the handle extending from `pointB`.
        // The direction of `handleA` from `pointA` aligns with the direction from `pointA` to `pointB`, as the start point does not need to curve.
        // The direction of `handleB` from `pointB` aligns with the direction from `pointC` to `pointA`, allowing for a smooth connection with the next curve.
        // The length of the handle is calculated by multiplying the distance between `pointA` and `pointB` by `handleLengthRatio`.
        let vectorAB = CGVector(origin: pointA, to: pointB)
        let vectorCA = CGVector(origin: pointC, to: pointA)

        let handleLength = Calculator.getLength(vectorAB) * handleLengthRatio

        let handleA = Calculator.getResizedVector(vectorAB, length: handleLength)
        let handleB = Calculator.getResizedVector(vectorCA, length: handleLength)

        return .init(
            handleA: .init(
                x: handleA.dx + pointA.x,
                y: handleA.dy + pointA.y
            ),
            handleB: .init(
                x: handleB.dx + pointB.x,
                y: handleB.dy + pointB.y
            )
        )
    }

    /// A method that returns two handle positions for the Bézier curve used in the last curve
    static func getLastBezierCurveHandlePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        handleLengthRatio: CGFloat
    ) -> BezierCurveHandlePoints {
        // `handleA` is the handle extending from `pointB`, and `handleB` is the handle extending from `pointC`.
        // The direction of `handleA` from `pointB` aligns with the direction from `pointA` to `pointC`, allowing for a smooth connection with the previous curve.
        // The direction of `handleB` from `pointC` aligns with the direction from `pointC` to `pointB`, as the end point does not need to curve.
        // The length of the handle is calculated by multiplying the distance between `pointC` and `pointB` by `handleLengthRatio`.
        let vectorAC = CGVector(origin: pointA, to: pointC)
        let vectorCB = CGVector(origin: pointC, to: pointB)

        let handleLength = Calculator.getLength(vectorCB) * handleLengthRatio

        let handleA = Calculator.getResizedVector(vectorAC, length: handleLength)
        let handleB = Calculator.getResizedVector(vectorCB, length: handleLength)

        return .init(
            handleA: .init(
                x: handleA.dx + pointB.x,
                y: handleA.dy + pointB.y
            ),
            handleB: .init(
                x: handleB.dx + pointC.x,
                y: handleB.dy + pointC.y
            )
        )
    }

    /// A method that returns two handle positions for the Bézier curve.
    static func getBezierCurveHandlePoints(
        previousPoint: CGPoint,
        startPoint: CGPoint,
        endPoint: CGPoint,
        nextPoint: CGPoint,
        handleLengthRatioA: CGFloat,
        handleLengthRatioB: CGFloat
    ) -> BezierCurveHandlePoints {
        // `handleA` is the handle extending from `startPoint`, and `handleB` is the handle extending from `endPoint`.
        // The direction of `handleA` from `startPoint` is aligned with the direction from `previousPoint` to `endPoint`,
        // while the direction of `handleB` from `endPoint` is aligned with the direction from `nextPoint` to `startPoint`.
        // The length of the handles are calculated by multiplying the distance between `startPoint` and `endPoint` by `handleLengthRatio`.
        // These allow for a smooth connection with the curves created by `func getLastBezierCurveHandlePoints` and `func getFirstBezierCurveHandlePoints`.
        let vectorAC = CGVector(origin: previousPoint, to: endPoint)
        let vectorDB = CGVector(origin: nextPoint, to: startPoint)
        let vectorBC = CGVector(origin: startPoint, to: endPoint)

        let handleLengthA = Calculator.getLength(vectorBC) * handleLengthRatioA
        let handleLengthB = Calculator.getLength(vectorBC) * handleLengthRatioB

        let handleA = Calculator.getResizedVector(vectorAC, length: handleLengthA)
        let handleB = Calculator.getResizedVector(vectorDB, length: handleLengthB)

        return .init(
            handleA: .init(
                x: handleA.dx + startPoint.x,
                y: handleA.dy + startPoint.y
            ),
            handleB: .init(
                x: handleB.dx + endPoint.x,
                y: handleB.dy + endPoint.y
            )
        )
    }

}

private extension CGVector {

    init(origin: CGPoint, to destination: CGPoint) {
        self.init(dx: destination.x - origin.x, dy: destination.y - origin.y)
    }

}
