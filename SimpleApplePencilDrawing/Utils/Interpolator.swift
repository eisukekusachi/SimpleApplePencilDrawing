//
//  Interpolator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

enum Interpolator {

    static func getCubicCurvePoints(
        movePoint: CGPoint,
        controlPoint1: CGPoint,
        controlPoint2: CGPoint,
        endPoint: CGPoint,
        duration: Int,
        shouldIncludeEndPoint: Bool
    ) -> [CGPoint] {

        var result: [CGPoint] = []

        var t: Float = 0.0
        let step: Float = 1.0 / Float(duration)

        for _ in 0 ..< duration {
            let moveX = movePoint.x * CGFloat(powf(1.0 - t, 3.0))
            let control1X = controlPoint1.x * CGFloat(3.0 * t * powf(1.0 - t, 2.0))
            let control2X = controlPoint2.x * CGFloat(3.0 * (1.0 - t) * powf(t, 2.0))
            let endX = endPoint.x * CGFloat(powf(t, 3))

            let moveY = movePoint.y * CGFloat(powf(1.0 - t, 3.0))
            let control1Y = controlPoint1.y * CGFloat(3.0 * t * powf(1.0 - t, 2.0))
            let control2Y = controlPoint2.y * CGFloat(3.0 * (1.0 - t) * powf(t, 2.0))
            let endY = endPoint.y * CGFloat(powf(t, 3.0))

            result.append(
                .init(
                    x: moveX + control1X + control2X + endX,
                    y: moveY + control1Y + control2Y + endY
                )
            )

            t += step
        }

        if shouldIncludeEndPoint {
            result.append(endPoint)
        }

        return result
    }

    static func getLinearInterpolationValues(
        begin: CGFloat,
        change: CGFloat,
        duration: Int,
        shouldIncludeEndPoint: Bool
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

        if shouldIncludeEndPoint {
            result.append(change)
        }

        return result
    }

}
