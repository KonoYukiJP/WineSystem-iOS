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
                    placeholder: "Name",
                    text: $systemCreateRequest.name,
                    isShowingAlert: $isAlertingEmptySystemName,
                    alertText: "This field is required."
                )
                HStack {
                    Text("Year")
                    Spacer()
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
                Section("Owner Name") {
                    TextFieldWithAlert(
                        placeholder: "Owner Name",
                        text: $systemCreateRequest.ownerName,
                        isShowingAlert: $isAlertingEmptyAdminName,
                        alertText: "This field is required."
                    )
                }
                Section("Password") {
                    SecureFieldWithAlert(
                        placeholder: "Password",
                        text: $systemCreateRequest.password,
                        isShowingAlert: $isAlertingShortPassword,
                        alertText: "4 or more characters."
                    )
                    SecureFieldWithAlert(
                        placeholder: "Confirm password",
                        text: $confirmation,
                        isShowingAlert: $isAlertingWrongPassword,
                        alertText: "The passwords you entered do not match."
                    )
                }
            }
            .navigationTitle("System")
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
