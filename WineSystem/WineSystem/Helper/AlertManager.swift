//
//  AlertManager.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/13.
//

import Observation
import SwiftUI

@Observable
class AlertManager {
    var isShowing = false
    var title = "No Title"
    var message = "No Message"
    var onDismiss: (() -> Void)? = nil

    func show(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
        self.isShowing = true
    }
}

struct AlertModifier: ViewModifier {
    @Bindable var alertManager: AlertManager

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $alertManager.isShowing) {
                Alert(
                    title: Text(alertManager.title),
                    message: Text(alertManager.message),
                    dismissButton: .default(
                        Text("OK"),
                        action: {
                            alertManager.onDismiss?()
                            alertManager.onDismiss = nil
                        }
                    )
                )
            }
    }
}

extension View {
    func alert(manager: AlertManager) -> some View {
        self.modifier(AlertModifier(alertManager: manager))
    }
}
