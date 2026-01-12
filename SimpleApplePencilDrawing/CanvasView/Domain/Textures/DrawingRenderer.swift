//
//  DrawingRenderer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/10.
//

import MetalKit

public typealias RealtimeDrawingTexture = MTLTexture

/// A protocol that defines a renderer for realtime stroke drawing
@MainActor
public protocol DrawingRenderer {

    var displayRealtimeDrawingTexture: Bool { get }

    var diameter: Int { get }

    func setup(renderer: MTLRendering)

    /// Sets up textures for realtime drawing
    func setupTextures(textureSize: CGSize)

    /// Sets the frame size. The frame size changes when the screen rotates or the view layout updates.
    func setFrameSize(_ frameSize: CGSize)

    /// Appends stroke points
    func appendStrokePoints(
        strokePoints: [GrayscaleDotPoint],
        touchPhase: TouchPhase
    )

    /// Draws lines onto a texture
    func drawStrokePoints(
        baseTexture: MTLTexture?,
        on realtimeDrawingTexture: RealtimeDrawingTexture?,
        with commandBuffer: MTLCommandBuffer
    )

    /// Prepares for the next stroke
    func prepareNextStroke()
}
