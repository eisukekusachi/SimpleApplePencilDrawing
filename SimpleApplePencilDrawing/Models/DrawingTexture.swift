//
//  DrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
/// Manage the currently drawn texture
protocol DrawingTexture {

    var texture: MTLTexture? { get }

    func initTexture(
        _ textureSize: CGSize
    )

    func drawPointsOnTexture(
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    )

    func clearTexture(with commandBuffer: MTLCommandBuffer)

}
