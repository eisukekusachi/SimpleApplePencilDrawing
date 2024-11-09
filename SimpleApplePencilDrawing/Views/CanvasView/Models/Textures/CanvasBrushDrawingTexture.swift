//
//  CanvasBrushDrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
/// A class for drawing with a brush
final class CanvasBrushDrawingTexture: CanvasDrawingTexture {
    /// A texture being drawn
    private (set) var texture: MTLTexture?
    /// A texture drawn in grayscale, with the grayscale converted to brightness later
    private var grayscaleDrawingTexture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

}

extension CanvasBrushDrawingTexture {

    func initTexture(textureSize: CGSize) {
        grayscaleDrawingTexture = MTKTextureUtils.makeBlankTexture(
            size: textureSize,
            with: device
        )
        texture = MTKTextureUtils.makeBlankTexture(
            size: textureSize,
            with: device
        )
    }

    /// Draws the points in grayscale on `grayscaleDrawingTexture` with Max blend mode.
    /// Converts the grayscale to brightness, adds color, and creates `texture`.
    /// This way, overlapping lines won’t darken within a single stroke.
    func drawPointsOnDrawingTexture(
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let grayscaleDrawingTexture,
            let texture
        else { return }

        if let buffer = MTLBuffers.makeGrayscalePointBuffers(
            grayscaleTexturePoints: grayscaleTexturePoints,
            pointsAlpha: color.alpha,
            textureSize: grayscaleDrawingTexture.size,
            with: device
        ) {
            MTLRenderer.drawCurve(
                buffers: buffer,
                onGrayscaleTexture: grayscaleDrawingTexture,
                with: commandBuffer
            )

            MTLRenderer.colorize(
                grayscaleTexture: grayscaleDrawingTexture,
                color: color.rgb,
                on: texture,
                with: commandBuffer
            )
        }
    }

    func clearTexture(with commandBuffer: MTLCommandBuffer) {
        MTLRenderer.clear(
            textures: [
                grayscaleDrawingTexture,
                texture
            ],
            with: commandBuffer
        )
    }

}
