//
//  SettingsView.swift
//  Topster
//
//  Created by Austin Lavalley on 11/10/23.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Settings")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                    Picker("Language", selection: .constant(0)) {
                        Text("English").tag(0)
                        Text("Spanish").tag(1)
                    }
                }

                Section(header: Text("Account Settings")) {
                    NavigationLink(destination: ChangePasswordView()) {
                        Text("Change Password")
                    }
                    Button(action: {
                        // Perform logout action
                    }) {
                        Text("Delete all grids")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
            }

            Section {
                Button(action: {
                    // Perform password change action
                }) {
                    Text("Change Password")
                }
            }
        }
        .navigationBarTitle("Change Password", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

