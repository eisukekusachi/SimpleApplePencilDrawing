//
//  MTLTextureCreator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Accelerate

enum MTLTextureCreator {

    static let pixelFormat: MTLPixelFormat = .bgra8Unorm

    static func makeBlankTexture(
        size: CGSize,
        with device: MTLDevice
    ) -> MTLTexture? {
        guard
            let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
        else { return nil }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [
            .renderTarget,
            .shaderRead,
            .shaderWrite
        ]

        let newTexture: MTLTexture? = device.makeTexture(descriptor: textureDescriptor)

        MTLRenderer.clear(
            texture: newTexture,
            with: commandBuffer
        )
        commandBuffer.commit()

        return newTexture
    }

}
