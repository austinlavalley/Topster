//
//  InternetImage.swift
//  Topster
//
//  Created by Austin Lavalley on 11/13/23.
//

import SwiftUI

struct InternetImage<Content: View>: View {
    var url: String
    
    @State private var image: UIImage?
    @State private var errors: String?

    @ViewBuilder var content: (Image) -> Content
    
    init(url: String, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
    }
    

    var body: some View {
        VStack {
            if let image = image {
                content(Image(uiImage: image))
            } else {
//                ProgressView()
                Rectangle().fill(.secondary)
                    .onAppear { loadImage() }
            }
        }
    }

    
    private func loadImage() {
        guard let url = URL(string: url) else {
            return
        }
        
        let urlRequest = URLRequest(url: url)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest),
           let image = UIImage(data: cachedResponse.data) {
            self.image = image
        } else {
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let data = data, let response = response, let image = UIImage(data: data) {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: urlRequest)
                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
            }.resume()
        }
    }
}

struct InternetImage_Previews: PreviewProvider
{
    static var previews: some View
    {
        InternetImage(url: "https://lastfm.freetls.fastly.net/i/u/174s/62ee1cffdde64d1e9a3462c307f83bfd.png") { image in
            image
                .resizable()
        }
    }
}
