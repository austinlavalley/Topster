//
//  DraggableGridSetup.swift
//  Topster
//
//  Created by Austin Lavalley on 10/21/23.
//

import SwiftUI


struct DraggableGridSetup: View {
    
    @State private var colors: [Color] = [.red, .blue, .green, .yellow, .purple, .black, .indigo, .cyan, .mint, .brown, .orange]
    @State private var draggingItem: Color?
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                let columns = Array(repeating: GridItem(spacing: 12), count: 3)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        GeometryReader {
                            let _ = $0.size
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.gradient)
                                .draggable(color) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 1, height: 1)
                                        .onAppear {
                                            draggingItem = color
                                        }
                                }
                                .dropDestination(for: Color.self) { items, location in
                                    draggingItem = nil
                                    return false
                                } isTargeted: { status in
                                    if let draggingItem, status, draggingItem != color {
                                        if let sourceIndex = colors.firstIndex(of: draggingItem),
                                            let destinationIndex = colors.firstIndex(of: color) {
                                            withAnimation(.spring()) {
                                                let sourceItem = colors.remove(at: sourceIndex)
                                                colors.insert(sourceItem, at: destinationIndex)
                                            }
                                            }
                                    }
                                }
                        }
                        .frame(height: 96)
                    }
                }
                .padding(12)
            }
        }
    }
}

struct DraggableGridSetup_Previews: PreviewProvider {
    static var previews: some View {
        DraggableGridSetup()
    }
}
