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
}






struct TopTracksNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopTracksNetwork()
    }
}
