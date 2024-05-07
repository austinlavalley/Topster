//
//  SearchHeaderView.swift
//  Topster
//
//  Created by Austin Lavalley on 5/6/24.
//

import SwiftUI

struct SearchHeaderView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Search").font(.title)
                
//                Text("alb.name").font(.subheadline).italic().foregroundStyle(.secondary)
                if ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) {
                    Text(vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ alb in
                        alb.name
                    }) ?? "Couldn't fetch album name").font(.subheadline).italic().foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SearchHeaderView()
        .environmentObject(FortyScrollGridViewModel())
}
