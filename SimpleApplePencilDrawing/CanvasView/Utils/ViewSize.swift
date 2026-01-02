//
//  ViewSize.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

enum ViewSize {

    static func getScaleToFit(_ source: CGSize, to destination: CGSize) -> CGFloat {
        let widthRatio = destination.width / source.width
        let heightRatio = destination.height / source.height

        return min(widthRatio, heightRatio)
    }

    static func getScaleToFill(_ source: CGSize, to destination: CGSize) -> CGFloat {
        let widthRatio = destination.width / source.width
        let heightRatio = destination.height / source.height

        return max(widthRatio, heightRatio)
    }

    static func convertScreenLocationToTextureLocation(
        touchLocation: CGPoint,
        frameSize: CGSize,
        drawableSize: CGSize,
        textureSize: CGSize
    ) -> CGPoint {
        if textureSize != drawableSize {
            let drawableToTextureFillScale = ViewSize.getScaleToFill(drawableSize, to: textureSize)
            let drawableLocation: CGPoint = .init(
                x: touchLocation.x * (drawableSize.width / frameSize.width),
                y: touchLocation.y * (drawableSize.width / frameSize.width)
            )
            return .init(
                x: drawableLocation.x * drawableToTextureFillScale + (textureSize.width - drawableSize.width * drawableToTextureFillScale) * 0.5,
                y: drawableLocation.y * drawableToTextureFillScale + (textureSize.height - drawableSize.height * drawableToTextureFillScale) * 0.5
            )
        } else {
            return .init(
                x: touchLocation.x * (textureSize.width / frameSize.width),
                y: touchLocation.y * (textureSize.width / frameSize.width)
            )
        }
    }

}
