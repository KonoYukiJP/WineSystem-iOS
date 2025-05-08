//
//  Home.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/22.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            TabView {
                Tab("Daily Report", systemImage: "document.on.clipboard") {
                    ReportView()
                }
                .badge(2)
                
                Tab("Management", systemImage: "list.bullet") {
                    Management()
                }
            }
        } else {
            AuthenticationView()
        }
    }
}

#Preview {
    HomeView().ja()
}
