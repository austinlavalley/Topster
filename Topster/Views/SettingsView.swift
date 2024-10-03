//
//  SettingsView.swift
//  Topster
//
//  Created by Austin Lavalley on 11/10/23.
//



// what settings are needed?

// dark mode
// delete data/all grids
// an area for last.fm api placement
// feedback and support
// privacy policy


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @EnvironmentObject var notificationSettings: NotificationSettings
    
    @Environment(\.openURL) var openURL
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false
    
    
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteSuccess = false
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    
                    Group {
                        Toggle("Enable dark mode 🌙", isOn: $darkModeEnabled)
                    }
                    .font(.subheadline).bold()
                    .padding()
                    .background(.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .onChange(of: darkModeEnabled) { oldValue, newValue in
                        vm.tempExportDarkMode = newValue
                    }
                    
                    Group {
                        Button("Feedback & support") {
                            openURL(URL(string: "https://topster.austinlavalley.com")!)
                        }.frame(maxWidth: .infinity, minHeight: 24)
                    }
                    .font(.subheadline).bold()
                    .padding()
                    .background(.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    Group {
                        Button("Privacy policy") {
                            openURL(URL(string: "https://topster.austinlavalley.com")!)
                        }.frame(maxWidth: .infinity, minHeight: 24)
                    }
                    .font(.subheadline).bold()
                    .padding()
                    .background(.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                    
                    Group {
                        Button {
                            showingDeleteConfirmation.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete all saved grids")
                                Spacer()
                            }
                            .frame(height: 36)
                            
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.red)
                        .padding()
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(.vertical)
                         
                    VStack {
                        Text("data provided by").italic()
                        Image("lastfm_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 64)
                    }.foregroundStyle(.secondary)
                        .padding(.top, 32)
                    
                    
                }
                .padding(.vertical)

                Spacer()
                VStack {
                    Text("🤝🤠🇺🇸")
                    Text("by Austin for Austin in Austin").font(.caption).italic().bold().foregroundColor(.secondary)
                }
            }
            
            
            
            if showingDeleteSuccess {
                VStack {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.65))
                            .frame(width: 192, height: 64)
                        
                        Text("All grids deleted 🫣").foregroundColor(.white).bold()
                    }
                }
            }
        }
        
        .confirmationDialog("You sure about that?", isPresented: $showingDeleteConfirmation) {
            Button("Delete grids", role: .destructive) {
                // delete all
                vm.deleteAllSavedGrids()
                
                withAnimation {
                    showingDeleteSuccess = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showingDeleteSuccess = false
                    }
                }
            }
        } message: {
            Text("This can't be ctrl + z'd")
        }
        
        .navigationBarTitle("Settings")
        .padding()
    }
}






func openMail(emailTo:String, subject: String, body: String) {
    if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())&body=\(body.fixToBrowserString())"),
       UIApplication.shared.canOpenURL(url)
    {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension String {
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
            //more symbols fixes here: https://mykindred.com/htmlspecialchars.php
    }
}





struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

