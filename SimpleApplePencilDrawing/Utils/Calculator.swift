//
//  Calculator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

enum Calculator {

    static func getCenterPoint(_ pointA: CGPoint, _ pointB: CGPoint) -> CGPoint {
        .init(x: (pointA.x + pointB.x) * 0.5, y: (pointA.y + pointB.y) * 0.5)
    }

    /// Get the total distance by connecting points
    static func getTotalLength(points: CGPoint...) -> CGFloat {
        var totalLength: CGFloat = 0.0
        for i in 0 ..< points.count - 1 {
            totalLength += Calculator.getLength(points[i], to: points[i + 1])
        }
        return totalLength
    }

    static func getLength(_ leftHandSide: CGPoint, to rightHandSide: CGPoint) -> CGFloat {
        sqrt(pow(rightHandSide.x - leftHandSide.x, 2) + pow(rightHandSide.y - leftHandSide.y, 2))
    }
    static func getLength(_ vector: CGVector) -> CGFloat {
        sqrt(pow(vector.dx, 2) + pow(vector.dy, 2))
    }
    static func getReversedVector(_ vector: CGVector) -> CGVector {
        .init(dx: vector.dx * -1.0, dy: vector.dy * -1.0)
    }

    static func getRadian(_ left: CGVector, _ right: CGVector) -> CGFloat {
        let dotProduct = left.dx * right.dx + left.dy * right.dy
        let divisor: CGFloat = Calculator.getLength(left) * Calculator.getLength(right)

        return divisor != 0 ? acos(dotProduct / divisor) : 0.0
    }

    static func getResizedVector(_ vector: CGVector, length: CGFloat) -> CGVector {
        var vector = vector

        if vector.dx == 0 && vector.dy == 0 {
            return vector

        } else if vector.dx == 0 {
            vector.dy = length * (vector.dy / abs(vector.dy))
            return vector

        } else if vector.dy == 0 {
            vector.dx = length * (vector.dx / abs(vector.dx))
            return vector

        } else {
            let proportion = abs(vector.dy / vector.dx)
            let x = sqrt(pow(length, 2) / (1 + pow(proportion, 2)))
            let y = proportion * x
            vector.dx = x * round(vector.dx / abs(vector.dx))
            vector.dy = y * round(vector.dy / abs(vector.dy))
            return vector
        }
    }

}
