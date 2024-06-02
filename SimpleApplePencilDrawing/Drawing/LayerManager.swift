//
//  LayerManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class LayerManager {

    var backgroundColor: UIColor = .white

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var currentTexture: MTLTexture?

    func initTextures(
        _ textureSize: CGSize,
        renderTarget: MTKRenderTextureProtocol
    ) {
        guard let renderTexture = renderTarget.renderTexture else { return }

        currentTexture = MTLTextureManager.makeBlankTexture(
            with: device,
            textureSize
        )

        MTLRenderer.fill(
            renderTexture,
            backgroundColor.rgb,
            renderTarget.commandBuffer
        )
    }

    func clearAll(
        _ renderTarget: MTKRenderTextureProtocol
    ) {
        guard let renderTexture = renderTarget.renderTexture else { return }

        MTLRenderer.clear(
            currentTexture,
            renderTarget.commandBuffer
        )

        MTLRenderer.fill(
            renderTexture,
            backgroundColor.rgb,
            renderTarget.commandBuffer
        )
    }

    func renderTexture(
        _ drawingTexture: MTLTexture?,
        on renderTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer,
        atEnd: Bool
    ) {
        guard
            let currentTexture,
            let renderTexture
        else { return }

        MTLRenderer.fill(
            renderTexture,
            backgroundColor.rgba,
            commandBuffer
        )

        MTLRenderer.merge(
            currentTexture,
            into: renderTexture,
            with: commandBuffer
        )

        guard let drawingTexture else { return }

        MTLRenderer.merge(
            drawingTexture,
            into: renderTexture,
            with: commandBuffer
        )

        if atEnd {
            MTLRenderer.merge(
                drawingTexture,
                into: currentTexture,
                with: commandBuffer
            )
        }
    }

}
