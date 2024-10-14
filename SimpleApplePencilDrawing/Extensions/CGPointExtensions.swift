//
//  CGPointExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

extension CGPoint {

    func distance(_ to: CGPoint?) -> CGFloat {
        guard let value = to else { return 0.0 }
        return sqrt(pow(value.x - x, 2) + pow(value.y - y, 2))
    }

    /// Scales the `sourceTextureLocation `by sourceTextureRatio`, and centers the scaled location
    func scaleAndCenter(
        sourceTextureRatio: CGFloat,
        sourceTextureSize: CGSize,
        destinationTextureSize: CGSize
    ) -> Self {
        if sourceTextureSize == destinationTextureSize {
            return self
        }

        let location: CGPoint = .init(
            x: self.x * sourceTextureRatio,
            y: self.y * sourceTextureRatio
        )
        let textureSize: CGSize = .init(
            width: sourceTextureSize.width * sourceTextureRatio,
            height: sourceTextureSize.height * sourceTextureRatio
        )

        return .init(
            x: location.x + (destinationTextureSize.width - textureSize.width) * 0.5,
            y: location.y + (destinationTextureSize.height - textureSize.height) * 0.5
        )
    }

}
