//
//  ContentView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/16.
//

import SwiftUI

struct AuthenticationView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var isShowingAdmiSheet = false
    @State private var isShowingUserSheet = false
    
    var body: some View {
        NavigationStack {
            HStack {
                ButtonIcon(iconName: "New System", action: {
                    isShowingAdmiSheet = true
                })
                .sheet(isPresented: $isShowingAdmiSheet, content: {SystemCreateView(isShowingSheet: $isShowingAdmiSheet)})
                ButtonIcon(iconName: "Login", action: {
                    isShowingUserSheet = true
                })
                .sheet(isPresented: $isShowingUserSheet, content: {LoginView(isShowingSheet: $isShowingUserSheet, isLoggedIn: $isLoggedIn)})
            }
        }
    }
}

#Preview {
    AuthenticationView().ja()
}
