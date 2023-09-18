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
            
            VStack {
                Button("Fetch Top Artists") {
                    Networker().returnTopArtists { result in
                        
                        switch result {
                        case .success(let returnedArtists):
                            self.topArtists = returnedArtists // Assign the result to the @State property
                        case .failure(let error):
                            print("Error fetching top artists: \(error)")
                        }
                    }
                }
                
                List(topArtists, id: \.name) { artist in
                    Text(artist.name ?? "n/a")
                }
            }
        }
    }

//    func fetchTopArtists() {
//        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else {
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            if let data = data {
//                do {
//                    let decoder = JSONDecoder()
//                    let artistInfo = try decoder.decode(ArtistInfo.self, from: data)

//                    DispatchQueue.main.async {
//                        self.topArtists = artistInfo.artists.artist
//                    }
//                } catch {
//                    print("Error decoding JSON: \(error)")
//                }
//            }
//        }.resume()
//    }
}







struct TopArtistsNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopArtistsNetwork()
    }
}
