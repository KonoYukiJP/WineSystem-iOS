//
//  SystemCreateView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/18.
//

import Foundation
import SwiftUI

struct SystemCreateView: View {
    @Binding var isShowingSheet: Bool
    @State private var systemCreateRequest = SystemCreateRequest()
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 20)...(currentYear + 10))
    }
    @State private var isShowingPicker = false
    @State private var confirmation: String = ""
    
    @State private var isAlertingEmptySystemName: Bool = false
    @State private var isAlertingEmptyAdminName: Bool = false
    @State private var isAlertingShortPassword: Bool = false
    @State private var isAlertingWrongPassword: Bool = false
    @State private var alertManager = AlertManager()
    
    private func validateSystemInfo() -> Bool {
        let invalidRules: [(condition: Bool, invalidAction: () -> Void)] = [
            (systemCreateRequest.name.isEmpty, { isAlertingEmptySystemName = true }),
            (systemCreateRequest.ownerName.isEmpty, { isAlertingEmptyAdminName = true }),
            (systemCreateRequest.password.count < 4, { isAlertingShortPassword = true }),
            (systemCreateRequest.password != confirmation, { isAlertingWrongPassword = true })
        ]
        var isAllValid: Bool = true
        
        for invalidRule in invalidRules {
            if invalidRule.condition {
                invalidRule.invalidAction()
                isAllValid = false
            }
        }
        return isAllValid
    }
    
    private func createSystem() async {
        if !validateSystemInfo() { return }
        do {
            try await NetworkService.createSystem(systemCreateRequest)
            isShowingSheet = false
        } catch let error as NSError {
            if error.code == 400 {
                alertManager.show(title: "\(error.code)", message: "The system name already exists.")
            } else {
                alertManager.show(title: "\(error.code)", message: "Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextFieldWithAlert(
                    title: "System Name",
                    placeholder: "System Name",
                    text: $systemCreateRequest.name,
                    showAlert: $isAlertingEmptySystemName,
                    alertMessage: "This field is required."
                )
                HStack {
                    Text("Year")
                        .frame(width: 136, alignment: .leading)
                    Button(action: {
                        isShowingPicker.toggle()
                    }, label: {
                        Text(String(systemCreateRequest.year))
                            .foregroundStyle(.primary)
                    })
                    .popover(
                        isPresented: $isShowingPicker
                    ) {
                        Picker("", selection: $systemCreateRequest.year) {
                            ForEach(years, id: \.self) { year in
                                Text("\(year)").tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                TextFieldWithAlert(
                    title: "Owner Name",
                    placeholder: "Owner Name",
                    text: $systemCreateRequest.ownerName,
                    showAlert: $isAlertingEmptyAdminName,
                    alertMessage: "This field is required."
                )
                SecureFieldWithAlert(
                    title: "Password",
                    placeholder: "Password",
                    text: $systemCreateRequest.password,
                    showAlert: $isAlertingShortPassword,
                    alertMessage: "4 or more characters."
                )
                SecureFieldWithAlert(
                    title: "Confirm",
                    placeholder: "Confirm password",
                    text: $confirmation,
                    showAlert: $isAlertingWrongPassword,
                    alertMessage: "The passwords you entered do not match."
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await createSystem() }
                    }) {
                        Text("Create")
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

#Preview {
    SystemCreateView(isShowingSheet: .constant(true)).ja()
}
