//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

final class CanvasViewModel {

    /// An iterator for managing a grayscale curve
    private var drawingCurvePoints: CanvasDrawingCurvePoints = .init()

    /// A texture currently being drawn
    private let drawingTexture: CanvasDrawingTexture = CanvasBrushDrawingTexture()
    /// A texture with lines
    private var currentTexture: MTLTexture?
    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// Arrays for handling Apple Pencil input values
    private let pencilDrawingArrays = CanvasPencilDrawingArrays()

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var backgroundColor: UIColor = .white

    private var displayLinkForRendering: CADisplayLink?

    private var canvasView: CanvasViewProtocol?

    private let requestingPauseDisplayLink = PassthroughSubject<Bool, Never>()

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var cancellables = Set<AnyCancellable>()

    init() {
        requestingPauseDisplayLink
            .sink { [weak self] isPause in
                self?.displayLinkForRendering?.isPaused = isPause
            }
            .store(in: &cancellables)

        configureDisplayLink()
    }

    func setCanvasView(_ canvasView: CanvasViewProtocol) {
        self.canvasView = canvasView
    }

    private func configureDisplayLink() {
        displayLinkForRendering = CADisplayLink(target: self, selector: #selector(updateCanvasViewWhileDrawing))
        displayLinkForRendering?.add(to: .current, forMode: .common)
        displayLinkForRendering?.isPaused = true
    }

}

extension CanvasViewModel {

    func onViewDidAppear() {

        // Since `func onUpdateRenderTexture` is not called at app launch on iPhone,
        // initialize the canvas here.
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(textureSize: textureSize)
        }

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    func onUpdateRenderTexture() {
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(textureSize: textureSize)
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

        // Reset `drawing` and start the display link when a touch begins
        if touchScreenPoints.currentTouchPhase == .began {
            drawingCurvePoints.reset()
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

        startDisplayLinkToUpdateCanvasView(!drawingCurvePoints.isDrawingFinished)
    }

    func onPencilGestureDetected(
        touches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView
    ) {
        // Reset `drawing` and start the display link when a touch begins
        if touches.contains(where: { $0.phase == .began }) {
            if drawingCurvePoints.isCurrentlyDrawing {
                canvasView?.resetCommandBuffer()
                clearDrawingTexture()
            }
            drawingCurvePoints.reset()
            pencilDrawingArrays.reset()
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

        // Combine `actualTouches` with the estimated values to create actual values, and append them to an array
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

        startDisplayLinkToUpdateCanvasView(!drawingCurvePoints.isDrawingFinished)
    }

    func onTapClearTexture() {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        drawingCurvePoints.reset()

        drawingTexture.clearAllTextures(with: commandBuffer)

        MTLRenderer.clear(
            texture: currentTexture,
            with: commandBuffer
        )

        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: commandBuffer
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(textureSize: CGSize) {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        drawingTexture.initTexture(size: textureSize)

        currentTexture = MTKTextureUtils.makeBlankTexture(size: textureSize, with: device)
        canvasTexture = MTKTextureUtils.makeBlankTexture(size: textureSize, with: device)

        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: commandBuffer
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func clearDrawingTexture() {
        // Clear `drawingTextures` during drawing
        drawingTexture.clearAllTextures()

        canvasView?.resetCommandBuffer()

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func startDisplayLinkToUpdateCanvasView(_ isStarted: Bool) {
        requestingPauseDisplayLink.send(!isStarted)

        // Call `requestingUpdateCanvasView` when stopping as the last line isn’t drawn
        if !isStarted {
            updateCanvasViewWhileDrawing()
        }
    }

    @objc private func updateCanvasViewWhileDrawing() {
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
            drawingCurvePoints.reset()
            pencilDrawingArrays.reset()

            // Draw `drawingTexture` onto `currentTexture`
            drawingTexture.mergeDrawingTexture(
                into: currentTexture,
                with: commandBuffer
            )
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

        MTLRenderer.drawTexture(
            texture: sourceTexture,
            buffers: sourceTextureBuffers,
            withBackgroundColor: .init(rgb: Constants.blankAreaBackgroundColor),
            on: destinationTexture,
            with: commandBuffer
        )

        canvasView?.setNeedsDisplay()
    }

}
