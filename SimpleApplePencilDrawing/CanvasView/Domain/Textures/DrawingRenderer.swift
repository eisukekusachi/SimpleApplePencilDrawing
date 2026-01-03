//
//  DrawingRenderer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/10.
//

import MetalKit

public typealias RealtimeDrawingTexture = MTLTexture

/// A protocol that defines a renderer for realtime stroke drawing.
@MainActor
public protocol DrawingRenderer {

    var displayRealtimeDrawingTexture: Bool { get }

    var diameter: Int { get }

    func setup(renderer: MTLRendering)

    /// Initializes the textures for realtime drawing
    func initializeTextures(textureSize: CGSize)

    /// Sets the frame size. The frame size changes when the screen rotates or the view layout updates.
    func setFrameSize(_ frameSize: CGSize)

    /// Appends stroke points
    func appendStrokePoints(
        strokePoints: [GrayscaleDotPoint],
        touchPhase: TouchPhase
    )

    /// Called during drawing
    func drawStrokePoints(
        baseTexture: MTLTexture?,
        on realtimeDrawingTexture: RealtimeDrawingTexture?,
        with commandBuffer: MTLCommandBuffer
    )

    /// Prepare for the next stroke
    func prepareNextStroke()
}
