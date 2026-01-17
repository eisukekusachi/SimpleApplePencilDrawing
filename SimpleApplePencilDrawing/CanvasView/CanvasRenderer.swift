//
//  CanvasRenderer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/06.
//

@preconcurrency import MetalKit

/// Renders textures for display by merging layer textures
@MainActor public final class CanvasRenderer: ObservableObject {

    /// Command buffer for a single frame
    public var currentFrameCommandBuffer: MTLCommandBuffer? {
        displayView.currentFrameCommandBuffer
    }

    public var textureSize: CGSize? {
        canvasTexture?.size
    }

    public var displayTextureSize: CGSize? {
        displayView.displayTexture?.size
    }

    /// Texture that combines the background color and the textures of `unselectedBottomTexture`, `selectedTexture` and `unselectedTopTexture`
    private(set) var canvasTexture: MTLTexture?

    /// Texture of the selected layer
    private(set) var selectedLayerTexture: MTLTexture?

    /// Texture used during drawing
    private(set) var realtimeDrawingTexture: RealtimeDrawingTexture?

    private var frameSize: CGSize = .zero

    private let renderer: MTLRendering

    private let flippedTextureBuffers: MTLTextureBuffers

    /// Background color of the canvas
    private var backgroundColor: UIColor = .white

    /// Base background color of the canvas. this color that appears when the canvas is rotated or moved.
    private var baseBackgroundColor: UIColor = .lightGray

    private var displayView: CanvasDisplayable

    public init(
        renderer: MTLRendering,
        displayView: CanvasDisplayable
    ) {
        guard let buffer = MTLBuffers.makeTextureBuffers(
            nodes: .flippedTextureNodes,
            with: renderer.device
        )
        else {
            fatalError("Failed to create texture buffers.")
        }
        self.renderer = renderer
        self.displayView = displayView
        self.flippedTextureBuffers = buffer
    }

    public func setupTextures(textureSize: CGSize) throws {
        guard
            Int(textureSize.width) >= canvasMinimumTextureLength &&
            Int(textureSize.height) >= canvasMinimumTextureLength
        else {
            let error = NSError(
                title: String(localized: "Error", bundle: .main),
                message: String(
                    localized: "Texture size is below the minimum: \(textureSize.width) \(textureSize.height)",
                    bundle: .main
                )
            )
            Logger.error(error)
            throw error
        }

        guard
            let selectedLayerTexture = makeTexture(textureSize),
            let canvasTexture = makeTexture(textureSize),
            let realtimeDrawingTexture = makeTexture(textureSize)
        else {
            let error = NSError(
                title: String(localized: "Error", bundle: .main),
                message: String(
                    localized: "Failed to create new texture",
                    bundle: .main
                )
            )
            Logger.error(error)
            throw error
        }
        self.selectedLayerTexture = selectedLayerTexture
        self.selectedLayerTexture?.label = "selectedLayerTexture"
        self.canvasTexture = canvasTexture
        self.canvasTexture?.label = "canvasTexture"
        self.realtimeDrawingTexture = realtimeDrawingTexture
        self.realtimeDrawingTexture?.label = "realtimeDrawingTexture"
    }
}

extension CanvasRenderer {

    public func setFrameSize(_ size: CGSize) {
        self.frameSize = size
    }

    func updateSelectedLayerTexture(
        using texture: RealtimeDrawingTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let selectedLayerTexture
        else { return }

        renderer.drawTexture(
            texture: texture,
            buffers: flippedTextureBuffers,
            withBackgroundColor: .clear,
            on: selectedLayerTexture,
            with: commandBuffer
        )
    }

    /// Refreshes the entire screen using textures
    public func composeAndRefreshCanvas(
        useRealtimeDrawingTexture: Bool
    ) {
        guard
            let canvasTexture,
            let selectedLayerTexture,
            let realtimeDrawingTexture,
            let currentFrameCommandBuffer
        else { return }

        renderer.fillColor(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: currentFrameCommandBuffer
        )

        renderer.mergeTexture(
            texture: useRealtimeDrawingTexture ? realtimeDrawingTexture : selectedLayerTexture,
            alpha: 255,
            into: canvasTexture,
            with: currentFrameCommandBuffer
        )

        drawCanvasToDisplay()
    }

    /// Draws `canvasTexture` to the display and requests a screen update
    public func drawCanvasToDisplay() {
        guard
            let displayTexture = displayView.displayTexture,
            let currentFrameCommandBuffer
        else { return }

        renderer.drawTexture(
            texture: canvasTexture,
            frameSize: frameSize,
            backgroundColor: baseBackgroundColor,
            on: displayTexture,
            with: currentFrameCommandBuffer
        )

        displayView.setNeedsDisplay()
    }

    public func clearTextures(
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let canvasTexture else { return }

        renderer.clearTextures(
            textures: [
                selectedLayerTexture,
                canvasTexture,
                realtimeDrawingTexture
            ],
            with: commandBuffer
        )

        renderer.fillColor(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )
    }
}

extension CanvasRenderer {
    private func makeTexture(_ textureSize: CGSize) -> MTLTexture? {
        MTLTextureCreator.makeTexture(
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            with: renderer.device
        )
    }
}
