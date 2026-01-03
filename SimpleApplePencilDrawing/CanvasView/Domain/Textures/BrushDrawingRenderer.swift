//
//  BrushDrawingRenderer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/04.
//

import MetalKit

/// A set of textures for realtime brush drawing
@MainActor
public final class BrushDrawingRenderer: DrawingRenderer {
    public var displayRealtimeDrawingTexture: Bool {
        _displayRealtimeDrawingTexture
    }
    private var _displayRealtimeDrawingTexture: Bool = false

    public var diameter: Int {
        _diameter
    }
    private var _diameter: Int = 8

    private var color: UIColor = .black

    private var frameSize: CGSize = .zero

    private var textureSize: CGSize?
    private var drawingTexture: MTLTexture?
    private var grayscaleTexture: MTLTexture?

    private var flippedTextureBuffers: MTLTextureBuffers?

    private var renderer: MTLRendering?

    /// An iterator that manages a single curve being drawn in realtime
    private var drawingCurve: DrawingCurve = DefaultDrawingCurve()

    public init() {}

    public func setup(renderer: MTLRendering) {
        guard let buffers = MTLBuffers.makeTextureBuffers(
            nodes: .flippedTextureNodes,
            with: renderer.device
        ) else {
            let error = NSError(
                title: String(localized: "Error", bundle: .main),
                message: String(
                    localized: "Failed to create buffers",
                    bundle: .main
                )
            )
            Logger.error(error)
            fatalError("Metal is not supported on this device.")
        }
        self.flippedTextureBuffers = buffers
        self.renderer = renderer
    }
}

public extension BrushDrawingRenderer {
    func initializeTextures(textureSize: CGSize) {
        guard
            let device = renderer?.device,
            let newCommandBuffer = renderer?.newCommandBuffer
        else { return }

        self.textureSize = textureSize

        self.drawingTexture = MTLTextureCreator.makeTexture(
            label: "drawingTexture",
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            with: device
        )
        self.grayscaleTexture = MTLTextureCreator.makeTexture(
            label: "grayscaleTexture",
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            with: device
        )

        clearTextures(with: newCommandBuffer)
        newCommandBuffer.commit()
    }

    func setFrameSize(_ frameSize: CGSize) {
        self.frameSize = frameSize
    }

    func setDiameter(_ diameter: Int) {
        self._diameter = diameter
    }

    func setColor(_ color: UIColor) {
        self.color = color
    }

    func appendStrokePoints(
        strokePoints: [GrayscaleDotPoint],
        touchPhase: TouchPhase
    ) {
        drawingCurve.append(
            points: strokePoints,
            touchPhase: touchPhase
        )
    }

    func drawStrokePoints(
        baseTexture: MTLTexture?,
        on realtimeDrawingTexture: RealtimeDrawingTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let renderer,
            let drawingTexture,
            let grayscaleTexture,
            let baseTexture,
            let realtimeDrawingTexture,
            let flippedTextureBuffers,
            let buffers = MTLBuffers.makeGrayscalePointBuffers(
                points: drawingCurve.curvePoints(),
                alpha: color.alpha,
                textureSize: drawingTexture.size,
                with: renderer.device
            )
        else { return }

        renderer.drawGrayPointBuffersWithMaxBlendMode(
            buffers: buffers,
            onGrayscaleTexture: grayscaleTexture,
            with: commandBuffer
        )

        renderer.drawTexture(
            grayscaleTexture: grayscaleTexture,
            color: color.rgb,
            on: drawingTexture,
            with: commandBuffer
        )

        // Rendering to the realtimeTexture starts by overwriting it with the baseTexture,
        // then composites the drawingTexture.
        renderer.drawTexture(
            texture: baseTexture,
            buffers: flippedTextureBuffers,
            withBackgroundColor: .clear,
            on: realtimeDrawingTexture,
            with: commandBuffer
        )

        renderer.mergeTexture(
            texture: drawingTexture,
            into: realtimeDrawingTexture,
            with: commandBuffer
        )

        _displayRealtimeDrawingTexture = true
    }

    func prepareNextStroke() {
        guard
            let newCommandBuffer = renderer?.newCommandBuffer
        else { return }

        clearTextures(with: newCommandBuffer)
        newCommandBuffer.commit()

        drawingCurve.reset()

        _displayRealtimeDrawingTexture = false
    }
}

private extension BrushDrawingRenderer {
    func clearTextures(with commandBuffer: MTLCommandBuffer) {
        renderer?.clearTextures(
            textures: [
                drawingTexture,
                grayscaleTexture
            ],
            with: commandBuffer
        )
    }
}

extension BrushDrawingRenderer {
    static private let minDiameter: Int = 1
    static private let maxDiameter: Int = 64

    static private let initBrushSize: Int = 8

    public static func diameterIntValue(_ value: Float) -> Int {
        Int(value * Float(maxDiameter - minDiameter)) + minDiameter
    }
    public static func diameterFloatValue(_ value: Int) -> Float {
        Float(value - minDiameter) / Float(maxDiameter - minDiameter)
    }
}
