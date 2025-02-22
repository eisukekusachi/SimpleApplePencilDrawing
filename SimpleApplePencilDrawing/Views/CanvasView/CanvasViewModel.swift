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

    /// A class for handling Apple Pencil inputs
    private let pencilScreenStrokeData = PencilScreenStrokeData()

    /// An iterator for real-time drawing
    private let drawingCurveIterator = DrawingCurveIterator()

    /// A texture currently being drawn
    private let drawingTexture = CanvasDrawingTexture(renderer: MTLRenderer.shared)

    private let drawingToolStatus = CanvasDrawingToolStatus()

    /// A texture with lines
    private var currentTexture: MTLTexture?

    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// Output destination for `canvasTexture`
    private var canvasView: CanvasViewProtocol?

    private var backgroundColor: UIColor = .white

    private var drawingDisplayLink = CanvasDrawingDisplayLink()

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var cancellables = Set<AnyCancellable>()

    init() {
        subscribe()
    }

    private func subscribe() {
        drawingDisplayLink.canvasDrawingPublisher
            .sink { [weak self] in
                self?.updateCanvasWithDrawing()
            }
            .store(in: &cancellables)

        drawingTexture.canvasDrawFinishedPublisher
            .sink { [weak self] in
                self?.resetAllInputParameters()
            }
            .store(in: &cancellables)
    }

}

extension CanvasViewModel {
    func onViewDidLoad(
        canvasView: CanvasViewProtocol,
        textureSize: CGSize? = nil
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
        pencilScreenStrokeData.setLatestEstimatedTouchPoint(
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
        pencilScreenStrokeData.appendActualTouches(
            actualTouches: actualTouches
                .sorted { $0.timestamp < $1.timestamp }
                .map { TouchPoint(touch: $0, view: view) }
        )

        drawCurveOnCanvas(pencilScreenStrokeData.latestActualTouchPoints)
    }

    func onTapClearTexture() {
        clearCanvas()
    }

}

extension CanvasViewModel {

    /// Initializes the textures used for drawing with the same size
    func initCanvas(size: CGSize) {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        drawingTexture.initTextures(size)

        currentTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)
        canvasTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)

        guard let canvasTexture else { return }

        MTLRenderer.shared.fillTexture(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )
    }

    private func resetAllInputParameters() {
        pencilScreenStrokeData.reset()
        drawingCurveIterator.reset()
    }

    private func clearCanvas() {
        guard
            let canvasTexture,
            let currentTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        resetAllInputParameters()

        drawingTexture.initTextures(canvasTexture.size)

        MTLRenderer.shared.clearTexture(
            texture: currentTexture,
            with: commandBuffer
        )

        MTLRenderer.shared.fillTexture(
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

        drawingTexture.drawCurvePoints(
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

        MTLRenderer.shared.drawTexture(
            texture: sourceTexture,
            buffers: sourceTextureBuffers,
            withBackgroundColor: .init(rgb: Constants.blankAreaBackgroundColor),
            on: destinationTexture,
            with: commandBuffer
        )

        canvasView?.setNeedsDisplay()
    }

}
