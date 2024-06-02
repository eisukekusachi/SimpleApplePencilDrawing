//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class CanvasViewModel {

    func onRenderTextureSizeChange(renderTarget: MTKRenderTextureProtocol) {
        guard
            let textureSize = renderTarget.renderTexture?.size
        else { return }

        initTextures(
            textureSize,
            renderTarget: renderTarget
        )

    }

}

extension CanvasViewModel {

    private func initTextures(
        _ textureSize: CGSize,
        renderTarget: MTKRenderTextureProtocol
    ) {
        guard let renderTexture = renderTarget.renderTexture else { return }

        MTLRenderer.fill(
            renderTexture,
            UIColor.red.rgba,
            renderTarget.commandBuffer
        )

        renderTarget.setNeedsDisplay()
    }

}
