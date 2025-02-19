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
    static let bytesPerPixel = 4
    static let bitsPerComponent = 8

    static func makeTexture(
        label: String? = nil,
        size: CGSize,
        pixelFormat: MTLPixelFormat = pixelFormat,
        with device: MTLDevice
    ) -> MTLTexture? {
        let texture = device.makeTexture(
            descriptor: getTextureDescriptor(size: size)
        )
        texture?.label = label
        return texture
    }

    static func makeTexture(
        label: String? = nil,
        size: CGSize,
        colorArray: [UInt8],
        with device: MTLDevice
    ) -> MTLTexture? {
        guard colorArray.count == Int(size.width * size.height) * bytesPerPixel else { return nil }

        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerRow = bytesPerPixel * width

        let texture = makeTexture(label: label, size: .init(width: width, height: height), with: device)
        texture?.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            slice: 0,
            withBytes: colorArray,
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerRow * height
        )
        return texture
    }

    static func makeBlankTexture(
        label: String? = nil,
        size: CGSize,
        with device: MTLDevice
    ) -> MTLTexture? {
        guard
            let texture = makeTexture(label: label, size: size, with: device),
            let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
        else { return nil }

        MTLRenderer.shared.clearTexture(
            texture: texture,
            with: commandBuffer
        )
        commandBuffer.commit()

        return texture
    }

    private static func getTextureDescriptor(size: CGSize) -> MTLTextureDescriptor {
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
        return textureDescriptor
    }

}
