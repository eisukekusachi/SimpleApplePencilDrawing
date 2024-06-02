//
//  UIColorExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

extension UIColor {

    var alpha: Int {
        var alpha: CGFloat = 0
        getRed(nil, green: nil, blue: nil, alpha: &alpha)

        return Int(alpha * 255)
    }

    var rgb: (Int, Int, Int) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)

        return (Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    var rgba: (Int, Int, Int, Int) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (Int(red * 255), Int(green * 255), Int(blue * 255), Int(alpha * 255))
    }

}
