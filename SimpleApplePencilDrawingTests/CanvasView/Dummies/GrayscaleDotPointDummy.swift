//
//  GrayscaleDotPointDummy.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/29.
//

import UIKit
@testable import SimpleApplePencilDrawing

extension GrayscaleDotPoint {

    static func generate(
        location: CGPoint = .zero,
        diameter: CGFloat = 0.0,
        brightness: CGFloat = 0.0,
        blurSize: CGFloat = 0.0
    ) -> GrayscaleDotPoint {
        .init(
            location: location,
            diameter: diameter,
            brightness: brightness,
            blurSize: blurSize
        )
    }

}
