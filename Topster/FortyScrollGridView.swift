//
//  FortyScrollGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/2/23.
//

import SwiftUI

struct FortyScrollGridView: View {
    
//    @State private var artists: [Artist] = []
    
    var body: some View {
        VStack {
//            List(artists) { artist in
//                Text(artist.name)
//            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid1()
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid2()
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid3()
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid4()
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding()

    }
}

struct FortyScrollGrid1: View {
    var body: some View {
        ForEach(1...5, id: \.self) { index in
            Rectangle()
                .frame(width: 144, height: 144)
        }
    }
}

struct FortyScrollGrid2: View {
    var body: some View {
        ForEach(6...17, id: \.self) { index in
            Rectangle()
                .frame(width: 120, height: 120)
                .opacity(0.8)
        }
    }
}

struct FortyScrollGrid3: View {
    var body: some View {
        ForEach(18...31, id: \.self) { index in
            Rectangle()
                .frame(width: 96, height: 96)
                .opacity(0.5)
        }
    }
}

struct FortyScrollGrid4: View {
    var body: some View {
        ForEach(32...40, id: \.self) { index in
            Rectangle()
                .frame(width: 72, height: 72)
                .opacity(0.3)
        }
    }
}


struct FortyScrollGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyScrollGridView()
    }
}

