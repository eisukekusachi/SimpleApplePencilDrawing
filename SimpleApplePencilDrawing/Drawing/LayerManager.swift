//
//  LayerManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class LayerManager {

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var currentTexture: MTLTexture?

    var isTextureInitialized: Bool {
        currentTexture != nil
    }
    var backgroundColor: UIColor = .white

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
