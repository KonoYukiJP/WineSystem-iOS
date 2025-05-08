//
//  View.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/09.
//

import SwiftUI

extension View {
    func en() -> some View {
        self.environment(\.locale, .init(identifier: "en"))
    }
    func ja() -> some View {
        self.environment(\.locale, .init(identifier: "ja"))
    }
}
