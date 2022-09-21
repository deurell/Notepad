//
//  ContentView.swift
//  PKDemo
//
//  Created by Mikael Deurell on 2022-09-21.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    let canvasView = PKCanvasView()
    let picker = PKToolPicker()

    var body: some View {
        VStack {
            ARContainerViewRepresentable(canvasView: canvasView)
            PKCanvasViewRepresentable(canvasView: canvasView, picker: picker)
        }.ignoresSafeArea()
    }
}

struct PKCanvasViewRepresentable : UIViewRepresentable {
    let canvasView: PKCanvasView
    let picker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        self.canvasView.tool = PKInkingTool(.pen, color: .black, width: 20)
        self.canvasView.becomeFirstResponder()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        picker.addObserver(canvasView)
        picker.setVisible(true, forFirstResponder: uiView)
    }
}

struct ARContainerViewRepresentable: UIViewRepresentable {
    let canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> NotepadView {
        let arView = NotepadView(frame: .zero)
        arView.setup(canvasView: canvasView)
        return arView
    }
    
    func updateUIView(_ uiView: NotepadView, context: Context) { }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
