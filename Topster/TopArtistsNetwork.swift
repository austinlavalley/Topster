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
                            self.topArtists = returnedArtists 
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
}







struct TopArtistsNetwork_Previews: PreviewProvider {
    static var previews: some View {
        TopArtistsNetwork()
    }
}
