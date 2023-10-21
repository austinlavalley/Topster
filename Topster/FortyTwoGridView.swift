import SwiftUI

struct FortyTwoGridView: View {
    
    let screenWidth: CGFloat = 480
    
    let largeGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 12), spacing: 4),
    ]
    
    let medGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),
        GridItem(.fixed(UIScreen.main.bounds.width / 3 - 8), spacing: 2.6666666667),

    ]
    
    let smallGridLayout: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),
        GridItem(.fixed(UIScreen.main.bounds.width / 4 - 6), spacing: 2),

    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
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

struct FortyTwoGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyTwoGridView()
    }
}
