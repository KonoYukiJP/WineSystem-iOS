//
//  ValidatedTextField.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/03.
//

import SwiftUI

struct AlertText: View {
    var alertMessage: LocalizedStringKey
    
    init(_ alertMessage: LocalizedStringKey) {
        self.alertMessage = alertMessage
    }
    
    var body: some View {
        Text("\(Image(systemName: "exclamationmark.circle"))\(alertMessage)")
            .font(.callout)
            .foregroundStyle(.red)
    }
}

struct TextFieldWithAlert: View {
    var title: LocalizedStringKey
    var placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var showAlert: Bool
    var alertMessage: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .frame(width: 136, alignment: .leading)
                TextField(
                    placeholder,
                    text: $text
                )
                .onChange(of: text) {
                    showAlert = false
                }
            }
            if showAlert {
                AlertText(alertMessage)
            }
        }
    }
}

struct SecureFieldWithAlert: View {
    var title: LocalizedStringKey
    var placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var showAlert: Bool
    var alertMessage: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .frame(width: 136, alignment: .leading)
                SecureField(
                    placeholder,
                    text: $text
                )
                .onChange(of: text) {
                    showAlert = false
                }
            }
            if showAlert {
                AlertText(alertMessage)
            }
        }
    }
}

struct TextFieldWithAlertExample: View {
    var body: some View {
        Form {
            TextFieldWithAlert(
                title: "Title",
                placeholder: "Placeholder",
                text: .constant(""),
                showAlert: .constant(true),
                alertMessage: "This field is required."
            )
        }
    }
}

#Preview {
    TextFieldWithAlertExample()
}
