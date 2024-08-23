//
//  BrushDrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class BrushDrawingTexture: DrawingTexture {

    var drawingTexture: MTLTexture? {
        _drawingTexture
    }

    private var _drawingTexture: MTLTexture?
    private var grayscaleDrawingTexture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    func initTextures(
        _ textureSize: CGSize
    ) {
        grayscaleDrawingTexture = MTLTextureManager.makeBlankTexture(
            with: device,
            textureSize
        )
        _drawingTexture = MTLTextureManager.makeBlankTexture(
            with: device,
            textureSize
        )
    }

    func drawLineOnDrawingTexture(
        grayscalePointsOnTexture: [GrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let grayscaleDrawingTexture,
            let drawingTexture
        else { return }

        if let buffer = MTLBuffers.makeGrayscalePointBuffers(
            device: device,
            grayscalePointsOnTexture: grayscalePointsOnTexture,
            pointsAlpha: color.alpha,
            textureSize: grayscaleDrawingTexture.size
        ) {
            MTLRenderer.drawPointsWithMaxBlendMode(
                grayscalePointBuffers: buffer,
                on: grayscaleDrawingTexture,
                with: commandBuffer
            )

            MTLRenderer.colorize(
                grayscaleTexture: grayscaleDrawingTexture,
                color: color.rgb,
                on: drawingTexture,
                with: commandBuffer
            )
        }
    }

    func clearDrawingTextures(with commandBuffer: MTLCommandBuffer) {
        MTLRenderer.clear(
            [
                grayscaleDrawingTexture,
                drawingTexture
            ],
            with: commandBuffer
        )
    }

}
