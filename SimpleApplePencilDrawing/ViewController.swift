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
        canvasView.addGestureRecognizer(
            FingerInputGestureRecognizer(self)
        )

        canvasView.publisher(for: \.renderTextureSize)
            .filter { $0 != .zero }
            .sink { [weak self] newSize in
                guard let `self` else { return }
                self.canvasViewModel.onRenderTextureSizeChange(renderTarget: self.canvasView)
            }
            .store(in: &cancellables)
    }

}

extension ViewController: FingerInputGestureSender {

    func sendFingerTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onFingerInputGesture(
            touches: touches.map { TouchPoint(touch: $0, view: view) },
            renderTarget: canvasView
        )
    }

}
