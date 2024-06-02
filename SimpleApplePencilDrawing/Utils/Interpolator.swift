//
//  Interpolator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

enum Interpolator {

    private static let handleMaxLengthRatio: CGFloat = 0.38

    static func firstCurve(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool = false
    ) -> [CGPoint] {

        let cbVector = CGVector(left: pointB, right: pointC)
        let baVector = CGVector(left: pointA, right: pointB)
        let abVector = CGVector(left: pointB, right: pointA)
        let cbaVector = CGVector(dx: cbVector.dx + baVector.dx, dy: cbVector.dy + baVector.dy)

        let adjustValue1 = Calc.getRadian(cbVector, Calc.getReversedVector(baVector)) / .pi

        let length1 = Calc.getLength(baVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp1Vector = Calc.getResizedVector(cbaVector, length: length1)

        let length0 = Calc.getLength(abVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp0Vector = Calc.getResizedVector(abVector, length: length0)

        let cp1 = CGPoint(x: cp1Vector.dx + pointB.x, y: cp1Vector.dy + pointB.y)
        let cp0 = CGPoint(x: cp0Vector.dx + pointA.x, y: cp0Vector.dy + pointA.y)

        let circumference: Int = max(1, Int(
            Calc.distance(pointA, to: cp0) +
            Calc.distance(cp0, to: cp1) +
            Calc.distance(cp1, to: pointB)
        ))

        return Interpolator.cubicCurve(
            movePoint: pointA,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: pointB,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }
    static func curve(
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
        let dcbVector = Calc.getReversedVector(CGVector(dx: bcVector.dx + cdVector.dx, dy: bcVector.dy + cdVector.dy))

        let adjustValue0 = Calc.getRadian(abVector, Calc.getReversedVector(bcVector)) / .pi
        let adjustValue1 = Calc.getRadian(bcVector, Calc.getReversedVector(cdVector)) / .pi

        let length0 = Calc.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp0Vector = Calc.getResizedVector(abcVector, length: length0)

        let length1 = Calc.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue1)
        let cp1Vector = Calc.getResizedVector(dcbVector, length: length1)

        let cp0 = CGPoint(x: cp0Vector.dx + startPoint.x, y: cp0Vector.dy + startPoint.y)
        let cp1 = CGPoint(x: cp1Vector.dx + endPoint.x, y: cp1Vector.dy + endPoint.y)

        let circumference = max(1, Int(
            Calc.distance(startPoint, to: cp0) +
            Calc.distance(cp0, to: cp1) +
            Calc.distance(cp1, to: endPoint)
        ))

        return Interpolator.cubicCurve(
            movePoint: startPoint,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: endPoint,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }
    static func lastCurve(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint,
        addLastPoint: Bool = false
    ) -> [CGPoint] {

        let abVector = CGVector(left: pointB, right: pointA)
        let bcVector = CGVector(left: pointC, right: pointB)
        let cbVector = CGVector(left: pointB, right: pointC)
        let abcVector = CGVector(dx: abVector.dx + bcVector.dx, dy: abVector.dy + bcVector.dy)

        let adjustValue0 = Calc.getRadian(abVector, Calc.getReversedVector(bcVector)) / .pi

        let length0 = Calc.getLength(bcVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp0Vector = Calc.getResizedVector(abcVector, length: length0)

        let length1 = Calc.getLength(cbVector) * handleMaxLengthRatio * max(0.0, adjustValue0)
        let cp1Vector = Calc.getResizedVector(cbVector, length: length1)

        let cp0 = CGPoint(x: cp0Vector.dx + pointB.x, y: cp0Vector.dy + pointB.y)
        let cp1 = CGPoint(x: cp1Vector.dx + pointC.x, y: cp1Vector.dy + pointC.y)

        let circumference = max(1, Int(
            Calc.distance(pointB, to: cp0) +
            Calc.distance(cp0, to: cp1) +
            Calc.distance(cp1, to: pointC)
        ))

        return Interpolator.cubicCurve(
            movePoint: pointB,
            controlPoint1: cp0,
            controlPoint2: cp1,
            endPoint: pointC,
            totalPointNum: circumference,
            addLastPoint: addLastPoint
        )
    }

    static func cubicCurve(
        movePoint: CGPoint,
        controlPoint1: CGPoint,
        controlPoint2: CGPoint,
        endPoint: CGPoint,
        totalPointNum: Int,
        addLastPoint: Bool = true
    ) -> [CGPoint] {

        var result: [CGPoint] = []

        var t: Float = 0.0
        let step: Float = 1.0 / Float(totalPointNum)

        for _ in 0 ..< totalPointNum {

            let movex = movePoint.x * CGFloat(powf(1.0 - t, 3.0))
            let control1x = controlPoint1.x * CGFloat(3.0 * t * powf(1.0 - t, 2.0))
            let control2x = controlPoint2.x * CGFloat(3.0 * (1.0 - t) * powf(t, 2.0))
            let endx = endPoint.x * CGFloat(powf(t, 3))

            let movey = movePoint.y * CGFloat(powf(1.0 - t, 3.0))
            let control1y = controlPoint1.y * CGFloat(3.0 * t * powf(1.0 - t, 2.0))
            let control2y = controlPoint2.y * CGFloat(3.0 * (1.0 - t) * powf(t, 2.0))
            let endy = endPoint.y * CGFloat(powf(t, 3.0))

            result.append(
                .init(
                    x: movex + control1x + control2x + endx,
                    y: movey + control1y + control2y + endy
                )
            )

            t += step
        }
        if addLastPoint {
            result.append(endPoint)
        }

        return result
    }

    static func linear(
        begin: CGFloat,
        change: CGFloat,
        duration: Int,
        addLastPoint: Bool = false
    ) -> [CGFloat] {

        var result: [CGFloat] = []

        for t in 0 ..< duration {
            if begin == change {
                result.append(begin)
            } else {
                let difference = (change - begin)
                let normalizedValue = CGFloat(Float(t) / Float(duration))

                result.append(difference * normalizedValue + begin)
            }
        }
        if addLastPoint {
            result.append(change)
        }

        return result
    }

    static func linear(
        begin: UIColor,
        change: UIColor,
        duration: Int,
        addLastPoint: Bool = false
    ) -> [UIColor] {

        var result: [UIColor] = []

        // Extract RGBA components from begin and change colors
        var beginRed: CGFloat = 0
        var beginGreen: CGFloat = 0
        var beginBlue: CGFloat = 0
        var beginAlpha: CGFloat = 0

        var changeRed: CGFloat = 0
        var changeGreen: CGFloat = 0
        var changeBlue: CGFloat = 0
        var changeAlpha: CGFloat = 0

        begin.getRed(&beginRed, green: &beginGreen, blue: &beginBlue, alpha: &beginAlpha)
        change.getRed(&changeRed, green: &changeGreen, blue: &changeBlue, alpha: &changeAlpha)

        for t in 0 ..< duration {
            if begin == change {
                result.append(begin)
            } else {
                let normalizedValue = CGFloat(t) / CGFloat(duration)

                let interpolatedRed = (changeRed - beginRed) * normalizedValue + beginRed
                let interpolatedGreen = (changeGreen - beginGreen) * normalizedValue + beginGreen
                let interpolatedBlue = (changeBlue - beginBlue) * normalizedValue + beginBlue
                let interpolatedAlpha = (changeAlpha - beginAlpha) * normalizedValue + beginAlpha

                let interpolatedColor = UIColor(
                    red: interpolatedRed,
                    green: interpolatedGreen,
                    blue: interpolatedBlue,
                    alpha: interpolatedAlpha
                )

                result.append(interpolatedColor)
            }
        }

        if addLastPoint {
            result.append(change)
        }

        return result
    }

}

private extension CGVector {

    init(left: CGPoint, right: CGPoint) {
        self.init(dx: left.x - right.x, dy: left.y - right.y)
    }

}
