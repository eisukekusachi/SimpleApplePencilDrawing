//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

final class CanvasViewModel {

    var frameSize: CGSize = .zero

    /// Handles input from Apple Pencil
    private let pencilStroke = PencilStroke()

    /// An iterator for real-time drawing
    private let drawingCurveIterator = DrawingCurveIterator()

    /// A texture set for real-time drawing
    private let drawingTextureSet = CanvasDrawingTextureSet()

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var drawingDisplayLink = CanvasDrawingDisplayLink()

    /// A texture with lines
    private var currentTexture: MTLTexture?

    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// Output destination for `canvasTexture`
    private var canvasView: CanvasViewProtocol?

    private var backgroundColor: UIColor = .white

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var cancellables = Set<AnyCancellable>()

    private var renderer: MTLRenderer!

    init(renderer: MTLRenderer = MTLRenderer.shared) {
        self.renderer = renderer

        subscribe()
    }

    private func subscribe() {
        drawingDisplayLink.canvasDrawingPublisher
            .sink { [weak self] in
                self?.updateCanvasWithDrawing()
            }
            .store(in: &cancellables)

        drawingTextureSet.canvasDrawFinishedPublisher
            .sink { [weak self] in
                self?.resetAllInputParameters()
            }
            .store(in: &cancellables)
    }

}

extension CanvasViewModel {
    func onViewDidLoad(
        canvasView: CanvasViewProtocol
    ) {
        self.canvasView = canvasView
    }

    func onUpdateRenderTexture() {
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(size: textureSize)
        }

        updateCanvas()
    }

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

    func onPencilGestureDetected(
        actualTouches: Set<UITouch>,
        view: UIView
    ) {
        pencilStroke.appendActualTouches(
            actualTouches: actualTouches
                .sorted { $0.timestamp < $1.timestamp }
                .map { .init(touch: $0, view: view) }
        )

        let pointArray = pencilStroke.drawingPoints(after: pencilStroke.drawingLineEndPoint)
        pencilStroke.setDrawingLineEndPoint()

        drawCurveOnCanvas(pointArray)
    }

    func onTapClearTexture() {
        clearCanvas()
    }

}

extension CanvasViewModel {

    /// Initializes the textures used for drawing with the same size
    func initCanvas(size: CGSize) {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        drawingTextureSet.initTextures(size)

        currentTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)
        canvasTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)

        guard let canvasTexture else { return }

        renderer.fillTexture(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )
    }

    private func resetAllInputParameters() {
        pencilStroke.reset()
        drawingCurveIterator.reset()
    }

    private func clearCanvas() {
        guard
            let canvasTexture,
            let currentTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        resetAllInputParameters()

        drawingTextureSet.initTextures(canvasTexture.size)

        renderer.clearTexture(
            texture: currentTexture,
            with: commandBuffer
        )

        renderer.fillTexture(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )

        updateCanvas()
    }

}

extension CanvasViewModel {

    private func drawCurveOnCanvas(_ screenTouchPoints: [TouchPoint]) {
        guard
            let textureSize = canvasTexture?.size,
            let drawableSize = canvasView?.renderTexture?.size
        else { return }

        drawingCurveIterator.append(
            points: screenTouchPoints.map {
                .init(
                    touchPoint: $0,
                    textureSize: textureSize,
                    drawableSize: drawableSize,
                    frameSize: frameSize,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            },
            touchPhase: screenTouchPoints.currentTouchPhase
        )

        drawingDisplayLink.updateCanvasWithDrawing(
            isCurrentlyDrawing: drawingCurveIterator.isCurrentlyDrawing
        )
    }

    private func updateCanvasWithDrawing() {
        guard
            let currentTexture,
            let canvasTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        drawingTextureSet.drawCurvePoints(
            drawingCurveIterator: drawingCurveIterator,
            withBackgroundTexture: currentTexture,
            on: canvasTexture,
            with: commandBuffer
        )

        updateCanvas()
    }

    private func updateCanvas() {
        guard
            let sourceTexture = canvasTexture,
            let destinationTexture = canvasView?.renderTexture,
            let sourceTextureBuffers = MTLBuffers.makeTextureBuffers(
                sourceSize: .init(
                    width: sourceTexture.size.width * ViewSize.getScaleToFit(sourceTexture.size, to: destinationTexture.size),
                    height: sourceTexture.size.height * ViewSize.getScaleToFit(sourceTexture.size, to: destinationTexture.size)
                ),
                destinationSize: destinationTexture.size,
                with: device
            ),
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        renderer.drawTexture(
            texture: sourceTexture,
            buffers: sourceTextureBuffers,
            withBackgroundColor: .init(rgb: Constants.blankAreaBackgroundColor),
            on: destinationTexture,
            with: commandBuffer
        )

        canvasView?.setNeedsDisplay()
    }

}
