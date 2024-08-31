//
//  LayerManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

/// Manage `var currentTexture`
final class LayerManager {
    private (set) var currentTexture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
}

extension LayerManager {
    func initTexture(
        _ textureSize: CGSize
    ) {
        currentTexture = MTKTextureUtils.makeBlankTexture(
            with: device,
            textureSize
        )
    }

    func resetAllTextures(
        _ renderTarget: CanvasViewProtocol,
        withBackgroundColor color: (Int, Int, Int)
    ) {
        guard let renderTexture = renderTarget.renderTexture else { return }

        MTLRenderer.clear(
            currentTexture,
            with: renderTarget.commandBuffer
        )

        MTLRenderer.fill(
            color,
            on: renderTexture,
            with: renderTarget.commandBuffer
        )
    }

}
