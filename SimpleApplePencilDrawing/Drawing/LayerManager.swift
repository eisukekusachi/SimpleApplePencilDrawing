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
        _ textureSize: CGSize
    ) {
        currentTexture = MTLTextureManager.makeBlankTexture(
            with: device,
            textureSize
        )

    }

    func clearAll(
        _ renderTarget: MTKRenderTextureProtocol
    ) {
        guard let renderTexture = renderTarget.renderTexture else { return }

        MTLRenderer.clear(
            currentTexture,
            with: renderTarget.commandBuffer
        )

        MTLRenderer.fill(
            backgroundColor.rgb,
            on: renderTexture,
            with: renderTarget.commandBuffer
        )
    }

    func fillBackgroundColor(
        on renderTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    ) {
        MTLRenderer.fill(
            backgroundColor.rgb,
            on: renderTexture,
            with: commandBuffer
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

        MTLRenderer.drawTextures(
            [currentTexture,
             drawingTexture],
            withBackgroundColor: backgroundColor.rgba,
            on: renderTexture,
            with: commandBuffer
        )

        if atEnd, let drawingTexture {
            MTLRenderer.merge(
                drawingTexture,
                into: currentTexture,
                with: commandBuffer
            )
        }
    }

}
