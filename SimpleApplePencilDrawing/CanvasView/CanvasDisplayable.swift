//
//  CanvasDisplayable.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/04.
//

import MetalKit

@MainActor
public protocol CanvasDisplayable {

    /// Command buffer for a single frame
    var currentFrameCommandBuffer: MTLCommandBuffer? { get }

    var displayTexture: MTLTexture? { get }

    func resetCommandBuffer()

    func setNeedsDisplay()
}
