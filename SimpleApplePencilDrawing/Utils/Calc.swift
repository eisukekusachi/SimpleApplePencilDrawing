//
//  Calc.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

enum Calc {

    static func distance(_ left: CGPoint, to right: CGPoint) -> CGFloat {
        guard left != right else { return 0 }
        return sqrt(pow(right.x - left.x, 2) + pow(right.y - left.y, 2))
    }

    static func getLength(_ vector: CGVector) -> CGFloat {
        sqrt(pow(vector.dx, 2) + pow(vector.dy, 2))
    }
    static func getReversedVector(_ vector: CGVector) -> CGVector {
        .init(dx: vector.dx * -1.0, dy: vector.dy * -1.0)
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

    static func getRadian(_ left: CGVector, _ right: CGVector) -> CGFloat {
        let dotProduct = left.dx * right.dx + left.dy * right.dy
        let divisor: CGFloat = Calc.getLength(left) * Calc.getLength(right)

        return divisor != 0 ? acos(dotProduct / divisor) : 0.0
    }

}
