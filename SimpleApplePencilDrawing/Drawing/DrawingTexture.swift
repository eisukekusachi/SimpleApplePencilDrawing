//
//  DrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

protocol DrawingTexture {

    var drawingTexture: MTLTexture? { get }

    func initTextures(
        _ textureSize: CGSize
    )

    func drawLineOnDrawingTexture(
        grayscalePointsOnTexture: [GrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    )

    func clearDrawingTextures(with commandBuffer: MTLCommandBuffer)

}
