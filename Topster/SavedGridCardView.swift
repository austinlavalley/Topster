//
//  SavedGridCardView.swift
//  Topster
//
//  Created by Austin Lavalley on 10/28/23.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 2 : 1)
    }
}

struct SavedGridCardPreviewView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @State private var showDeleteConfirm = false
    
    let grid: GridWithType
    let currentIndex: Int
    let nonNilPairs: [Int: Album?]
    
    init(grid: GridWithType, currentIndex: Int) {
        self.grid = grid
        self.currentIndex = currentIndex
        self.nonNilPairs = grid.grid.filter({ $0.value != nil })
    }
    
    @GestureState private var isPressed = false
    @State private var isLongPressed = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                if grid.name != nil {
                    Text(grid.name ?? "NAME ISSUE").bold()
                }
            ScrollView(.horizontal) {

                    HStack {
                        ForEach(nonNilPairs.sorted(by: {$0.key < $1.key}), id: \.key) { key, album in
                            if album != nil {
                                VStack {
                                    AsyncAlbumSquare(album: album!)
                                }
                            }
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            .scrollIndicators(.hidden)
            }
            .padding()
            .background(currentIndex == vm.currentActiveGrid ? Color.blue.opacity(0.4) : .secondary.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed || isLongPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isPressed || isLongPressed)
        }

        .onTapGesture {
            isLongPressed.toggle()
            
            vm.FortyGridDict = grid.grid
            vm.currentActiveGrid = currentIndex
            vm.activeGridType = grid.type
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isLongPressed.toggle()
            }
        }

        
        .confirmationDialog("Delete this grid?", isPresented: $showDeleteConfirm) {
            Button("Delete grid", role: .destructive) {
                vm.removeFromSavedGrids(at: currentIndex)
                vm.currentActiveGrid = nil
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}


















struct SavedGridCardPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SavedGridCardPreviewView(grid: GridWithType(grid: [1: Optional(Topster.Album(name: "American Heartbreak", artist: "Zach Bryan", url: "https://www.last.fm/music/Zach+Bryan/American+Heartbreak", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("extralarge"))], streamable: "0", mbid: "")), 25: nil, 24: nil, 38: nil, 31: nil, 35: nil, 8: nil, 28: nil, 16: nil, 36: nil, 4: nil, 20: nil, 34: nil, 26: nil, 7: Optional(Topster.Album(name: "Youth", artist: "Matisyahu", url: "https://www.last.fm/music/Matisyahu/Youth", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("extralarge"))], streamable: "0", mbid: "b971671b-a135-4801-b65a-859815fb1813")), 23: nil, 21: nil, 27: nil, 39: nil, 32: nil, 11: nil, 13: nil, 18: nil, 3: nil, 40: nil, 37: nil, 19: nil, 14: nil, 29: nil, 22: nil, 30: nil, 5: nil, 33: nil, 12: nil, 10: nil, 17: nil, 2: Optional(Topster.Album(name: "Trap Lord", artist: "A$AP Ferg", url: "https://www.last.fm/music/A$AP+Ferg/Trap+Lord", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/af71b4bfdb68bce6fd5a060499f36982.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/af71b4bfdb68bce6fd5a060499f36982.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/af71b4bfdb68bce6fd5a060499f36982.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/af71b4bfdb68bce6fd5a060499f36982.png"), size: Optional("extralarge"))], streamable: "0", mbid: "776dc589-dd2e-4a24-a09d-1da520acea1c")), 9: nil, 15: nil, 6: Optional(Topster.Album(name: "some rap songs", artist: "Earl Sweatshirt", url: "https://www.last.fm/music/Earl+Sweatshirt/some+rap+songs", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("extralarge"))], streamable: "0", mbid: ""))], type: .fortyTwo, name: "Test grid name"), currentIndex: 3)
            .environmentObject(FortyScrollGridViewModel())
        
    }
}
