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

    private let drawingTexture: DrawingTexture = BrushDrawingTexture()

    private let layerManager = LayerManager()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

}

extension CanvasViewModel {

    func onRenderTextureSizeChange(renderTarget: MTKRenderTextureProtocol) {
        guard
            let textureSize = renderTarget.renderTexture?.size
        else { return }

        initTextures(
            textureSize,
            renderTarget: renderTarget
        )
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

    private func initTextures(
        _ textureSize: CGSize,
        renderTarget: MTKRenderTextureProtocol
    ) {
        drawingTexture.initTextures(
            textureSize
        )
        layerManager.initTextures(
            textureSize,
            renderTarget: renderTarget
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
