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

    private let drawingTool = DrawingTool()

    /// An iterator for managing grayscale points.
    private var grayscaleDrawingIterator: GrayscaleDrawingIterator?

    /// A class for managing the currently drawing texture
    private let drawingTexture: DrawingTexture = BrushDrawingTexture()

    /// A class for managing textures
    private let layerManager = LayerManager()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

}

extension CanvasViewModel {

    func onViewDidAppear(
        _ drawableTextureSize: CGSize,
        renderTarget: MTKRenderTextureProtocol
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
        touches: [TouchPoint],
        renderTarget: MTKRenderTextureProtocol
    ) {
        drawCurve(
            touches: touches.map {
                $0.getScaledTouchPoint(
                    renderTextureSize: renderTarget.renderTexture?.size ?? .zero,
                    drawableSize: renderTarget.viewDrawable?.texture.size ?? .zero
                )
            },
            on: renderTarget
        )
    }

    func onPencilInputGesture(
        touches: [TouchPoint],
        renderTarget: MTKRenderTextureProtocol
    ) {
        drawCurve(
            touches: touches.map {
                $0.getScaledTouchPoint(
                    renderTextureSize: renderTarget.renderTexture?.size ?? .zero,
                    drawableSize: renderTarget.viewDrawable?.texture.size ?? .zero
                )
            },
            on: renderTarget
        )
    }

    func clearButtonTapped(renderTarget: MTKRenderTextureProtocol) {
        drawingTexture.clearDrawingTextures(
            with: renderTarget.commandBuffer
        )
        layerManager.clearAll(
            renderTarget
        )
        renderTarget.setNeedsDisplay()
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(
        textureSize: CGSize,
        renderTarget: MTKRenderTextureProtocol
    ) {
        drawingTexture.initTextures(
            textureSize
        )
        layerManager.initTextures(
            textureSize
        )

        renderTarget.initTexture(with: textureSize)

        // Add a background color to the render target’s texture
        layerManager.fillBackgroundColor(
            on: renderTarget.renderTexture!,
            with: renderTarget.commandBuffer
        )

        renderTarget.setNeedsDisplay()
    }

    private func drawCurve(
        touches: [TouchPoint],
        on renderTarget: MTKRenderTextureProtocol
    ) {
        let touchPhase = touches.phase

        defer {
            if touchPhase == .ended || touchPhase == .cancelled {
                pauseDisplayLinkSubject.send(true)
                grayscaleDrawingIterator = nil
            }
        }
        if touchPhase == .began {
            pauseDisplayLinkSubject.send(false)
            grayscaleDrawingIterator = GrayscaleDrawingIterator()
        }

        // Add points to the iterator.
        grayscaleDrawingIterator?.append(
            touches.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingTool.brushDiameter)
                )
            }
        )

        // Draw curve points on the `drawingTexture`.
        drawingTexture.drawLineOnDrawingTexture(
            grayscalePointsOnTexture: grayscaleDrawingIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            color: drawingTool.brushColor,
            with: renderTarget.commandBuffer
        )

        // Render the `drawingTexture` onto the `renderTexture`.
        layerManager.renderTexture(
            drawingTexture.drawingTexture,
            on: renderTarget.renderTexture,
            with: renderTarget.commandBuffer,
            atEnd: touchPhase == .ended
        )

        if touchPhase == .ended {
            drawingTexture.clearDrawingTextures(
                with: renderTarget.commandBuffer
            )
        }
    }

}
