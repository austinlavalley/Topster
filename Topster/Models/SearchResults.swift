//
//  SearchResults.swift
//  Topster
//
//  Created by Austin Lavalley on 9/20/23.
//

import Foundation


// MARK: - SearchResults
struct SearchResults: Codable {
    let results: Results
}

// MARK: - Results
struct Results: Codable {
    let opensearchQuery: OpensearchQuery?
    let opensearchTotalResults, opensearchStartIndex, opensearchItemsPerPage: String?
    let artistmatches: Artistmatches
}

// MARK: - Artistmatches
struct Artistmatches: Codable {
    let artist: [Artist]
}

// MARK: - Image
struct Image: Codable {
    let text: String?
    let size: String?
    
    enum CodingKeys: String, CodingKey {
        case text = "#text"
        case size = "size"
    }
}



// MARK: - OpensearchQuery
struct OpensearchQuery: Codable {
    let text, role, searchTerms, startPage: String?
}
