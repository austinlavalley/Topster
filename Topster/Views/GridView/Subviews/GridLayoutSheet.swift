//
//  GridLayoutSheet.swift
//  Topster
//
//  Created by Austin Lavalley on 9/12/24.
//

import SwiftUI

struct GridLayoutSheet: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        VStack {
            
            HStack {
                ZStack {
                    Rectangle()
                        .fill(vm.activeGridType == .fortyTwo ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: vm.activeGridType == .fortyTwo ? 2 : 0)
                        }
                    
                    VStack {
                        Text("40").font(.title).bold()
                        Text("Grid").font(.title2).bold()
                    }
                    .foregroundStyle(vm.activeGridType == .fortyTwo ? Color.primary : .white)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                
                ZStack {
                    Rectangle()
                        .fill(vm.activeGridType == .twentyFive ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: vm.activeGridType == .twentyFive ? 2 : 0)
                        }
                    
                    VStack {
                        Text("25").font(.title).bold()
                        Text("Grid").font(.title2).bold()
                    }
                    .foregroundStyle(vm.activeGridType == .twentyFive ? Color.primary : .white)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            
            
            HStack {
                ZStack {
                    Rectangle()
                        .fill(vm.activeGridType == .twenty ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: vm.activeGridType == .twenty ? 2 : 0)
                        }
                    
                    VStack {
                        Text("20").font(.title).bold()
                        Text("Grid").font(.title2).bold()
                    }
                    .foregroundStyle(vm.activeGridType == .twenty ? Color.primary : .white)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                
                ZStack {
                    Rectangle()
                        .fill(vm.activeGridType == .twentyWide ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: vm.activeGridType == .twentyWide ? 2 : 0)
                        }
                    
                    VStack {
                        Text("20w").font(.title).bold()
                        Text("Grid").font(.title2).bold()
                    }
                    .foregroundStyle(vm.activeGridType == .twentyWide ? Color.primary : .white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.padding()
    }
}

#Preview {
    GridLayoutSheet()
        .environmentObject(FortyScrollGridViewModel())
}
