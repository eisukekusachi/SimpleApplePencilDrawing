//
//  MTLCommandManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class MTLCommandManager {

    private let queue: MTLCommandQueue

    private (set) var commandBuffer: MTLCommandBuffer?

    init(device: MTLDevice) {
        self.queue = device.makeCommandQueue()!
        makeNewCommandBuffer()
    }

    func makeNewCommandBuffer() {
        commandBuffer = queue.makeCommandBuffer()
    }

}
