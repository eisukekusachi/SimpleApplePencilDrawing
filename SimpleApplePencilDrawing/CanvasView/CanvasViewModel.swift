//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

@MainActor
final class CanvasViewModel {

    /// Frame size, which changes when the screen rotates or the view layout updates
    var frameSize: CGSize = .zero {
        didSet {
            canvasRenderer.setFrameSize(frameSize)
            drawingRenderer?.setFrameSize(frameSize)
        }
    }

    private var isFinishedDrawing: Bool {
        drawingTouchPhase == .ended
    }

    /// Handles input from Apple Pencil
    private let pencilStroke = PencilStroke()

    /// Manages drawing lines onto textures
    private var drawingRenderer: DrawingRenderer?

    /// Manages drawing textures onto the canvas
    private let canvasRenderer: CanvasRenderer

    /// Touch phase for drawing
    private var drawingTouchPhase: UITouch.Phase?

    /// Display link for real-time drawing
    private var drawingDisplayLink = DrawingDisplayLink()

    private var cancellables = Set<AnyCancellable>()

    init(
        canvasRenderer: CanvasRenderer
    ) {
        self.canvasRenderer = canvasRenderer
    }

    func setup(
        drawingRenderer: DrawingRenderer,
        textureSize: CGSize
    ) throws {
        self.bindData()
        self.drawingRenderer = drawingRenderer
        try self.setupCanvas(textureSize: textureSize)
    }

    private func bindData() {
        // The canvas is updated every frame during drawing
        drawingDisplayLink.update
            .sink { [weak self] in
                self?.onDrawingDisplayLinkFrame()
            }
            .store(in: &cancellables)
    }

    /// Sets up textures used for drawing with a consistent size
    private func setupCanvas(textureSize: CGSize) throws {
        try canvasRenderer.setupTextures(textureSize: textureSize)
        drawingRenderer?.setupTextures(textureSize: textureSize)
        drawingRenderer?.prepareNextStroke()
        canvasRenderer.refreshCanvasAfterComposition(
            useRealtimeDrawingTexture: false
        )
    }
}

extension CanvasViewModel {

    /// Processes pencil input using estimated touches
    func onPencilGestureDetected(
        estimatedTouches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView
    ) {
        pencilStroke.setLatestEstimatedTouchPoint(
            estimatedTouches
                .filter({ $0.type == .pencil })
                .sorted(by: { $0.timestamp < $1.timestamp })
                .last
                .map { .init(touch: $0, view: view) }
        )
    }

    /// Processes pencil input using actual touches
    func onPencilGestureDetected(
        actualTouches: Set<UITouch>,
        view: UIView
    ) {
        guard
            let drawingRenderer,
            let textureSize = canvasRenderer.textureSize,
            let displayTextureSize = canvasRenderer.displayTextureSize
        else { return }

        pencilStroke.appendActualTouches(
            actualTouches: actualTouches
                .sorted { $0.timestamp < $1.timestamp }
                .map { .init(touch: $0, view: view) }
        )

        let pointArray = pencilStroke.drawingPoints(after: pencilStroke.drawingLineEndPoint)
        pencilStroke.setDrawingLineEndPoint()

        // Update the touch phase for drawing
        drawingTouchPhase = drawingTouchPhase(pointArray)

        drawingRenderer.appendStrokePoints(
            strokePoints: pointArray.map {
                .init(
                    location: CGAffineTransform.texturePoint(
                        screenPoint: $0.preciseLocation,
                        textureSize: textureSize,
                        drawableSize: displayTextureSize,
                        frameSize: frameSize
                    ),
                    brightness: $0.maximumPossibleForce != 0 ? min($0.force, 1.0) : 1.0,
                    diameter: CGFloat(drawingRenderer.diameter)
                )
            },
            touchPhase: pointArray.currentTouchPhase
        )

        drawingDisplayLink.run(
            isCurrentlyDrawing
        )
    }

    /// Called on every display-link frame while drawing is active
    private func onDrawingDisplayLinkFrame() {
        guard
            let drawingRenderer,
            let selectedLayerTexture = canvasRenderer.selectedLayerTexture,
            let realtimeDrawingTexture = canvasRenderer.realtimeDrawingTexture,
            let currentFrameCommandBuffer = canvasRenderer.currentFrameCommandBuffer
        else { return }

        drawingRenderer.drawStrokePoints(
            baseTexture: selectedLayerTexture,
            on: realtimeDrawingTexture,
            with: currentFrameCommandBuffer
        )

        // The finalization process is performed when drawing is completed
        if isFinishedDrawing {
            canvasRenderer.drawSelectedLayerTexture(
                from: canvasRenderer.realtimeDrawingTexture,
                with: currentFrameCommandBuffer
            )

            currentFrameCommandBuffer.addCompletedHandler { @Sendable _ in
                Task { @MainActor [weak self] in
                    // Reset parameters on drawing completion
                    self?.drawingRenderer?.prepareNextStroke()
                }
            }
        }

        canvasRenderer.refreshCanvasAfterComposition(
            useRealtimeDrawingTexture: !isFinishedDrawing
        )
    }

    func onTapClearTexture() {
        guard let currentFrameCommandBuffer = canvasRenderer.currentFrameCommandBuffer else { return }
        pencilStroke.reset()
        drawingRenderer?.prepareNextStroke()
        canvasRenderer.clearTextures(with: currentFrameCommandBuffer)
        canvasRenderer.drawCanvasToDisplay()
    }

    /// Called when the display texture size changes, such as when the device orientation changes.
    func onUpdateDisplayTexture() {
        canvasRenderer.drawCanvasToDisplay()
    }
}

extension CanvasViewModel {

    /// Touch phase used for drawing
    func drawingTouchPhase(_ points: [TouchPoint]) -> UITouch.Phase? {
        if points.contains(where: { $0.phase == .cancelled }) {
            return .cancelled
        } else if points.contains(where: { $0.phase == .ended }) {
            return .ended
        } else if points.contains(where: { $0.phase == .began }) {
            return .began
        } else if points.contains(where: { $0.phase == .moved }) {
            return .moved
        } else if points.contains(where: { $0.phase == .stationary }) {
            return .stationary
        }
        return nil
    }

    private var isCurrentlyDrawing: Bool {
        switch drawingTouchPhase {
        case .began, .moved: return true
        default: return false
        }
    }
}
