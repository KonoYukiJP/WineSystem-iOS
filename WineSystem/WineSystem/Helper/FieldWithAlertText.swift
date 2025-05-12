//
//  TextFieldWithAlertText.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/03.
//

import SwiftUI

struct AlertText: View {
    let alertMessage: LocalizedStringKey
    
    init(_ alertMessage: LocalizedStringKey) {
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            Text(alertMessage)
        }
        .font(.callout)
        .foregroundStyle(.red)
    }
}

struct TextFieldWithAlert: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var isShowingAlert: Bool
    let alertText: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(
                placeholder,
                text: $text
            )
            .onChange(of: text) {
                isShowingAlert = false
            }
            if isShowingAlert {
                AlertText(alertText)
            }
        }
    }
}

struct SecureFieldWithAlert: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var isShowingAlert: Bool
    let alertText: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            SecureField(
                placeholder,
                text: $text
            )
            .onChange(of: text) {
                isShowingAlert = false
            }
            if isShowingAlert {
                AlertText(alertText)
            }
        }
    }
}

struct TextFieldWithAlertTextExample: View {
    var body: some View {
        Form {
            TextFieldWithAlert(
                placeholder: "Placeholder",
                text: .constant(""),
                isShowingAlert: .constant(true),
                alertText: "This field is required."
            )
            SecureFieldWithAlert(
                placeholder: "Placeholder",
                text: .constant(""),
                isShowingAlert: .constant(true),
                alertText: "This field is required.")
        }
    }
}

#Preview {
    TextFieldWithAlertTextExample()
}
