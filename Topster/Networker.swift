//
//  Networker.swift
//  Topster
//
//  Created by Austin Lavalley on 9/18/23.
//

import Foundation



class Networker {
    
    func returnTopArtists(completion: @escaping (Result<[Artist], Error>) -> Void) {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json")
        else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            var topArtists: [Artist] = []
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let artistInfo = try decoder.decode(ArtistInfo.self, from: data)

                    topArtists = artistInfo.artists.artist
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(topArtists))
            }
        }.resume()
    }
    
    
    func returnTopTracks(completion: @escaping (Result<[Track], Error>) -> Void) {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json")
        else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            var topTracks: [Track] = []
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let trackInfo = try decoder.decode(TrackInfo.self, from: data)

                    topTracks = trackInfo.tracks.track
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(topTracks))
            }
        }.resume()
    }
    
    
    func searchArtists(query: String, completion: @escaping (Result<[Artist], Error>) -> Void) {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=artist.search&artist=\(query)&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            
            var searchResults: [Artist] = []
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(SearchResults.self, from: data)
                    
                    searchResults = results.results.artistmatches?.artist ?? []
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(searchResults))
            }
        }.resume()
    }
    
    func searchAlbums(query: String, completion: @escaping (Result<[Album], Error>) -> Void) {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=album.search&album=\(query)&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            
            var searchResults: [Album] = []
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(SearchResults.self, from: data)
                    
                    searchResults = results.results.albummatches?.album ?? []
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(searchResults))
            }
        }.resume()
    }
    
    
}
