//
//  TopArtistsNetwork.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import SwiftUI

struct TopArtistsNetwork: View {
    
    @State private var topArtists: [Artist] = []
    @State private var loadError: String?

    
    var body: some View {
        NavigationView {
            
            VStack {
                Button("Fetch Top Artists") {
                    Task {
                        do {
                            topArtists = try await Networker().returnTopArtists()
                            loadError = nil
                        } catch {
                            loadError = error.localizedDescription
                        }
                    }
                }

                if let loadError {
                    Text(loadError).font(.footnote).foregroundStyle(.secondary)
                }
                
                List(Array(topArtists.enumerated()), id: \.offset) { _, artist in
                    Text(artist.name ?? "n/a")
                }
            }
        }
    }
}


struct TopArtistsNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopArtistsNetwork()
    }
}
