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
    /// A texture with lines previously drawn
    private let currentTexture = CanvasCurrentTexture()
    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// A manager for handling Apple Pencil input values
    private let pencilScreenTouchPoints = CanvasPencilScreenTouchPoints()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var backgroundColor: UIColor = .white

    private let blankAreaBackgroundColor: (Int, Int, Int) = (230, 230, 230)
}

extension CanvasViewModel {

    func onUpdateRenderTexture(canvasView: CanvasViewProtocol) {
        drawTextureWithAspectFit(
            texture: canvasTexture,
            withBackgroundColor: blankAreaBackgroundColor,
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
        let touchScreenPoints: [CanvasTouchPoint] = touches.map {
            .init(touch: $0, view: view)
        }

        let touchPhase = touchScreenPoints.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
        }

        let textureTouchPoints: [CanvasTouchPoint] = touchScreenPoints.map {
            let scaleFrameToTexture = ViewSize.getScaleToFit(view.frame.size, to: canvasView.renderTexture?.size ?? .zero)
            return CanvasTouchPoint.init(
                location: convertToTextureCoordinates(
                    location: .init(
                        x: $0.location.x * scaleFrameToTexture,
                        y: $0.location.y * scaleFrameToTexture
                    ),
                    renderTextureSize: canvasTexture?.size ?? .zero,
                    drawableSize: canvasView.renderTexture?.size ?? .zero
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
            let scaleFrameToTexture = ViewSize.getScaleToFit(view.frame.size, to: canvasView.renderTexture?.size ?? .zero)
            return CanvasTouchPoint.init(
                location: convertToTextureCoordinates(
                    location: .init(
                        x: $0.location.x * scaleFrameToTexture,
                        y: $0.location.y * scaleFrameToTexture
                    ),
                    renderTextureSize: canvasTexture?.size ?? .zero,
                    drawableSize: canvasView.renderTexture?.size ?? .zero
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

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil

            pencilScreenTouchPoints.reset()
        }
    }

    func onTapClearTexture(canvasView: CanvasViewProtocol) {
        drawingTexture.clearTexture()
        currentTexture.clearTexture()

        MTLRenderer.fill(
            backgroundColor.rgb,
            on: canvasView.renderTexture,
            with: canvasView.commandBuffer
        )

        canvasView.setNeedsDisplay()
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
        currentTexture.initTexture(textureSize: textureSize)
        canvasTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)

        MTLRenderer.fill(
            backgroundColor.rgb,
            on: canvasView.renderTexture,
            with: canvasView.commandBuffer
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
        MTLRenderer.drawTextures(
            [currentTexture.texture,
             drawingTexture.texture],
            withBackgroundColor: backgroundColor.rgba,
            on: canvasTexture,
            with: canvasView.commandBuffer
        )

        // At touch end, render `drawingTexture` on `currentTexture`
        // Then, clear `drawingTexture` for the next drawing.
        if touchPhase == .ended {
            MTLRenderer.merge(
                drawingTexture.texture,
                into: currentTexture.texture,
                with: canvasView.commandBuffer
            )
            drawingTexture.clearTexture(
                with: canvasView.commandBuffer
            )
        }

        drawTextureWithAspectFit(
            texture: canvasTexture,
            withBackgroundColor: blankAreaBackgroundColor,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )
    }

    private func drawTextureWithAspectFit(
        texture: MTLTexture?,
        withBackgroundColor color: (Int, Int, Int)? = nil,
        on destinationTexture: MTLTexture?,
        commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let destinationTexture
        else { return }

        let sourceSize: CGSize = .init(
            width: texture.size.width * ViewSize.getScaleToFit(texture.size, to: destinationTexture.size),
            height: texture.size.height * ViewSize.getScaleToFit(texture.size, to: destinationTexture.size)
        )

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let textureBuffers = MTLBuffers.makeAspectFitTextureBuffers(
                device: device,
                sourceSize: sourceSize,
                destinationSize: destinationTexture.size,
                nodes: textureNodes
            )
        else { return }

        MTLRenderer.drawTexture(
            texture,
            buffers: textureBuffers,
            withBackgroundColor: color,
            on: destinationTexture,
            with: commandBuffer
        )
    }

    private func convertToTextureCoordinates(
        location: CGPoint,
        renderTextureSize: CGSize,
        drawableSize: CGSize
    ) -> CGPoint {

        var locationOnTexture = location

        if renderTextureSize != drawableSize {
            let widthRatio = renderTextureSize.width / drawableSize.width
            let heightRatio = renderTextureSize.height / drawableSize.height

            if widthRatio > heightRatio {
                locationOnTexture = .init(
                    x: location.x * widthRatio + (renderTextureSize.width - drawableSize.width * widthRatio) * 0.5,
                    y: location.y * widthRatio + (renderTextureSize.height - drawableSize.height * widthRatio) * 0.5
                )
            } else {
                locationOnTexture = .init(
                    x: location.x * heightRatio + (renderTextureSize.width - drawableSize.width * heightRatio) * 0.5,
                    y: location.y * heightRatio + (renderTextureSize.height - drawableSize.height * heightRatio) * 0.5
                )
            }
        }

        return locationOnTexture
    }

}
