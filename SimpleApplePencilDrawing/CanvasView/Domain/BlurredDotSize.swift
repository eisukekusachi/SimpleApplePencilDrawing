//
//  BlurredDotSize.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/02/21.
//

import Foundation

struct BlurredDotSize {
    var diameter: Float
    var blurSize: Float = BlurredDotSize.initBlurSize
}

extension BlurredDotSize {

    static let initBlurSize: Float = 1.0

    var diameterIncludingBlurSize: Float {
        return diameter + blurSize * 2
    }

}
