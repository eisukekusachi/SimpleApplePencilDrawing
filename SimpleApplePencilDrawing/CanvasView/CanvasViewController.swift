//
//  CanvasViewController.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/01.
//

import UIKit
import Combine

class CanvasViewController: UIViewController {

    private let canvasView: CanvasView = .init()

    private let canvasViewModel = CanvasViewModel()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(canvasView)

        subscribeEvents()
        bindViewModel()

        canvasViewModel.onViewDidLoad(
            canvasView: canvasView
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
        canvasViewModel.frameSize = view.frame.size
    }
}

extension CanvasViewController {

    private func subscribeEvents() {
        canvasView.addGestureRecognizer(
            PencilInputGestureRecognizer(delegate: self)
        )

        // Add a gesture recognizer to clear the canvas when the screen is tapped with three fingers.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTouchesRequired = 3
        canvasView.addGestureRecognizer(tapGesture)
    }

    private func bindViewModel() {
        canvasView.updateTexturePublisher
            .sink { [weak self] in
                guard let `self` else { return }
                self.canvasViewModel.onUpdateRenderTexture()
            }
            .store(in: &cancellables)
    }

}

extension CanvasViewController: PencilInputGestureRecognizerSender {

    func sendPencilEstimatedTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onPencilGestureDetected(
            estimatedTouches: touches,
            with: event,
            view: view
        )
    }

    func sendPencilActualTouches(_ touches: Set<UITouch>, on view: UIView) {
        canvasViewModel.onPencilGestureDetected(
            actualTouches: touches,
            view: view
        )
    }

}

extension CanvasViewController {

    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        canvasViewModel.onTapClearTexture()
    }

}
