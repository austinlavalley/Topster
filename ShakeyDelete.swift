//
//  ShakeyDelete.swift
//  Topster
//
//  Created by Austin Lavalley on 10/22/23.
//

import SwiftUI
import Foundation

struct ShakeyDelete: View {
    @State private var scale: CGFloat = 1.0
    @State private var deleting = false

    @State private var start: Bool = false

    var body: some View {
        VStack {
            Text("AH")
                .font(Font.system(size: 50))
                .offset(x: start ? 30 : 0)
                .padding()
            
            Button("Shake") {
                start = true
                withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    start = false
                }
            }
        }
    }
}


struct ShakeyDelete_Previews: PreviewProvider {
    static var previews: some View {
        ShakeyDelete()
    }
}
