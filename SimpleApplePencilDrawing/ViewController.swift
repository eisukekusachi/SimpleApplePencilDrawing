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
        bindViewModel()
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

        // Add a gesture recognizer to clear the canvas when the screen is tapped with three fingers.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTouchesRequired = 3
        canvasView.addGestureRecognizer(tapGesture)
    }

    private func bindViewModel() {
        canvasViewModel.pauseDisplayLinkPublish
            .receive(on: DispatchQueue.main)
            .assign(to: \.isDisplayLinkPaused, on: canvasView)
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

extension ViewController {

    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        canvasViewModel.clearButtonTapped(renderTarget: canvasView)
    }

}
