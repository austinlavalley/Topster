//
//  ShakeyDelete.swift
//  Topster
//
//  Created by Austin Lavalley on 10/22/23.
//

import SwiftUI

struct ShakeyDelete: View {
    @State private var scale: CGFloat = 1.0
    @State private var deleting = false

    @State private var start: Bool = false

    var body: some View {
        VStack {
            Text("Tappable Object")
                .scaleEffect(scale)
                .rotationEffect(Angle(degrees: deleting ? 5 : 0))
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .onChanged { _ in
                            // Start the deletion animation
                            withAnimation(Animation.spring()) {
                                scale = 1.5
                                deleting = true
                            }
                        }
                        .onEnded { _ in
                            // End the deletion animation
                            withAnimation {
                                scale = 1.0
                                deleting = false
                            }
                        }
                )
                .opacity(deleting ? 0.0 : 1.0)
            
            VStack {
                Text("AH")
                    .font(Font.system(size: 50))
                    .offset(x: start ? 15 : 0)
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
}


struct ShakeyDelete_Previews: PreviewProvider {
    static var previews: some View {
        ShakeyDelete()
    }
}
