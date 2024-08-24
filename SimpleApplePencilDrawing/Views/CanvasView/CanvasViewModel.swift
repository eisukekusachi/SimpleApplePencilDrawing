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

    private let drawingTool = CanvasDrawingTool()

    /// An iterator for managing grayscale points.
    private var grayscaleTexturePointIterator: CanvasGrayscaleTexturePointIterator?

    /// A class for managing the currently drawing texture
    private let drawingTexture: DrawingTexture = CanvasBrushDrawingTexture()

    /// A class for managing textures
    private let layerManager = LayerManager()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

    private var backgroundColor: UIColor = .white

}

extension CanvasViewModel {

    func onViewDidAppear(
        _ drawableTextureSize: CGSize,
        canvasView: CanvasViewProtocol
    ) {
        // Initialize the canvas here if the renderTexture's texture is nil
        if canvasView.renderTexture == nil {
            initCanvas(
                textureSize: drawableTextureSize,
                canvasView: canvasView
            )
        }
    }

    func onFingerInputGesture(
        touches: [CanvasTouchPoint],
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        let touchPhase = touches.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTexturePointIterator = CanvasGrayscaleTexturePointIterator()
        }

        let textureTouchPoints: [CanvasTouchPoint] = touches.map {
            $0.convertToTextureCoordinates(
                frameSize: view.frame.size,
                renderTextureSize: canvasView.renderTexture?.size ?? .zero,
                drawableSize: canvasView.viewDrawable?.texture.size ?? .zero
            )
        }

        // Add points to the iterator.
        grayscaleTexturePointIterator?.append(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingTool.brushDiameter)
                )
            }
        )

        drawPoints(
            textureCurvePoints: grayscaleTexturePointIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            touchPhase: touchPhase,
            on: canvasView
        )
    }

    func onPencilInputGesture(
        touches: [CanvasTouchPoint],
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        let touchPhase = touches.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTexturePointIterator = CanvasGrayscaleTexturePointIterator()
        }

        let textureTouchPoints: [CanvasTouchPoint] = touches.map {
            $0.convertToTextureCoordinates(
                frameSize: view.frame.size,
                renderTextureSize: canvasView.renderTexture?.size ?? .zero,
                drawableSize: canvasView.viewDrawable?.texture.size ?? .zero
            )
        }

        // Add points to the iterator.
        grayscaleTexturePointIterator?.append(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingTool.brushDiameter)
                )
            }
        )

        drawPoints(
            textureCurvePoints: grayscaleTexturePointIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            touchPhase: touchPhase,
            on: canvasView
        )
    }

    func onTapClearTexture(canvasView: CanvasViewProtocol) {
        drawingTexture.clearTexture(
            with: canvasView.commandBuffer
        )
        layerManager.resetAllTextures(
            canvasView,
            withBackgroundColor: backgroundColor.rgb
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
        drawingTexture.initTexture(
            textureSize
        )
        layerManager.initTexture(
            textureSize
        )

        canvasView.initTexture(with: textureSize)

        // Add a background color to the render target’s texture
        MTLRenderer.fill(
            backgroundColor.rgb,
            on: canvasView.renderTexture,
            with: canvasView.commandBuffer
        )

        canvasView.setNeedsDisplay()
    }

    private func pauseDisplayLinkOnCanvas(_ isPaused: Bool, canvasView: CanvasViewProtocol) {
        pauseDisplayLinkSubject.send(isPaused)

        // Call `canvas.setNeedsDisplay` when stopping as the last line isn’t drawn
        if isPaused {
            canvasView.setNeedsDisplay()
        }
    }

    private func drawPoints(
        textureCurvePoints: [CanvasGrayscaleDotPoint],
        touchPhase: UITouch.Phase,
        on canvasView: CanvasViewProtocol
    ) {
        // Draw curve points on the `drawingTexture.texture`.
        drawingTexture.drawPointsOnTexture(
            grayscaleTexturePoints: textureCurvePoints,
            color: drawingTool.brushColor,
            with: canvasView.commandBuffer
        )

        // Render the `drawingTexture` onto the `renderTexture`
        MTLRenderer.drawTextures(
            [layerManager.currentTexture,
             drawingTexture.texture],
            withBackgroundColor: backgroundColor.rgba,
            on: canvasView.renderTexture,
            with: canvasView.commandBuffer
        )

        // At touch end, render `drawingTexture.texture` on `layerManager.currentTexture`.
        // Then, clear `drawingTexture.texture` for the next drawing.
        if touchPhase == .ended {
            MTLRenderer.merge(
                drawingTexture.texture,
                into: layerManager.currentTexture,
                with: canvasView.commandBuffer
            )
            drawingTexture.clearTexture(
                with: canvasView.commandBuffer
            )
        }

        if touchPhase == .ended || touchPhase == .cancelled {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTexturePointIterator = nil
        }
    }

}
