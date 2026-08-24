//
//  NetworkManager.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import SwiftUI

struct TopTracksNetwork: View {
    @State private var topTracks: [Track] = []
    @State private var loadError: String?

    var body: some View {
        NavigationView {
            VStack {
                
                Button("Fetch top tracks") {
                    Task {
                        do {
                            topTracks = try await Networker().returnTopTracks()
                            loadError = nil
                        } catch {
                            loadError = error.localizedDescription
                        }
                    }
                }

                if let loadError {
                    Text(loadError).font(.footnote).foregroundStyle(.secondary)
                }
                
                List(Array(topTracks.enumerated()), id: \.offset) { _, track in
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
