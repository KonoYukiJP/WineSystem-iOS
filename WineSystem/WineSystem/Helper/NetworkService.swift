//
//  NetworkService.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/30.
//

import Foundation

struct NetworkService {
    //static let apiRootURL: String = "http://127.0.0.1:5000"
    //static let apiRootURL: String = "http://163.43.218.237"
    static let apiRootURL: String = "https://winesystem.servehttp.com"
    
    private static func get<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if (200...299).contains(httpResponse.statusCode) {
            return try decoder.decode(T.self, from: data)
        } else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func getSystems() async throws -> [System] {
        return try await get(path: "/systems")
    }
    static func getSystem(systemId: Int) async throws -> System {
        return try await get(path: "/systems/\(systemId)")
    }
    static func getUsers(systemId: Int) async throws -> [User] {
        return try await get(path: "/systems/\(systemId)/users")
    }
    static func getUsername() async throws -> String {
        let username: String = try await get(path: "/users/me/name")
        return username
    }
    static func getRoles(systemId: Int) async throws -> [Role] {
        return try await get(path: "/systems/\(systemId)/roles")
    }
    static func getActions() async throws -> [Action] {
        return try await get(path: "/actions")
    }
    static func getResources() async throws -> [Resource] {
        return try await get(path: "/resources")
    }
    static func getTanks(systemId: Int) async throws -> [Tank] {
        return try await get(path: "/systems/\(systemId)/tanks")
    }
    static func getMaterials(systemId: Int) async throws -> [Material] {
        return try await get(path: "/systems/\(systemId)/materials")
    }
    static func getSensors(systemId: Int) async throws -> [Sensor] {
        return try await get(path: "/systems/\(systemId)/sensors")
    }
    static func getWorks() async throws -> [Work] {
        return try await get(path: "/works")
    }
    static func getOperations() async throws -> [Operation] {
        return try await get(path: "/operations")
    }
    static func getFeatures() async throws -> [Feature] {
        return try await get(path: "/features")
    }
    static func getReports(systemId: Int) async throws -> [Report] {
        return try await get(path: "/systems/\(systemId)/reports")
    }
    static func getUsersAsItems(systemId: Int) async throws -> [Item] {
        return try await get(path: "/systems/\(systemId)/users")
    }
    static func getFeaturesAsItems() async throws -> [Item] {
        return try await get(path: "/features")
    }
    static func getTanksAsItems(systemId: Int) async throws -> [Item] {
        return try await get(path: "/systems/\(systemId)/tanks")
    }
    static func getMaterialsAsItems(systemId: Int) async throws -> [Item] {
        return try await get(path: "/systems/\(systemId)/materials")
    }
    static func getBackups() async throws -> Backup {
        return try await get(path: "/backups")
    }
    private static func post<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func login(systemId: Int, loginRequest: LoginRequest) async throws -> String {
        guard let url = URL(string: "\(apiRootURL)/systems/\(systemId)/login") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(loginRequest)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if (200...299).contains(httpResponse.statusCode) {
            let loginResponse: LoginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            return loginResponse.token
        } else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func createSystem(_ systemCreateRequest: SystemCreateRequest) async throws {
        try await post(path: "/systems", body: systemCreateRequest)
    }
    static func createUser(systemId: Int, userCreateRequest: UserCreateRequest) async throws {
        try await post(path: "/systems/\(systemId)/users", body: userCreateRequest)
    }
    static func createMaterial(systemId: Int, newMaterialRequest: NewMaterialRequest) async throws {
        try await post(path: "/systems/\(systemId)/materials", body: newMaterialRequest)
    }
    static func createSensor(systemId: Int, newSensorRequest: NewSensorRequest) async throws {
        try await post(path: "/systems/\(systemId)/sensors", body: newSensorRequest)
    }
    static func createRole(systemId: Int, roleCreateRequest: RoleCreateRequest) async throws {
        try await post(path: "/systems/\(systemId)/roles", body: roleCreateRequest)
    }
    static func createTank(systemId: Int, newTankRequest: NewTankRequest) async throws {
        try await post(path: "/systems/\(systemId)/tanks", body: newTankRequest)
    }
    static func createReport(systemId: Int, newReportRequest: NewReportRequest) async throws {
        try await post(path: "/systems/\(systemId)/reports", body: newReportRequest)
    }
    static func createBackup(backupCreateRequest: BackupCreateRequest) async throws {
        try await post(path: "/backups", body: backupCreateRequest)
    }
    private static func put<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func updateUsername(usernameUpdateRequest: UsernameUpdateRequest) async throws {
        try await put(path: "/users/me/name", body: usernameUpdateRequest)
    }
    static func updatePassword(passwordUpdateRequest: PasswordUpdateRequest) async throws {
        try await put(path: "/users/ma/password", body: passwordUpdateRequest)
    }
    static func updateMaterial(materialId: Int, newMaterialRequest: NewMaterialRequest) async throws {
        try await put(path: "/materials/\(materialId)", body: newMaterialRequest)
    }
    static func updateTank(tankId: Int, newTankRequest: NewTankRequest) async throws {
        try await put(path: "/tanks/\(tankId)", body: newTankRequest)
    }
    static func updateSensor(sensorId: Int, newSensorRequest: NewSensorRequest) async throws {
        try await put(path: "/sensors/\(sensorId)", body: newSensorRequest)
    }
    static func updateUser(userId: Int, userUpdateRequest: UserUpdateRequest) async throws {
        try await put(path: "/users/\(userId)", body: userUpdateRequest)
    }
    static func updateReport(reportId: Int, newReportRequest: NewReportRequest) async throws {
        try await put(path: "/reports/\(reportId)", body: newReportRequest)
    }
    static func updateBackup(backupUpdateRequest: BackupUpdateRequest) async throws {
        try await put(path: "/backups", body: backupUpdateRequest)
    }
    private static func patch<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func updateSystemName(systemId: Int, systemNameUpdateRequest: SystemNameUpdateRequest) async throws {
        try await patch(path: "/systems/\(systemId)", body: systemNameUpdateRequest)
    }
    static func updateSystemYear(systemId: Int, systemYearUpdateRequest: SystemYearUpdateRequest) async throws {
        try await patch(path: "/systems/\(systemId)", body: systemYearUpdateRequest)
    }
    static func updateRole(roleId: Int, roleUpdateRequest: RoleUpdateRequest) async throws {
        try await patch(path: "/roles/\(roleId)", body: roleUpdateRequest)
    }
    private static func delete(path: String) async throws {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    static func deleteSystem(systemId: Int) async throws {
        try await delete(path: "/systems/\(systemId)")
    }
    static func deleteUser(userId: Int) async throws {
        try await delete(path: "/users/\(userId)")
    }
    static func deleteRole(roleId: Int) async throws {
        try await delete(path: "/roles/\(roleId)")
    }
    static func deleteMaterial(materialId: Int) async throws {
        try await delete(path: "/materials/\(materialId)")
    }
    static func deleteSensor(sensorId: Int) async throws {
        try await delete(path: "/sensors/\(sensorId)")
    }
    static func deleteTank(tankId: Int) async throws {
        try await delete(path: "/tanks/\(tankId)")
    }
    static func deleteBackup(filename: String) async throws {
        try await delete(path: "/backups/\(filename)")
    }
}
