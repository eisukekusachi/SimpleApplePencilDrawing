//
//  Drawing.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/09/22.
//

import Foundation

enum Drawing {
    private static let handleMaxLengthRatio: CGFloat = 0.38

    static func getFirstCurvePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool = false
    ) -> [CGPoint] {

        let cbVector = CGVector(left: pointB, right: pointC)
        let baVector = CGVector(left: pointA, right: pointB)
        let abVector = CGVector(left: pointB, right: pointA)
        let cbaVector = CGVector(dx: cbVector.dx + baVector.dx, dy: cbVector.dy + baVector.dy)

        let adjustValue1 = Calculator.getRadian(cbVector, Calculator.getReversedVector(baVector)) / .pi

        let length1 = Calculator.getLength(baVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp1Vector = Calculator.getResizedVector(cbaVector, length: length1)

        let length0 = Calculator.getLength(abVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp0Vector = Calculator.getResizedVector(abVector, length: length0)

        let cp1 = CGPoint(x: cp1Vector.dx + pointB.x, y: cp1Vector.dy + pointB.y)
        let cp0 = CGPoint(x: cp0Vector.dx + pointA.x, y: cp0Vector.dy + pointA.y)

        let circumference: Int = max(1, Int(
            Calculator.getLength(pointA, to: cp0) +
            Calculator.getLength(cp0, to: cp1) +
            Calculator.getLength(cp1, to: pointB)
        ))
        print(circumference)

        return Interpolator.getCubicCurvePoints(
            movePoint: pointA,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: pointB,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }
    static func getCurvePoints(
        previousPoint: CGPoint,
        startPoint: CGPoint,
        endPoint: CGPoint,
        nextPoint: CGPoint,
        addLastPoint: Bool = false
    ) -> [CGPoint] {

        let abVector = CGVector(left: startPoint, right: previousPoint)
        let bcVector = CGVector(left: endPoint, right: startPoint)
        let cdVector = CGVector(left: nextPoint, right: endPoint)
        let abcVector = CGVector(dx: abVector.dx + bcVector.dx, dy: abVector.dy + bcVector.dy)
        let dcbVector = Calculator.getReversedVector(CGVector(dx: bcVector.dx + cdVector.dx, dy: bcVector.dy + cdVector.dy))

        let adjustValue0 = Calculator.getRadian(abVector, Calculator.getReversedVector(bcVector)) / .pi
        let adjustValue1 = Calculator.getRadian(bcVector, Calculator.getReversedVector(cdVector)) / .pi

        let length0 = Calculator.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp0Vector = Calculator.getResizedVector(abcVector, length: length0)

        let length1 = Calculator.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp1Vector = Calculator.getResizedVector(dcbVector, length: length1)

        let cp0 = CGPoint(x: cp0Vector.dx + startPoint.x, y: cp0Vector.dy + startPoint.y)
        let cp1 = CGPoint(x: cp1Vector.dx + endPoint.x, y: cp1Vector.dy + endPoint.y)

        let circumference = max(1, Int(
            Calculator.getLength(startPoint, to: cp0) +
            Calculator.getLength(cp0, to: cp1) +
            Calculator.getLength(cp1, to: endPoint)
        ))

        return Interpolator.getCubicCurvePoints(
            movePoint: startPoint,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: endPoint,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }
    static func getLastCurvePoints(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool = false
    ) -> [CGPoint] {

        let abVector = CGVector(left: pointB, right: pointA)
        let bcVector = CGVector(left: pointC, right: pointB)
        let cbVector = CGVector(left: pointB, right: pointC)
        let abcVector = CGVector(dx: abVector.dx + bcVector.dx, dy: abVector.dy + bcVector.dy)

        let adjustValue0 = Calculator.getRadian(abVector, Calculator.getReversedVector(bcVector)) / .pi

        let length0 = Calculator.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp0Vector = Calculator.getResizedVector(abcVector, length: length0)

        let length1 = Calculator.getLength(cbVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp1Vector = Calculator.getResizedVector(cbVector, length: length1)

        let cp0 = CGPoint(x: cp0Vector.dx + pointB.x, y: cp0Vector.dy + pointB.y)
        let cp1 = CGPoint(x: cp1Vector.dx + pointC.x, y: cp1Vector.dy + pointC.y)

        let circumference = max(1, Int(
            Calculator.getLength(pointB, to: cp0) +
            Calculator.getLength(cp0, to: cp1) +
            Calculator.getLength(cp1, to: pointC)
        ))

        return Interpolator.getCubicCurvePoints(
            movePoint: pointB,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: pointC,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }

}

private extension CGVector {

    init(left: CGPoint, right: CGPoint) {
        self.init(dx: left.x - right.x, dy: left.y - right.y)
    }

}
