//
//  ViewController.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/01.
//

import UIKit
import Combine

class ViewController: UIViewController {

    @IBOutlet private weak var canvasView: MTKRenderTextureView!

    private let canvasViewModel = CanvasViewModel()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeEvents()
    }

}

extension ViewController {

    private func subscribeEvents() {
        canvasView.publisher(for: \.renderTextureSize)
            .filter { $0 != .zero }
            .sink { [weak self] newSize in
                guard let `self` else { return }
                self.canvasViewModel.onRenderTextureSizeChange(renderTarget: self.canvasView)
            }
            .store(in: &cancellables)
    }

}
