//
//  NetworkManager.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import SwiftUI

struct TopTracksNetwork: View {
    @State private var tracks: [Track] = []

    var body: some View {
        NavigationView {
            List(tracks, id: \.name) { track in
                NavigationLink(destination: Text("\(track.artist.name)")) {
                    Text(track.name)
                }
            }
            .navigationBarTitle("Track List")
            .onAppear(perform: loadData)
        }
    }

    func loadData() {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let trackInfo = try decoder.decode(TrackInfo.self, from: data)
                    DispatchQueue.main.async {
                        self.tracks = trackInfo.tracks.track
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}


struct TrackInfo: Codable {
    let tracks: Tracks
}

struct Tracks: Codable {
    let track: [Track]
}

struct Track: Codable {
    let name: String
    let duration: String
    let artist: Artist
    // Add more properties as needed

    struct Artist: Codable {
        let name: String
        let url: String
    }
}



struct TopTracksNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopTracksNetwork()
    }
}
