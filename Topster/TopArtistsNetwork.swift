//
//  TopArtistsNetwork.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import SwiftUI

struct TopArtistsNetwork: View {
    @State private var topArtists: [Artist] = []
    

    var body: some View {
        NavigationView {
            List(topArtists, id: \.name) { artist in
//                Text(artist.name)
            }
            .navigationBarTitle("Top Artists")
            .onAppear(perform: fetchTopArtists)
        }
    }

    func fetchTopArtists() {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let artistInfo = try decoder.decode(ArtistInfo.self, from: data)
                    print(artistInfo.artists)
                    DispatchQueue.main.async {
                        self.topArtists = artistInfo.artists.artist
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}





struct TopArtistsNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopArtistsNetwork()
    }
}
