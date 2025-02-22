//
//  CanvasDrawingTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
/// A protocol with the currently drawing texture
protocol CanvasDrawingTexture {
    /// A currently drawing texture
    var texture: MTLTexture? { get }

    /// Initializes the textures for drawing with the specified texture size.
    func initTexture(size: CGSize)

    /// Renders `selectedTexture` and `drawingTexture`, then render them onto targetTexture
    func renderDrawingTexture(
        withSelectedTexture selectedTexture: MTLTexture?,
        backgroundColor: UIColor,
        onto targetTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    )

    /// Merges the drawing texture into the destination texture
    func mergeDrawingTexture(
        into destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    )

    /// Clears all textures
    func clearAllTextures()
    func clearAllTextures(with commandBuffer: MTLCommandBuffer)
}
