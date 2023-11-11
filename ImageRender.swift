//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI

// An example view to render
struct RenderView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.largeTitle)
            .foregroundStyle(.white)
            .padding()
            .background(.blue)
            .clipShape(Capsule())
    }
}

struct ImageRender: View {
    @State private var text = "Your text here"
    @State private var renderedImage = Image(systemName: "photo")
    @Environment(\.displayScale) var displayScale

    var body: some View {
        VStack {
            renderedImage

            ShareLink("Export", item: renderedImage, preview: SharePreview(Text("Shared image"), image: renderedImage))

            TextField("Enter some text", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
        .onChange(of: text) { _ in render() }
        .onAppear { render() }
    }

    @MainActor func render() {
        let renderer = ImageRenderer(content: RenderView(text: text))

        // make sure and use the correct display scale for this device
        renderer.scale = displayScale

        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

struct ImageRender_Previews: PreviewProvider {
    static var previews: some View {
        ImageRender()
    }
}
