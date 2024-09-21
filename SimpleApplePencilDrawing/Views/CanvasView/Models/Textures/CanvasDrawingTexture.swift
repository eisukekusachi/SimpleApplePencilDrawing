//
//  CanvasDrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
/// Manage the currently drawn texture
protocol CanvasDrawingTexture {

    var texture: MTLTexture? { get }

    func initTexture(textureSize: CGSize)

    func drawPointsOnDrawingTexture(
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    )

    func clearTexture(with commandBuffer: MTLCommandBuffer)

    func clearTexture()

}
