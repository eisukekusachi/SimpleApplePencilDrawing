//
//  MTLTextureExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

extension MTLTexture {

    var size: CGSize {
        return CGSize(width: self.width, height: self.height)
    }

}
