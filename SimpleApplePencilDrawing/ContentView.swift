//
//  ContentView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/12/31.
//

import Combine
import UIKit
import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            CanvasViewRepresentable(
                viewModel: viewModel
            )
            .ignoresSafeArea()

            Button(
                action: {
                    viewModel.doSomething()
                },
                label: {
                    Text("Button")
                }
            )
            .padding(.bottom, 28)
        }
    }
}

struct CanvasViewRepresentable: UIViewRepresentable {

    let viewModel: ContentViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> CanvasView {
        let canvasView = CanvasView()
        context.coordinator.canvasView = canvasView
        do {
            try canvasView.setup()
        } catch {
            fatalError("Failed to initialize the canvas")
        }
        return canvasView
    }

    class Coordinator {
        weak var canvasView: CanvasView?
        private var cancellables = Set<AnyCancellable>()

        init(viewModel: ContentViewModel) {
            viewModel.doSomethingSubject
                .sink { [weak self] in
                    self?.canvasView?.doSomething()
                }
                .store(in: &cancellables)
        }
    }

    func updateUIView(_ uiView: CanvasView, context: Context) {}
    static func dismantleUIView(_ uiView: CanvasView, coordinator: ()) {}
}

#Preview {
    ContentView()
}
