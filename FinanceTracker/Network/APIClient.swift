import Foundation
import UIKit

// MARK: - Data Models

struct Transaction: Codable, Identifiable {
    let id: Int64?
    var text: String = ""
    var amount: Double
    var type: String        // "INCOME" or "EXPENSE"
    var category: String?
    var categoryId: Int64?
    var date: String        // "yyyy-MM-dd"
    var note: String?
    var imageUrl: String?
    var presignedImageUrl: String?
}

struct Category: Codable, Identifiable {
    let id: Int64
    var name: String
    var type: String
}

struct RecurringTransaction: Codable, Identifiable {
    let id: Int64?
    var name: String
    var amount: Double
    var type: String
    var frequency: String   // "DAILY","WEEKLY","MONTHLY"
    var startDate: String
    var nextRunDate: String?
    var active: Bool
    var categoryId: Int64?
}

struct TransactionPage: Codable {
    let content: [Transaction]
    let totalPages: Int?
    let totalElements: Int?
}

struct SummaryResponse: Codable {
    let cashFlow: CashFlow
    let incomeCategories: [CategoryStat]
    let expenseCategories: [CategoryStat]
}

struct CashFlow: Codable {
    let totalIncome: Double?
    let totalExpense: Double?
}

struct CategoryStat: Codable, Identifiable {
    var id: String { name }
    let name: String
    let value: Double
}

struct ProfileResponse: Codable {
    let username: String?
    let email: String?
    let presignedImageUrl: String?
}

struct ImageUploadResponse: Codable {
    let imageUrl: String?
    let presignedImageUrl: String?
}

struct AvatarUploadResponse: Codable {
    let presignedImageUrl: String?
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(Int, String)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noToken: return "Not authenticated"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .unknown(let e): return e.localizedDescription
        }
    }
}

// MARK: - APIClient

@MainActor
class APIClient {
    static let shared = APIClient()
    private let baseURL: String = {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, !url.isEmpty else {
            return "https://www.wisefintrakr.com"   // fallback
        }
        return url
    }()
    private let session = URLSession.shared

    private init() {}

    var token: String? {
        get { UserDefaults.standard.string(forKey: "jwt_token") }
        set { UserDefaults.standard.set(newValue, forKey: "jwt_token") }
    }

    // MARK: - Request Helpers

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        return url
    }

    private func authorizedRequest(url: URL, method: String = "GET") throws -> URLRequest {
        guard let token = token else { throw APIError.noToken }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        if !(200..<300).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(http.statusCode, msg)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func executeVoid(_ request: URLRequest) async throws {
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        if !(200..<300).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode, "Request failed")
        }
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> String {
        let url = try makeURL("/api/auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        if !(200..<300).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Login failed"
            throw APIError.httpError(http.statusCode, msg)
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let tok = json["token"] as? String {
            return tok
        }
        throw APIError.decodingError(URLError(.cannotParseResponse))
    }

    func signup(username: String, password: String, email: String) async throws {
        let url = try makeURL("/api/auth/signup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password, "email": email]
        req.httpBody = try JSONEncoder().encode(body)
        try await executeVoid(req)
    }

    // MARK: - Transactions

    func getSummary() async throws -> SummaryResponse {
        let url = try makeURL("/api/transactions/summary")
        let req = try authorizedRequest(url: url)
        return try await execute(req)
    }

    func getHistory(page: Int = 0, size: Int = 20) async throws -> TransactionPage {
        var components = URLComponents(string: baseURL + "/api/transactions/history")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        let url = components.url!
        let req = try authorizedRequest(url: url)
        return try await execute(req)
    }

    func addTransaction(_ tx: Transaction) async throws -> Transaction {
        let url = try makeURL("/api/transactions/add")
        var req = try authorizedRequest(url: url, method: "POST")
        req.httpBody = try JSONEncoder().encode(tx)
        return try await execute(req)
    }

    func updateTransaction(_ tx: Transaction) async throws {
        guard let id = tx.id else { throw APIError.invalidURL }
        let url = try makeURL("/api/transactions/update/\(id)")
        var req = try authorizedRequest(url: url, method: "PUT")
        req.httpBody = try JSONEncoder().encode(tx)
        try await executeVoid(req)
    }

    func deleteTransaction(id: Int64) async throws {
        let url = try makeURL("/api/transactions/\(id)")
        let req = try authorizedRequest(url: url, method: "DELETE")
        try await executeVoid(req)
    }

    func uploadTransactionImage(id: Int64, imageData: Data) async throws -> ImageUploadResponse {
        let url = try makeURL("/api/transactions/\(id)/image")
        guard let token = token else { throw APIError.noToken }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = makeMultipartBody(data: imageData, fieldName: "image", fileName: "receipt.jpg", mimeType: "image/jpeg", boundary: boundary)
        return try await execute(req)
    }

    // MARK: - Categories

    func getCategories(type: String) async throws -> [Category] {
        var components = URLComponents(string: baseURL + "/api/categories")!
        components.queryItems = [URLQueryItem(name: "type", value: type)]
        let url = components.url!
        let req = try authorizedRequest(url: url)
        return try await execute(req)
    }

    func addCategory(name: String, type: String) async throws -> Category {
        let url = try makeURL("/api/categories")
        var req = try authorizedRequest(url: url, method: "POST")
        let body = ["name": name, "type": type]
        req.httpBody = try JSONEncoder().encode(body)
        return try await execute(req)
    }

    // MARK: - Recurring

    func getRecurring() async throws -> [RecurringTransaction] {
        let url = try makeURL("/api/recurring")
        let req = try authorizedRequest(url: url)
        return try await execute(req)
    }

    func addRecurring(_ rt: RecurringTransaction) async throws -> RecurringTransaction {
        let url = try makeURL("/api/recurring")
        var req = try authorizedRequest(url: url, method: "POST")
        req.httpBody = try JSONEncoder().encode(rt)
        return try await execute(req)
    }

    func toggleRecurring(id: Int64) async throws -> RecurringTransaction {
        let url = try makeURL("/api/recurring/\(id)")
        let req = try authorizedRequest(url: url, method: "PUT")
        return try await execute(req)
    }

    func deleteRecurring(id: Int64) async throws {
        let url = try makeURL("/api/recurring/\(id)")
        let req = try authorizedRequest(url: url, method: "DELETE")
        try await executeVoid(req)
    }

    // MARK: - Profile

    func getProfile() async throws -> ProfileResponse {
        let url = try makeURL("/api/profile")
        let req = try authorizedRequest(url: url)
        return try await execute(req)
    }

    func updateProfile(email: String) async throws {
        let url = try makeURL("/api/profile")
        var req = try authorizedRequest(url: url, method: "PUT")
        let body = ["email": email]
        req.httpBody = try JSONEncoder().encode(body)
        try await executeVoid(req)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let url = try makeURL("/api/profile/password")
        var req = try authorizedRequest(url: url, method: "PUT")
        let body = ["currentPassword": currentPassword, "newPassword": newPassword]
        req.httpBody = try JSONEncoder().encode(body)
        try await executeVoid(req)
    }

    func uploadAvatar(imageData: Data) async throws -> AvatarUploadResponse {
        let url = try makeURL("/api/profile/avatar")
        guard let token = token else { throw APIError.noToken }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = makeMultipartBody(data: imageData, fieldName: "image", fileName: "avatar.jpg", mimeType: "image/jpeg", boundary: boundary)
        return try await execute(req)
    }

    // MARK: - Multipart Helper

    private func makeMultipartBody(data: Data, fieldName: String, fileName: String, mimeType: String, boundary: String) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    // MARK: - CSV Export
    /// Downloads all transactions as CSV bytes. Throws on network/auth error.
    func exportTransactionsCsv() async throws -> Data {
        let url = try makeURL("/api/transactions/export/csv")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Account Deletion
    func deleteAccount() async throws {
        let url = try makeURL("/api/profile/account")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        try await executeVoid(req)
    }

    // MARK: - Consent
    func recordConsent(platform: String = "ios", policyVersion: String = "2026-05") async {
        guard token != nil else { return }
        guard let url = try? makeURL("/api/consent") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["platform": platform, "policyVersion": policyVersion]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        try? await executeVoid(req)
    }
}
