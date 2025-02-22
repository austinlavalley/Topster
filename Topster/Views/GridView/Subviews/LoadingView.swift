//
//  LoadingView.swift
//  Topster
//
//  Created by Austin Lavalley on 4/27/24.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            
//            Image("localAlbum")

            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView().scaleEffect(2)
//                Text("Putting it all together...").bold().frame(width: 160).multilineTextAlignment(.center)
//                Text("Building your grid...").bold().frame(width: 160).multilineTextAlignment(.center)

            }
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                .frame(width: 200, height: 200)
            }
            
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
