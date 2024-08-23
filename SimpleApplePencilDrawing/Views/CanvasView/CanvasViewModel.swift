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
        renderTarget: CanvasViewProtocol
    ) {
        // Initialize the canvas here if the renderTexture's texture is nil
        if renderTarget.renderTexture == nil {
            initCanvas(
                textureSize: drawableTextureSize,
                renderTarget: renderTarget
            )
        }
    }

    func onFingerInputGesture(
        touches: [CanvasTouchPoint],
        view: UIView,
        renderTarget: CanvasViewProtocol
    ) {
        drawCurve(
            touches: touches.map {
                $0.convertToTextureCoordinates(
                    frameSize: view.frame.size,
                    renderTextureSize: renderTarget.renderTexture?.size ?? .zero,
                    drawableSize: renderTarget.viewDrawable?.texture.size ?? .zero
                )
            },
            on: renderTarget
        )
    }

    func onPencilInputGesture(
        touches: [CanvasTouchPoint],
        view: UIView,
        renderTarget: CanvasViewProtocol
    ) {
        drawCurve(
            touches: touches.map {
                $0.convertToTextureCoordinates(
                    frameSize: view.frame.size,
                    renderTextureSize: renderTarget.renderTexture?.size ?? .zero,
                    drawableSize: renderTarget.viewDrawable?.texture.size ?? .zero
                )
            },
            on: renderTarget
        )
    }

    func onTapClearTexture(renderTarget: CanvasViewProtocol) {
        drawingTexture.clearTexture(
            with: renderTarget.commandBuffer
        )
        layerManager.resetAllTextures(
            renderTarget,
            withBackgroundColor: backgroundColor.rgb
        )
        renderTarget.setNeedsDisplay()
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(
        textureSize: CGSize,
        renderTarget: CanvasViewProtocol
    ) {
        drawingTexture.initTexture(
            textureSize
        )
        layerManager.initTexture(
            textureSize
        )

        renderTarget.initTexture(with: textureSize)

        // Add a background color to the render target’s texture
        MTLRenderer.fill(
            backgroundColor.rgb,
            on: renderTarget.renderTexture,
            with: renderTarget.commandBuffer
        )

        renderTarget.setNeedsDisplay()
    }

    private func drawCurve(
        touches: [CanvasTouchPoint],
        on renderTarget: CanvasViewProtocol
    ) {
        let touchPhase = touches.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkSubject.send(false)
            grayscaleTexturePointIterator = CanvasGrayscaleTexturePointIterator()
        }

        // Add points to the iterator.
        grayscaleTexturePointIterator?.append(
            touches.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingTool.brushDiameter)
                )
            }
        )

        // Draw curve points on the `drawingTexture`.
        drawingTexture.drawLineOnTexture(
            grayscaleTexturePoints: grayscaleTexturePointIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            color: drawingTool.brushColor,
            with: renderTarget.commandBuffer
        )

        // Render the `drawingTexture` onto the `renderTexture`
        MTLRenderer.drawTextures(
            [layerManager.currentTexture,
             drawingTexture.texture],
            withBackgroundColor: backgroundColor.rgba,
            on: renderTarget.renderTexture,
            with: renderTarget.commandBuffer
        )

        if touchPhase == .ended {
            MTLRenderer.merge(
                drawingTexture.texture,
                into: layerManager.currentTexture,
                with: renderTarget.commandBuffer
            )
            drawingTexture.clearTexture(
                with: renderTarget.commandBuffer
            )
        }

        if touchPhase == .ended || touchPhase == .cancelled {
            pauseDisplayLinkSubject.send(true)
            grayscaleTexturePointIterator = nil
        }
    }

}
