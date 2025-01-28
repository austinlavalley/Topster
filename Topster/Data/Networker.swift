//
//  Networker.swift
//  Topster
//
//  Created by Austin Lavalley on 9/18/23.
//

import Foundation



class Networker {
        
    func fetchApiKey() -> String {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) {
            return dict["API_KEY"] as? String ?? ""
        }
        return ""
    }
    
    func returnTopArtists(completion: @escaping (Result<[Artist], Error>) -> Void) {
        let apiKey = fetchApiKey()
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=\(apiKey)&format=json")
        else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            var topArtists: [Artist] = []
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let artistResponse = try decoder.decode(ArtistResponse.self, from: data)

                    topArtists = artistResponse.artists.artist
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
        let apiKey = fetchApiKey()
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=\(apiKey)&format=json")
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
        let apiKey = fetchApiKey()
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=artist.search&artist=\(query)&api_key=\(apiKey)&format=json") else { return }

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
        let apiKey = fetchApiKey()
        let formattedQuery = query.replacingOccurrences(of: " ", with: "-")
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=album.search&album=\(formattedQuery)&api_key=\(apiKey)&format=json") else { return }

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
