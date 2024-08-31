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

    /// A texture currently being displayed
    private let currentTexture = CanvasCurrentTexture()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

    private let drawingToolStatus = CanvasDrawingToolStatus()

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
            $0.convertToTextureCoordinates(
                frameSize: view.frame.size,
                renderTextureSize: canvasView.renderTexture?.size ?? .zero,
                drawableSize: canvasView.viewDrawable?.texture.size ?? .zero
            )
        }

        // Add points to the iterator.
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
    }

    func onPencilInputGesture(
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
            $0.convertToTextureCoordinates(
                frameSize: view.frame.size,
                renderTextureSize: canvasView.renderTexture?.size ?? .zero,
                drawableSize: canvasView.viewDrawable?.texture.size ?? .zero
            )
        }

        // Add points to the iterator.
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
        drawingTexture.initTexture(textureSize: textureSize)
        currentTexture.initTexture(textureSize: textureSize)

        canvasView.initTexture(textureSize: textureSize)

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
            color: drawingToolStatus.brushColor,
            with: canvasView.commandBuffer
        )

        // Render the `drawingTexture` onto the `renderTexture`
        MTLRenderer.drawTextures(
            [currentTexture.currentTexture,
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
                into: currentTexture.currentTexture,
                with: canvasView.commandBuffer
            )
            drawingTexture.clearTexture(
                with: canvasView.commandBuffer
            )
        }

        if touchPhase == .ended || touchPhase == .cancelled {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil
        }
    }

}
