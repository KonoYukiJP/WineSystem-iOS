//
//  SwiftUIView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/29.
//

import SwiftUI

struct FeaturesView: View {
    let work: Work
    let operation: Operation
    @State private var features: [Feature] = []
    @State private var alertManager = AlertManager()
    
    private func getFeatures() async {
        do {
            features = try await NetworkService.getFeatures()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        List {
            ForEach(features) { feature in
                NavigationLink(
                    destination:
                        ReportPostView(
                            work: work,
                            operation: operation,
                            feature: feature
                        ),
                    label: {
                        Text(feature.name)
                    }
                )
            }
        }
        .task {
            await getFeatures()
        }
    }
}

#Preview {
    NavigationStack {
        FeaturesView(work: Work(id: 0, name: "Work"), operation: Operation(id: 0, name: "Operation", workId: 0))
    }.ja()
}
