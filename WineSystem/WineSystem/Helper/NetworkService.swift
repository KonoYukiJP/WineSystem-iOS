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
    
    private static func request<T: Decodable>(
        path: String,
        method: String
    ) async throws -> T {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if (200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    private static func request<T: Decodable, U: Encodable>(
        path: String,
        method: String,
        body: U
    ) async throws -> T {
        guard let url = URL(string: "\(apiRootURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        } else {
            let response = try JSONDecoder().decode(Response.self, from: data)
            throw NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
    }
    
    static func login(systemId: Int, loginRequest: LoginRequest) async throws -> String {
        return try await request(path: "/systems/\(systemId)/login", method: "POST", body: loginRequest)
    }
    static func updateBackup(filename: String) async throws {
        let _: Response = try await request(path: "/backups/\(filename)", method: "PUT")
    }
    
    private static func get<T: Decodable>(path: String) async throws -> T {
        return try await request(path: path, method: "GET")
    }
    static func getSystems() async throws -> [System] {
        return try await get(path: "/systems")
    }
    static func getSystem() async throws -> System {
        return try await get(path: "/systems/me")
    }
    static func getUsers() async throws -> [User] {
        return try await get(path: "/users")
    }
    static func getUsername() async throws -> String {
        let username: String = try await get(path: "/users/me/name")
        return username
    }
    static func getRoles() async throws -> [Role] {
        return try await get(path: "/roles")
    }
    static func getActions() async throws -> [Action] {
        return try await get(path: "/actions")
    }
    static func getResources() async throws -> [Resource] {
        return try await get(path: "/resources")
    }
    static func getTanks() async throws -> [Tank] {
        return try await get(path: "/tanks")
    }
    static func getMaterials() async throws -> [Material] {
        return try await get(path: "/materials")
    }
    static func getSensors() async throws -> [Sensor] {
        return try await get(path: "/sensors")
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
    static func getReports() async throws -> [Report] {
        return try await get(path: "/reports")
    }
    static func getBackups() async throws -> [Backup] {
        return try await get(path: "/backups")
    }
    
    private static func post<T: Encodable>(path: String, body: T) async throws {
        let _: Response = try await request(path: path, method: "POST", body: body)
    }
    static func createSystem(_ systemCreateRequest: SystemCreateRequest) async throws {
        try await post(path: "/systems", body: systemCreateRequest)
    }
    static func createUser(userCreateRequest: UserCreateRequest) async throws {
        try await post(path: "/users", body: userCreateRequest)
    }
    static func createMaterial(newMaterialRequest: NewMaterialRequest) async throws {
        try await post(path: "/materials", body: newMaterialRequest)
    }
    static func createSensor(newSensorRequest: NewSensorRequest) async throws {
        try await post(path: "/sensors", body: newSensorRequest)
    }
    static func createRole(roleCreateRequest: RoleCreateRequest) async throws {
        try await post(path: "/roles", body: roleCreateRequest)
    }
    static func createTank(newTankRequest: NewTankRequest) async throws {
        try await post(path: "/tanks", body: newTankRequest)
    }
    static func createReport(reportCreateRequest: ReportCreateRequest) async throws {
        try await post(path: "/reports", body: reportCreateRequest)
    }
    static func createBackup(backupCreateRequest: BackupCreateRequest) async throws {
        try await post(path: "/backups", body: backupCreateRequest)
    }
    
    private static func put<T: Encodable>(path: String, body: T) async throws {
        let _: Response = try await request(path: path, method: "PUT", body: body)
    }
    static func updateUsername(usernameUpdateRequest: UsernameUpdateRequest) async throws {
        try await put(path: "/users/me/name", body: usernameUpdateRequest)
    }
    static func updatePassword(passwordUpdateRequest: PasswordUpdateRequest) async throws {
        try await put(path: "/users/me/password", body: passwordUpdateRequest)
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
    static func updateReport(reportId: Int, reportUpdateRequest: ReportUpdateRequest) async throws {
        try await put(path: "/reports/\(reportId)", body: reportUpdateRequest)
    }
    
    private static func patch<T: Encodable>(path: String, body: T) async throws {
        let _: Response = try await request(path: path, method: "PATCH", body: body)
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
        let _: Response = try await request(path: path, method: "DELETE")
    }
    static func deleteSystem() async throws {
        try await delete(path: "/systems/me")
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
    static func deleteReport(reportId: Int) async throws {
        try await delete(path: "/reports/\(reportId)")
    }
    static func deleteBackup(filename: String) async throws {
        try await delete(path: "/backups/\(filename)")
    }
}
