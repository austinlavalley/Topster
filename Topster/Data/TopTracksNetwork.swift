//
//  NetworkManager.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import SwiftUI

struct TopTracksNetwork: View {
    @State private var topTracks: [Track] = []

    var body: some View {
        NavigationView {
            VStack {
                
                Button("Fetch top tracks") {
                    Networker().returnTopTracks { result in
                        
                        switch result {
                        case .success(let returnedTracks):
                            self.topTracks = returnedTracks
                        case .failure(let error):
                            print("Error fetching top tracks: \(error)")
                        }
                    }
                }
                
                List(topTracks, id: \.name) { track in
                    Text("\(track.artist.name) - \(track.name)")
                }
                .navigationBarTitle("Track List")
            }
        }
    }

//    func loadData() {
//        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else {
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            if let data = data {
//                do {
//                    let decoder = JSONDecoder()
//                    let trackInfo = try decoder.decode(TrackInfo.self, from: data)
//                    DispatchQueue.main.async {
//                        self.tracks = trackInfo.tracks.track
//                    }
//                } catch {
//                    print("Error decoding JSON: \(error)")
//                }
//            }
//        }.resume()
//    }
}






struct TopTracksNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopTracksNetwork()
    }
}
