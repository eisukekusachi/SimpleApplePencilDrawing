//
//  CGPointExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

extension CGPoint {

    func scale(_ sourceSize: CGSize, to destinationSize: CGSize) -> Self {
        let scaleFrameToTexture = ViewSize.getScaleToFit(sourceSize, to: destinationSize)

        return .init(
            x: self.x * scaleFrameToTexture,
            y: self.y * scaleFrameToTexture
        )
    }

    func distance(_ to: CGPoint?) -> CGFloat {
        guard let value = to else { return 0.0 }
        return sqrt(pow(value.x - x, 2) + pow(value.y - y, 2))
    }

}
