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

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var displayLinkForRendering: CADisplayLink?

    private var canvasView: CanvasViewProtocol?

    private let requestingCanvasTextureDrawToRenderTexture = PassthroughSubject<Void, Never>()

    private let requestingPauseDisplayLink = PassthroughSubject<Bool, Never>()

    private let requestingUpdateCanvasView = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Configure the display link for rendering.
        displayLinkForRendering = CADisplayLink(target: self, selector: #selector(updateCanvasView(_:)))
        displayLinkForRendering?.add(to: .current, forMode: .common)
        displayLinkForRendering?.isPaused = true

        requestingCanvasTextureDrawToRenderTexture
            .sink { [weak self] _ in
                guard 
                    let `self`,
                    let canvasView,
                    let canvasTextureSize = canvasTexture?.size,
                    let renderTextureSize = canvasView.renderTexture?.size,
                    let commandBuffer = canvasView.commandBuffer
                else { return }

                self.drawTextureWithScaling(
                    texture: canvasTexture,
                    textureScaleFactor: ViewSize.getScaleToFit(canvasTextureSize, to: renderTextureSize),
                    on: canvasView.renderTexture,
                    commandBuffer: commandBuffer
                )
                canvasView.updateCanvasView()
            }
            .store(in: &cancellables)

        requestingPauseDisplayLink
            .sink { [weak self] isPause in
                self?.displayLinkForRendering?.isPaused = isPause
            }
            .store(in: &cancellables)

        requestingUpdateCanvasView
            .sink { [weak self] _ in
                self?.canvasView?.updateCanvasView()
            }
            .store(in: &cancellables)
    }

}

extension CanvasViewModel {

    func onViewDidAppear(canvasView: CanvasViewProtocol) {

        self.canvasView = canvasView

        // Since `func onUpdateRenderTexture` is not called at app launch on iPhone,
        // initialize the canvas here.
        if canvasTexture == nil, let textureSize = canvasView.renderTexture?.size {
            initCanvas(
                textureSize: textureSize
            )
        }
        requestingCanvasTextureDrawToRenderTexture.send()
    }

    func onUpdateRenderTexture() {
        if canvasTexture == nil, let textureSize = canvasView?.renderTexture?.size {
            initCanvas(
                textureSize: textureSize
            )
        }
        requestingCanvasTextureDrawToRenderTexture.send()
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

        if touchScreenPoints.currentTouchPhase == .began {
            startDisplayLinkToUpdateCanvasView(true)
            drawing.reset()
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
        if pencilDrawingArrays.hasActualValueReplacementCompleted {
            pencilDrawingArrays.appendLastEstimatedTouchPointToActualTouchPointArray()
        }

        let touchScreenPoints = pencilDrawingArrays.latestActualTouchPoints
        pencilDrawingArrays.updateLatestActualTouchPoint()

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

    @objc private func updateCanvasView(_ displayLink: CADisplayLink) {
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

        mergeDrawingTexture(
            withCurrentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: commandBuffer,
            executeDrawingFinishProcess: drawing.isDrawingComplete
        )

        requestingCanvasTextureDrawToRenderTexture.send()

        if drawing.isDrawingFinished {
            drawing.reset()
            pencilDrawingArrays.reset()
            startDisplayLinkToUpdateCanvasView(false)
        }
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(textureSize: CGSize) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        drawingTexture.initTexture(textureSize: textureSize)
        currentTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)
        canvasTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)

        clearCanvas()
    }

    private func clearCanvas() {
        guard let commandBuffer = canvasView?.commandBuffer else { return }

        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: commandBuffer
        )

        requestingCanvasTextureDrawToRenderTexture.send()
    }

    private func clearDrawingTexture() {
        guard
            let currentTexture,
            let commandBuffer = canvasView?.commandBuffer
        else { return }

        // Clear `drawingTextures` during drawing
        drawingTexture.clearTexture(with: commandBuffer)

        mergeDrawingTexture(
            withCurrentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: commandBuffer
        )

        requestingCanvasTextureDrawToRenderTexture.send()
    }

    private func startDisplayLinkToUpdateCanvasView(_ isStarted: Bool) {
        requestingPauseDisplayLink.send(!isStarted)

        // Call `requestingUpdateCanvasView` when stopping as the last line isn’t drawn
        if !isStarted {
            requestingUpdateCanvasView.send(())
        }
    }

    private func mergeDrawingTexture(
        withCurrentTexture currentTexture: MTLTexture,
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
                drawingTexture.texture
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
                texture: drawingTexture.texture,
                into: currentTexture,
                with: commandBuffer
            )
            drawingTexture.clearTexture(
                with: commandBuffer
            )
        }
    }

    /// Draw `texture` onto `destinationTexture` with a scaled size
    private func drawTextureWithScaling(
        texture: MTLTexture?,
        textureScaleFactor: CGFloat,
        on destinationTexture: MTLTexture?,
        commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let destinationTexture,
            let device = MTLCreateSystemDefaultDevice(),
            let textureBuffers = MTLBuffers.makeTextureBuffers(
                device: device,
                sourceSize: .init(
                    width: texture.size.width * textureScaleFactor,
                    height: texture.size.height * textureScaleFactor
                ),
                destinationSize: destinationTexture.size,
                nodes: textureNodes
            )
        else { return }

        MTLRenderer.draw(
            texture: texture,
            buffers: textureBuffers,
            withBackgroundColor: Constants.blankAreaBackgroundColor,
            on: destinationTexture,
            with: commandBuffer
        )
    }

}
