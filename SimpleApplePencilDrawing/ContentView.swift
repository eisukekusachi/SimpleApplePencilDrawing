//
//  ContentView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/12/31.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MyViewControllerWrapper()
    }
}

struct MyViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        CanvasViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ContentView()
}
