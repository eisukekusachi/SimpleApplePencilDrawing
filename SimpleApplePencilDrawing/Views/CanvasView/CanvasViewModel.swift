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
    private var drawing: CanvasDrawing = .init()

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

    private let requestingUpdateCanvasView = PassthroughSubject<Void, Never>()

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var cancellables = Set<AnyCancellable>()

    init() {
        requestingPauseDisplayLink
            .sink { [weak self] isPause in
                self?.displayLinkForRendering?.isPaused = isPause
            }
            .store(in: &cancellables)

        requestingUpdateCanvasView
            .sink { [weak self] _ in
                self?.canvasView?.setNeedsDisplay()
            }
            .store(in: &cancellables)

        configureDisplayLink()
    }

    func setCanvasView(_ canvasView: CanvasViewProtocol) {
        self.canvasView = canvasView
    }

    private func configureDisplayLink() {
        displayLinkForRendering = CADisplayLink(target: self, selector: #selector(updateCanvasViewWhileDrawing(_:)))
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
            initCanvas(
                textureSize: textureSize
            )
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
            drawing.reset()
            startDisplayLinkToUpdateCanvasView(true)
        }

        drawing.setCurrentTouchPhase(touchScreenPoints.currentTouchPhase)

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

        drawing.appendToIterator(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )
    }

    func onPencilGestureDetected(
        touches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView
    ) {
        // Reset `drawing` and start the display link when a touch begins
        if touches.contains(where: { $0.phase == .began }) {
            if drawing.isCurrentlyDrawing {
                canvasView?.resetCommandBuffer()
                clearDrawingTexture()
            }
            drawing.reset()
            pencilDrawingArrays.reset()

            startDisplayLinkToUpdateCanvasView(true)
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

        drawing.setCurrentTouchPhase(touchScreenPoints.currentTouchPhase)

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

        drawing.appendToIterator(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )
    }

    func onTapClearTexture() {
        guard let newCommandBuffer = device.makeCommandQueue()?.makeCommandBuffer() else { return }

        drawing.reset()
        drawingTexture.clearTexture(with: newCommandBuffer)

        MTLRenderer.clear(
            texture: currentTexture,
            with: newCommandBuffer
        )
        newCommandBuffer.commit()

        clearCanvas()
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(textureSize: CGSize) {
        drawingTexture.initTexture(textureSize: textureSize)

        currentTexture = MTKTextureUtils.makeBlankTexture(
            size: textureSize,
            with: device
        )
        canvasTexture = MTKTextureUtils.makeBlankTexture(
            size: textureSize,
            with: device
        )

        clearCanvas()
    }

    private func clearCanvas() {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: commandBuffer
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func clearDrawingTexture() {
        guard
            let currentTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        // Clear `drawingTextures` during drawing
        drawingTexture.clearTexture(with: commandBuffer)

        mergeTextures(
            currentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: commandBuffer
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)
    }

    private func startDisplayLinkToUpdateCanvasView(_ isStarted: Bool) {
        requestingPauseDisplayLink.send(!isStarted)

        // Call `requestingUpdateCanvasView` when stopping as the last line isn’t drawn
        if !isStarted {
            requestingUpdateCanvasView.send(())
        }
    }

    private func mergeTextures(
        drawingTexture: CanvasDrawingTexture? = nil,
        currentTexture: MTLTexture,
        withBackgroundColor backgroundColor: UIColor,
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer,
        executeDrawingFinishProcess: Bool = false
    ) {
        guard let destinationTexture else { return }

        // Render `currentTexture` and `drawingTexture` onto the `renderTexture`
        MTLRenderer.draw(
            textures: [
                currentTexture,
                drawingTexture?.texture
            ],
            withBackgroundColor: backgroundColor.rgba,
            on: destinationTexture,
            with: commandBuffer
        )

        // When the drawing process completes,
        // render `drawingTexture` onto `currentTexture`,
        // then clear `drawingTexture` for the next drawing.
        if executeDrawingFinishProcess {
            MTLRenderer.merge(
                texture: drawingTexture?.texture,
                into: currentTexture,
                with: commandBuffer
            )
            drawingTexture?.clearTexture(
                with: commandBuffer
            )
        }
    }

    @objc private func updateCanvasViewWhileDrawing(_ displayLink: CADisplayLink) {
        guard
            let currentTexture,
            let canvasTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        if let curvePoints = drawing.makeDrawingCurvePointsFromIterator() {
            drawingTexture.drawPointsOnDrawingTexture(
                grayscaleTexturePoints: curvePoints,
                color: drawingToolStatus.brushColor,
                with: commandBuffer
            )
        }

        mergeTextures(
            drawingTexture: drawingTexture,
            currentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: commandBuffer,
            executeDrawingFinishProcess: drawing.isDrawingComplete
        )

        updateCanvasWithTexture(canvasTexture, on: canvasView)

        if drawing.isDrawingFinished {
            drawing.reset()
            pencilDrawingArrays.reset()
            startDisplayLinkToUpdateCanvasView(false)
        }
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
