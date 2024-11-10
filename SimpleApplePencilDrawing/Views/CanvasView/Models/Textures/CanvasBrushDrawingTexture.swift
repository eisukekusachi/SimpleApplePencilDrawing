//
//  CanvasBrushDrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
/// This class encapsulates a series of actions for drawing a single line on a texture using a brush
final class CanvasBrushDrawingTexture: CanvasDrawingTexture {
    
    var texture: MTLTexture?

    private var grayscaleTexture: MTLTexture!

    private var temporaryTexture: MTLTexture!

    private var flippedTextureBuffers: MTLTextureBuffers?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    required init() {
        self.flippedTextureBuffers = MTLBuffers.makeTextureBuffers(
            nodes: .flippedTextureNodes,
            with: device
        )
    }

}

extension CanvasBrushDrawingTexture {

    func initTexture(size: CGSize) {
        texture = MTLTextureCreator.makeBlankTexture(size: size, with: device)
        grayscaleTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)

        clearAllTextures()
    }

    /// Renders `selectedTexture` and `drawingTexture`, then render them onto targetTexture
    func renderDrawingTexture(
        withSelectedTexture selectedTexture: MTLTexture?,
        backgroundColor: UIColor,
        onto targetTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let selectedTexture,
            let flippedTextureBuffers,
            let targetTexture
        else { return }

        MTLRenderer.drawTexture(
            texture: selectedTexture,
            buffers: flippedTextureBuffers,
            withBackgroundColor: backgroundColor,
            on: targetTexture,
            with: commandBuffer
        )

        MTLRenderer.merge(
            texture: texture,
            into: targetTexture,
            with: commandBuffer
        )
    }

    func mergeDrawingTexture(
        into destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let destinationTexture else { return }

        MTLRenderer.merge(
            texture: texture,
            into: destinationTexture,
            with: commandBuffer
        )

        clearAllTextures(with: commandBuffer)
    }

    func clearAllTextures() {
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        clearAllTextures(with: commandBuffer)
        commandBuffer.commit()
    }

    func clearAllTextures(with commandBuffer: MTLCommandBuffer) {
        MTLRenderer.clear(
            textures: [
                texture,
                grayscaleTexture
            ],
            with: commandBuffer
        )
    }

}

extension CanvasBrushDrawingTexture {
    /// First, draw lines in grayscale on the grayscale texture,
    /// then apply the intensity as transparency to colorize the grayscale texture,
    /// and render the colored grayscale texture onto the drawing texture.
    func drawPointsOnBrushDrawingTexture(
        points: [CanvasGrayscaleDotPoint],
        color: UIColor,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let grayscaleTexture,
            let buffers = MTLBuffers.makeGrayscalePointBuffers(
                grayscaleTexturePoints: points,
                pointsAlpha: color.alpha,
                textureSize: grayscaleTexture.size,
                with: device
            )
        else { return }

        MTLRenderer.drawCurve(
            buffers: buffers,
            onGrayscaleTexture: grayscaleTexture,
            with: commandBuffer
        )

        MTLRenderer.colorize(
            grayscaleTexture: grayscaleTexture,
            color: color.rgb,
            on: texture,
            with: commandBuffer
        )
    }

}
