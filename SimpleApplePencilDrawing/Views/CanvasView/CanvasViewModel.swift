//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

final class CanvasViewModel {
    /// Arrays for handling Apple Pencil input values
    private let pencilDrawingArrays = CanvasPencilDrawingArrays()

    /// Curve points for drawing
    private var drawingCurvePoints: CanvasDrawingCurvePoints = .init()

    /// A texture currently being drawn
    private let drawingTexture: CanvasDrawingTexture = CanvasBrushDrawingTexture()

    /// A texture with lines
    private var currentTexture: MTLTexture?

    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// Output destination for `canvasTexture`
    private var canvasView: CanvasViewProtocol?

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var backgroundColor: UIColor = .white

    private let runDisplayLinkSubject = PassthroughSubject<Bool, Never>()

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
    }

}

extension CanvasViewModel {
    func onViewDidLoad(
        canvasView: CanvasViewProtocol,
        textureSize: CGSize? = nil
    ) {
        self.canvasView = canvasView
    }

    func onViewDidAppear() {
        // Since `func onUpdateRenderTexture` is not called at app launch on iPhone,
        // initialize the canvas here.
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(size: textureSize)
        }

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    func onUpdateRenderTexture() {
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(size: textureSize)
        }

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    func onFingerInputGesture(
        touches: Set<UITouch>,
        view: UIView
    ) {
        guard
            pencilDrawingArrays.estimatedTouchPointArray.isEmpty,
            let canvasTextureSize = canvasTexture?.size
        else { return }

        let touchScreenPoints: [CanvasTouchPoint] = touches.map {
            .init(touch: $0, view: view)
        }

        // Reset the current drawing at the start of drawing
        if touchScreenPoints.currentTouchPhase == .began {
            resetAllInputParameters()
        }

        drawingCurvePoints.setCurrentTouchPhase(touchScreenPoints.currentTouchPhase)

        let textureTouchPoints: [CanvasTouchPoint] = touchScreenPoints.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            .init(
                location: $0.location.scaleAndCenter(
                    sourceTextureRatio: ViewSize.getScaleToFill(view.frame.size, to: canvasTextureSize),
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTextureSize
                ),
                touch: $0
            )
        }

        drawingCurvePoints.appendToIterator(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawingDisplayLink.updateCanvasWithDrawing(
            isCurrentlyDrawing: !drawingCurvePoints.isDrawingFinished
        )
    }

    func onPencilGestureDetected(
        touches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView
    ) {
        // Reset the current drawing
        if touches.contains(where: { $0.phase == .began }) {
            if drawingCurvePoints.isCurrentlyDrawing {
                resetCurrentDrawing()
            }
            resetAllInputParameters()
        }

        event?.allTouches?
            .compactMap { $0.type == .pencil ? $0 : nil }
            .sorted { $0.timestamp < $1.timestamp }
            .forEach { touch in
                event?.coalescedTouches(for: touch)?.forEach { coalescedTouch in
                    pencilDrawingArrays.appendEstimatedValue(
                        .init(touch: coalescedTouch, view: view)
                    )
                }
            }
    }

    func onPencilGestureDetected(
        actualTouches: Set<UITouch>,
        view: UIView
    ) {
        guard let canvasTextureSize = canvasTexture?.size else { return }

        // Combine `actualTouches` with the estimated values to create actual values, and append them to the array
        let actualTouchArray = Array(actualTouches).sorted { $0.timestamp < $1.timestamp }
        actualTouchArray.forEach { actualTouch in
            pencilDrawingArrays.appendActualValueWithEstimatedValue(actualTouch)
        }
        pencilDrawingArrays.appendLastEstimatedValueToActualTouchPointArrayIfProcessCompleted()

        let touchScreenPoints = pencilDrawingArrays.latestActualTouchPoints

        drawingCurvePoints.setCurrentTouchPhase(touchScreenPoints.currentTouchPhase)

        let textureTouchPoints: [CanvasTouchPoint] = touchScreenPoints.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            .init(
                location: $0.location.scaleAndCenter(
                    sourceTextureRatio: ViewSize.getScaleToFill(view.frame.size, to: canvasTextureSize),
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTextureSize
                ),
                touch: $0
            )
        }

        drawingCurvePoints.appendToIterator(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawingDisplayLink.updateCanvasWithDrawing(
            isCurrentlyDrawing: !drawingCurvePoints.isDrawingFinished
        )
    }

    func onTapClearTexture() {
        guard
            let canvasTexture,
            let currentTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        resetAllInputParameters()

        drawingTexture.clearAllTextures(with: commandBuffer)

        MTLRenderer.shared.clearTexture(
            texture: currentTexture,
            with: commandBuffer
        )

        MTLRenderer.shared.fillTexture(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

}

extension CanvasViewModel {

    /// Initializes the textures used for drawing with the same size
    func initCanvas(size: CGSize) {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        drawingTexture.initTexture(size: size)

        currentTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)
        canvasTexture = MTLTextureCreator.makeBlankTexture(size: size, with: device)

        guard let canvasTexture else { return }

        MTLRenderer.shared.fillTexture(
            texture: canvasTexture,
            withRGB: backgroundColor.rgb,
            with: commandBuffer
        )
    }

    /// Clears the line being drawn on the canvas
    private func resetCurrentDrawing() {
        drawingTexture.clearAllTextures()

        canvasView?.resetCommandBuffer()

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func resetAllInputParameters() {
        pencilDrawingArrays.reset()
        drawingCurvePoints.reset()
    }

}

extension CanvasViewModel {

    private func updateCanvasWithDrawing() {
        guard
            let currentTexture,
            let canvasTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        // Draw curve points on `drawingTexture`
        if let curvePoints = drawingCurvePoints.makeDrawingCurvePointsFromIterator() {
            (drawingTexture as? CanvasBrushDrawingTexture)?.drawPointsOnBrushDrawingTexture(
                points: curvePoints,
                color: drawingToolStatus.brushColor,
                with: commandBuffer
            )
        }

        // Draw `currentTexture` and `drawingTexture` onto `canvasTexture`
        drawingTexture.renderDrawingTexture(
            withSelectedTexture: currentTexture,
            backgroundColor: .white,
            onto: canvasTexture,
            with: commandBuffer
        )

        if drawingCurvePoints.isDrawingFinished {
            // Draw `drawingTexture` onto `currentTexture`
            drawingTexture.mergeDrawingTexture(
                into: currentTexture,
                with: commandBuffer
            )

            resetAllInputParameters()
        }

        // Update `canvasView` with `canvasTexture`
        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func updateCanvasWithTexture(
        _ texture: MTLTexture?,
        on canvasView: CanvasViewProtocol?
    ) {
        guard
            let sourceTexture = texture,
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
