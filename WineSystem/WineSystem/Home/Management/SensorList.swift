//
//  SensorList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/12/19.
//

import SwiftUI

struct SensorList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var sensors: [Sensor] = []
    @State private var tanks: [Tank] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getSensors() async {
        do {
            sensors = try await NetworkService.getSensors(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func getTanks() async {
        do {
            tanks = try await NetworkService.getTanks(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteSensor(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteSensor(sensorId: sensors[offsets.first!].id)
                sensors.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }

    var body: some View {
        List {
            ForEach(sensors) { sensor in
                NavigationLink(
                    destination:
                        SensorEditView(
                            sensor: sensor,
                            tanks: tanks,
                            onUpdateSensor: {
                                Task { await getSensors() }
                            }),
                    label: {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(sensor.name)
                                Text("[ \(sensor.unit) ]")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Group {
                                HStack {
                                    if let tankName = tanks.first(where: { $0.id == sensor.tankId})?.name {
                                        Text(tankName)
                                    }
                                    if !sensor.position.isEmpty {
                                        Text(sensor.position)
                                    }
                                }
                                Text(sensor.date, formatter: dateFormatter)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                )
            }
            .onDelete(perform: deleteSensor)
        }
        .navigationTitle("Sensors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Create Sensor", systemImage: "plus") {
                    isShowingSheet = true
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            await getSensors()
            await getTanks()
        }
        .sheet(isPresented: $isShowingSheet) {
            SensorCreateView(
                isShowingSheet: $isShowingSheet,
                systemId: systemId,
                tanks: tanks,
                onCreateSensor: {
                    Task { await getSensors() }
                }
            )
        }
    }
}

struct SensorEditView: View {
    @Environment(\.dismiss) private var dismiss
    let sensorId: Int
    @State private var newSensorRequest: NewSensorRequest
    let tanks: [Tank]
    let onUpdateSensor: () -> Void
    @State private var isAlertingName = false
    @State private var alertManager = AlertManager()
    
    init(sensor: Sensor, tanks: [Tank], onUpdateSensor: @escaping () -> Void) {
        self.sensorId = sensor.id
        _newSensorRequest = State(initialValue: .init(from: sensor))
        self.tanks = tanks
        self.onUpdateSensor = onUpdateSensor
    }
    
    private func updateSensor() async {
        if newSensorRequest.name.isEmpty {
            isAlertingName = true
            return
        }
        do {
            try await NetworkService.updateSensor(sensorId: sensorId, newSensorRequest: newSensorRequest)
            onUpdateSensor()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteSensor() {
        Task {
            do {
                try await NetworkService.deleteSensor(sensorId: sensorId)
                onUpdateSensor()
                dismiss()
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                HStack {
                    Text("Name")
                    TextField(
                        "Sensor Name",
                        text: $newSensorRequest.name
                    )
                    .multilineTextAlignment(.trailing)
                }
                .onChange(of: newSensorRequest.name) {
                    isAlertingName = false
                }
                if isAlertingName {
                    AlertText("Thie field is required.")
                }
            }
            HStack {
                Text("Unit")
                TextField(
                    "Unit",
                    text: $newSensorRequest.unit
                )
                .multilineTextAlignment(.trailing)
            }
            Picker(selection: $newSensorRequest.tankId) {
                Text("None").tag(nil as Int?)
                ForEach(tanks) { tank in
                    Text(tank.name).tag(tank.id)
                }
            } label: {
                Text("Tank")
            }
            HStack {
                Text("Position")
                TextField(
                    "Position",
                    text: $newSensorRequest.position
                )
                .multilineTextAlignment(.trailing)
            }
            DatePicker("Date", selection: $newSensorRequest.date, displayedComponents: .date)
            
            Section {
                Button("Delete") {
                    deleteSensor()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Edit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await updateSensor() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

struct SensorCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let tanks: [Tank]
    let onCreateSensor: () -> Void
    @State private var name = ""
    @State private var isAlertingName = false
    @State private var unit = ""
    @State private var tankId: Int? = nil
    @State private var position = ""
    @State private var date: Date = Date()
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func createSensor() async {
        if name.isEmpty {
            isAlertingName = true
            return
        }
        
        let newSensorRequest = NewSensorRequest(
            name: name,
            unit: unit,
            tankId: tankId,
            position: position,
            date: date
        )
        do {
            try await NetworkService.createSensor(systemId: systemId, newSensorRequest: newSensorRequest)
            onCreateSensor()
            isShowingSheet = false
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextFieldWithAlert(
                    placeholder: "Name",
                    text: $name,
                    isShowingAlert: $isAlertingName,
                    alertText: "This field is required."
                )
                .focused($focusedFieldNumber, equals: 0)
                .onSubmit { focusedFieldNumber = 1 }
                TextFieldWithAlert(
                    placeholder: "Unit",
                    text: $unit,
                    isShowingAlert: .constant(false),
                    alertText: "4 or more characters."
                )
                .focused($focusedFieldNumber, equals: 1)
                
                Section("Position") {
                    Picker(selection: $tankId) {
                        Text("None").tag(nil as Int?)
                        ForEach(tanks) { tank in
                            Text(tank.name).tag(tank.id)
                        }
                    } label: {
                        Text("Tank")
                    }
                    TextFieldWithAlert(
                        placeholder: "Position",
                        text: $position,
                        isShowingAlert: .constant(false),
                        alertText: "4 or more characters."
                    )
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
            }
            .navigationTitle("New Sensor")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createSensor() }
                    }
                }
            }
            .alert(manager: alertManager)
            .onAppear { focusedFieldNumber = 0 }
        }
    }
}

#Preview {
    NavigationStack {
        SensorList()
    }.ja()
}
