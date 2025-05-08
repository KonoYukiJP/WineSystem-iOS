//
//  ManagementView.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/11/25.
//

import SwiftUI

struct Management: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @AppStorage("systemName") private var systemName = "No System"
    @AppStorage("username") private var username = "No Name"
    @State private var isShowingUserSettingsView = false
    @State private var isShowingSystemSettingsView = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let columnCount = geometry.size.width < 600 ? 2 : 4
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(144)), count: columnCount), spacing: 0) {
                    NavigationLink(
                        destination:
                            UserList(),
                        label: {
                            TextIcon("User")
                        }
                    )
                    NavigationLink(
                        destination:
                            RoleList(),
                        label: {
                            TextIcon("Role")
                        }
                    )
                    NavigationLink(
                        destination:
                            MaterialList(),
                        label: {
                            TextIcon("Material")
                        }
                    )
                    NavigationLink(
                        destination:
                            TankList(),
                        label: {
                            TextIcon("Tank")
                        }
                    )
                    NavigationLink(
                        destination:
                            SensorList(),
                        label: {
                            TextIcon("Sensor")
                        }
                    )
                    ButtonIcon(iconName: "バックアップ", action: {})
                }
            }
            .navigationTitle("Management")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSystemSettingsView = true
                    }) {
                        HStack {
                            Image(systemName: "house")
                            Text(systemName)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingUserSettingsView = true
                    }) {
                        HStack {
                            Image(systemName: "person")
                            Text(username)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingUserSettingsView, content: {
                UserSettingsView(
                    isShowingSheet: $isShowingUserSettingsView
                )
            })
            .sheet(isPresented: $isShowingSystemSettingsView, content: {
                SystemSettingsView(
                    isShowingSheet: $isShowingSystemSettingsView
                )
            })
        }
    }
}

#Preview {
    Management().ja()
}
