//
//  ContentView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/12/31.
//

import UIKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        MyViewControllerWrapper()
    }
}

struct MyViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let canvasView = CanvasView()
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        do {
            try canvasView.setup()
        } catch {
            fatalError("Failed to initialize the canvas")
        }
    }
}

#Preview {
    ContentView()
}
