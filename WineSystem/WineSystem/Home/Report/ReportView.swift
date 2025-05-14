//
//  ReportView.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/11/25.
//

import SwiftUI

struct ReportView: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @AppStorage("systemName") private var systemName = "No System"
    @AppStorage("username") private var username = "No Name"
    @State var isShowingSystemSettingsView = false
    @State var isShowingUserSettingsView = false
    @State private var works: [Work] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let columnCount = Int(geometry.size.width / 152)
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(144)), count: columnCount), spacing: 0) {
                        ForEach(works) { work in
                            NavigationLink {
                                ReportCreateView(work: work)
                            } label: {
                                TextIcon(work.localizedName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Report")
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
            .alert(manager: alertManager)
            .sheet(isPresented: $isShowingSystemSettingsView, content: {
                SystemSettingsView(
                    isShowingSheet: $isShowingSystemSettingsView
                )
            })
            .sheet(isPresented: $isShowingUserSettingsView, content: {
                UserSettingsView(
                    isShowingSheet: $isShowingUserSettingsView
                )
            })
            .task {
                do {
                    works = try await NetworkService.getWorks()
                } catch let error as NSError {
                    alertManager.show(title: "\(error.code)", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ReportView().ja()
}
