//
//  GridLayoutSelectOption.swift
//  Topster
//
//  Created by Austin Lavalley on 9/12/24.
//

import SwiftUI

struct GridLayoutSelectOption: View {
    
    let title: String
    let subtitle: String
    
    let isSelected: Bool
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.subheadline)
            }
            
            Spacer()
            
            Circle()
                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 12, height: 12)
                )
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    GridLayoutSelectOption(title: "Title", subtitle: "Subtitle", isSelected: true)
}
