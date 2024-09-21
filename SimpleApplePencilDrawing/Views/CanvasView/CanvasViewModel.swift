//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

final class CanvasViewModel {

    var pauseDisplayLinkPublish: AnyPublisher<Bool, Never> {
        pauseDisplayLinkSubject.eraseToAnyPublisher()
    }

    /// An iterator for managing a grayscale curve
    private var grayscaleTextureCurveIterator: CanvasGrayscaleCurveIterator?

    /// A texture currently being drawn
    private let drawingTexture: CanvasDrawingTexture = CanvasBrushDrawingTexture()
    /// A texture with lines
    private var currentTexture: MTLTexture?
    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// A manager for handling Apple Pencil input values
    private let pencilScreenTouchPoints = CanvasPencilScreenTouchPoints()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var backgroundColor: UIColor = .white

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

}

extension CanvasViewModel {

    func onUpdateRenderTexture(canvasView: CanvasViewProtocol) {
        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )
        canvasView.setNeedsDisplay()
    }

    func onViewDidAppear(
        _ drawableTextureSize: CGSize,
        canvasView: CanvasViewProtocol
    ) {
        if canvasTexture == nil {
            initCanvas(
                textureSize: drawableTextureSize,
                canvasView: canvasView
            )
        }
    }

    func onFingerInputGesture(
        touches: Set<UITouch>,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        guard
            let canvasTexture,
            let renderTexture = canvasView.renderTexture
        else { return }

        let touchScreenPoints: [CanvasTouchPoint] = touches.map {
            .init(touch: $0, view: view)
        }

        let touchPhase = touchScreenPoints.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
        }

        let textureTouchPoints: [CanvasTouchPoint] = touchScreenPoints.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            CanvasTouchPoint.init(
                location: scaleAndCenterAspectFill(
                    sourceTextureLocation: $0.location,
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTexture.size
                ),
                touch: $0
            )
        }

        grayscaleTextureCurveIterator?.append(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawPoints(
            textureCurvePoints: grayscaleTextureCurveIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            touchPhase: touchPhase,
            on: canvasView
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil
        }
    }

    func onPencilGestureDetected(
        touches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        // Make `grayscaleTextureCurveIterator` and start the display link when a touch begins
        if touches.contains(where: {$0.phase == .began}) {
            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
            pauseDisplayLinkSubject.send(false)

            pencilScreenTouchPoints.reset()
        }

        event?.allTouches?
            .compactMap { $0.type == .pencil ? $0 : nil }
            .sorted { $0.timestamp < $1.timestamp }
            .forEach { touch in
                event?.coalescedTouches(for: touch)?.forEach { coalescedTouch in
                    pencilScreenTouchPoints.appendEstimatedValue(
                        .init(touch: coalescedTouch, view: view)
                    )
                }
            }
    }

    func onPencilGestureDetected(
        actualTouches: Set<UITouch>,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        guard
            let canvasTexture,
            let renderTexture = canvasView.renderTexture
        else { return }

        // Combine `actualTouches` with the estimated values to create actual values, and append them to an array
        let actualTouchArray = Array(actualTouches).sorted { $0.timestamp < $1.timestamp }
        actualTouchArray.forEach { actualTouch in
            pencilScreenTouchPoints.appendActualValueWithEstimatedValue(actualTouch)
        }
        if pencilScreenTouchPoints.hasActualValueReplacementCompleted {
            pencilScreenTouchPoints.appendLastEstimatedTouchPointToActualTouchPointArray()
        }

        guard
            // Wait to ensure sufficient time has passed since the previous process
            // as the operation may not work correctly if the time difference is too short.
            pencilScreenTouchPoints.hasSufficientTimeElapsedSincePreviousProcess(allowedDifferenceInSeconds: 0.01) ||
            [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(pencilScreenTouchPoints.actualTouchPointArray.currentTouchPhase)
        else { return }

        let latestScreenTouchArray = pencilScreenTouchPoints.latestActualTouchPoints
        pencilScreenTouchPoints.updateLatestActualTouchPoint()

        let touchPhase = latestScreenTouchArray.currentTouchPhase

        let latestTextureTouchArray = latestScreenTouchArray.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            CanvasTouchPoint.init(
                location: scaleAndCenterAspectFill(
                    sourceTextureLocation: $0.location,
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTexture.size
                ),
                touch: $0
            )
        }

        grayscaleTextureCurveIterator?.append(
            latestTextureTouchArray.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawPoints(
            textureCurvePoints: grayscaleTextureCurveIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            touchPhase: touchPhase,
            on: canvasView
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil

            pencilScreenTouchPoints.reset()
        }
    }

    func onTapClearTexture(canvasView: CanvasViewProtocol) {
        drawingTexture.clearTexture()

        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        MTLRenderer.clear(
            texture: currentTexture,
            with: commandBuffer
        )
        commandBuffer.commit()

        clearCanvas(canvasView)
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(
        textureSize: CGSize,
        canvasView: CanvasViewProtocol
    ) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        drawingTexture.initTexture(textureSize: textureSize)
        currentTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)
        canvasTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)

        clearCanvas(canvasView)
    }

    private func clearCanvas(_ canvasView: CanvasViewProtocol) {
        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: canvasView.commandBuffer
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        canvasView.setNeedsDisplay()
    }

    private func pauseDisplayLinkOnCanvas(_ isPaused: Bool, canvasView: CanvasViewProtocol) {
        pauseDisplayLinkSubject.send(isPaused)

        // Call `canvasView.setNeedsDisplay` when stopping as the last line isn’t drawn
        if isPaused {
            canvasView.setNeedsDisplay()
        }
    }

    private func drawPoints(
        textureCurvePoints: [CanvasGrayscaleDotPoint],
        touchPhase: UITouch.Phase,
        on canvasView: CanvasViewProtocol
    ) {
        // Draw curve points on the `drawingTexture`
        drawingTexture.drawPointsOnTexture(
            grayscaleTexturePoints: textureCurvePoints,
            color: drawingToolStatus.brushColor,
            with: canvasView.commandBuffer
        )

        // Render `currentTexture` and `drawingTexture` onto the `renderTexture`
        MTLRenderer.draw(
            textures: [
                currentTexture,
                drawingTexture.texture
            ],
            withBackgroundColor: backgroundColor.rgba,
            on: canvasTexture,
            with: canvasView.commandBuffer
        )

        // At touch end, render `drawingTexture` on `currentTexture`
        // Then, clear `drawingTexture` for the next drawing.
        if touchPhase == .ended {
            MTLRenderer.merge(
                texture: drawingTexture.texture,
                into: currentTexture,
                with: canvasView.commandBuffer
            )
            drawingTexture.clearTexture(
                with: canvasView.commandBuffer
            )
        }
    }

    /// Draw `texture` onto `destinationTexture` with aspect fit
    private func drawTextureWithAspectFit(
        texture: MTLTexture?,
        on destinationTexture: MTLTexture?,
        commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let destinationTexture
        else { return }

        let ratio = ViewSize.getScaleToFit(texture.size, to: destinationTexture.size)

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let textureBuffers = MTLBuffers.makeTextureBuffers(
                device: device,
                sourceSize: .init(
                    width: texture.size.width * ratio,
                    height: texture.size.height * ratio
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

    /// Scales the `sourceTextureLocation` by applying the aspect fill ratio of `sourceTextureSize` to `destinationTextureSize`,
    /// ensuring the aspect ratio is maintained, and centers the scaled location within `destinationTextureSize`.
    private func scaleAndCenterAspectFill(
        sourceTextureLocation: CGPoint,
        sourceTextureSize: CGSize,
        destinationTextureSize: CGSize
    ) -> CGPoint {
        if sourceTextureSize == destinationTextureSize {
            return sourceTextureLocation
        }

        let ratio = ViewSize.getScaleToFill(sourceTextureSize, to: destinationTextureSize)

        return .init(
            x: sourceTextureLocation.x * ratio + (destinationTextureSize.width - sourceTextureSize.width * ratio) * 0.5,
            y: sourceTextureLocation.y * ratio + (destinationTextureSize.height - sourceTextureSize.height * ratio) * 0.5
        )
    }

}
