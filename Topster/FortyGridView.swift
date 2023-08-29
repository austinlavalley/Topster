//
//  FortyGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 8/29/23.
//

import SwiftUI

struct FortyGridView: View {
    
    let screenWidth: CGFloat = 480
    
    let extraLargeGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
    ]
    
    let extraLargeGridLayout2: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 4),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 4),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 4),

    ]
    
    
    let largeGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
    ]
    
    let medGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),
//        GridItem(.fixed(360 / 3), spacing: 2.6666666667),
//        GridItem(.fixed(360 / 3), spacing: 2.6666666667),
//        GridItem(.fixed(360 / 3), spacing: 2.6666666667),
    ]
    
    let smallGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),

//        GridItem(.fixed(360 / 4), spacing: 2),
//        GridItem(.fixed(360 / 4), spacing: 2),
//        GridItem(.fixed(360 / 4), spacing: 2),
//        GridItem(.fixed(360 / 4), spacing: 2),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                LazyVGrid(columns: extraLargeGridLayout, spacing: 4) {
                    // Larger Tiles (1st row)
                    ForEach(1...2, id: \.self) { index in
                        Color.green
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 168, maxHeight: .infinity)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                LazyVGrid(columns: extraLargeGridLayout2, spacing: 4) {
                    // Larger Tiles (1st row)
                    ForEach(3...5, id: \.self) { index in
                        Color.green
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 168, maxHeight: .infinity)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                LazyVGrid(columns: largeGridLayout, spacing: 4) {
                    // Larger Tiles (1st row)
                    ForEach(1...10, id: \.self) { index in
                        Color.green
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 168, maxHeight: .infinity)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                
                LazyVGrid(columns: medGridLayout, spacing: 4) {
                    ForEach(11...22, id: \.self) { index in
                        Color.purple
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: .infinity)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                    }
                }
                    
                LazyVGrid(columns: smallGridLayout, spacing: 4) {
                    // Regular Tiles (2nd-6th rows)
                    ForEach(23...42, id: \.self) { index in
                        Color.blue
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
    }
}

struct FortyGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyGridView()
    }
}

