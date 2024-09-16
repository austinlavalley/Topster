//
//  fittingrows.swift
//  Topster
//
//  Created by Austin Lavalley on 9/16/24.
//

import SwiftUI

struct FittingRows: View {
    let rows : [Int]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                ForEach(rows, id: \.self) { count in
                    HStack(spacing: 4) {
                        ForEach(0..<count, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.green)
    }
}


#Preview {
    FittingRows(rows: [5,5,6,6,10,10])
}
