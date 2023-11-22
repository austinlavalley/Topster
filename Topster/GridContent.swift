//
//  GridContent.swift
//  Topster
//
//  Created by Austin Lavalley on 11/22/23.
//

import SwiftUI

struct GridContent: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        Spacer()
        
        ScrollView(.horizontal) {
            HStack {
                FortyScrollGridMaster(start: 0, end: 5, size: 144, squareColor: .secondary)
            }
        }
        
        ScrollView(.horizontal) {
            HStack {
                FortyScrollGridMaster(start: 5, end: 17, size: 120, squareColor: .secondary.opacity(0.8))
            }
        }
        
        ScrollView(.horizontal) {
            HStack {
                FortyScrollGridMaster(start: 17, end: 31, size: 96, squareColor: .secondary.opacity(0.6))
            }
        }
        
        ScrollView(.horizontal) {
            HStack {
                FortyScrollGridMaster(start: 31, end: 40, size: 72, squareColor: .secondary.opacity(0.4))
                
            }
        }
    }
}

struct GridContent_Previews: PreviewProvider {
    static var previews: some View {
        GridContent()
    }
}
