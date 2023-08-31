import SwiftUI

struct GridModel {
    var rows: Int = 4
    var columns: Int = 4
}

struct CollageView: View {
    
    @State private var gridModel = GridModel()
    
    var body: some View {
        VStack {
            Text("Grid Example")
            
            Slider(value: Binding(
                get: { Float(gridModel.rows) },
                set: { gridModel.rows = Int($0) }
            ), in: 1...12, step: 1) {
                Text("Rows: \(gridModel.rows)")
            }
            
            Slider(value: Binding(
                get: { Float(gridModel.columns) },
                set: { gridModel.columns = Int($0) }
            ), in: 1...12, step: 1) {
                Text("Columns: \(gridModel.columns)")
            }
            
            
            ScrollView(.horizontal) {
                ScrollView(.vertical) {
                    Grid(gridModel: gridModel)
                }
                .frame(width: calculateHorizontalScrollViewWidth())
            }
            .scrollIndicators(.hidden)
        }
        .padding()
    }
    
    private func calculateHorizontalScrollViewWidth() -> CGFloat {
        let columnWidth: CGFloat = 96
        let spacing: CGFloat = 8
        let totalSpacing = CGFloat(gridModel.columns - 1) * spacing
        let totalWidth = CGFloat(gridModel.columns) * columnWidth + totalSpacing
        return totalWidth
    }
}

struct Grid: View {
    let gridModel: GridModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: generateGridColumns(), spacing: 8) {
                ForEach(0..<(gridModel.rows * gridModel.columns), id: \.self) { index in
                    tile()
                }
            }
        }
    }
    
    private func generateGridColumns() -> [GridItem] {
        Array(repeating: .init(.flexible()), count: gridModel.columns)
    }
}


struct tile: View {
    var body: some View {
        
        Color.blue
        .frame(width: 96, height: 96)
        .buttonStyle(.borderedProminent)
        
    }
}




struct CollageView_Previews: PreviewProvider {
    static var previews: some View {
        CollageView()
    }
}
