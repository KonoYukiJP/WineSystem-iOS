//
//  IconButton.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/11/24.
//

import SwiftUI

struct ButtonIcon: View {
    var iconName: LocalizedStringKey
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            TextIcon(iconName)
        }
        .contentShape(RoundedRectangle(cornerRadius: 48))
    }
}

struct TextIcon: View {
    var iconName: LocalizedStringKey
    
    init(_ iconName: LocalizedStringKey) {
        self.iconName = iconName
    }
    
    var body: some View {
        Text(iconName)
            .frame(width: 144, height: 144)
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .stroke(.accent, lineWidth: 1)
            )
            .padding(4)
    }
}

#Preview {
    VStack {
        HStack {
            ButtonIcon(iconName: "Title", action: {})
            ButtonIcon(iconName: "Title", action: {})
        }
        HStack {
            ButtonIcon(iconName: "Title", action: {})
            ButtonIcon(iconName: "Title", action: {})
        }
    }
}
