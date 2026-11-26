
import Foundation
import Combine
import Security
import UIKit

@MainActor final class LicenseManager: ObservableObject {
    // Client endpoint copied from the supplied source. Never embed ADMIN_SECRET in an IPA.
    private let baseURL = URL(string:"https://muddy-snow-bf48.minhduc1234509876.workers.dev")!
    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published var message: String?
    @Published private(set) var expiresAt: String?
    @Published var rememberKey = true
    private let store = SecureStore()
    private let account = "license-key"
    private var activeKey: String?
    private var timer: Task<Void,Never>?

    func beginLaunchSession() {
        guard let key = store.read(account), !key.isEmpty else { message = "Nhập License Key để tiếp tục"; return }
        validate(key)
    }
    func activate(_ raw: String) {
        let key = raw.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !key.isEmpty, !isBusy else { return }
        Task { await send(path:"activate",key:key,activation:true) }
    }
    func validate(_ key:String) {
        guard !isBusy else { return }
        Task { await send(path:"validate",key:key,activation:false) }
    }
    private func send(path:String,key:String,activation:Bool) async {
        isBusy = true
        message = activation ? "Đang kích hoạt License…" : "Đang xác thực License…"
        defer { isBusy = false }
        do {
            var request = URLRequest(url:baseURL.appendingPathComponent(path))
            request.httpMethod = "POST"; request.timeoutInterval = 20
            request.setValue("application/json",forHTTPHeaderField:"Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject:["key":key,"deviceId":DeviceIdentity.current])
            let (data,response) = try await URLSession.shared.data(for:request)
            guard let http = response as? HTTPURLResponse else { throw LicenseError("Phản hồi máy chủ không hợp lệ") }
            guard let result = try? JSONDecoder().decode(APIResult.self,from:data) else { throw LicenseError("License API trả dữ liệu không hợp lệ (HTTP \(http.statusCode))") }
            let accepted = activation ? result.success : (result.success && result.valid == true)
            guard accepted else {
                isActive = false; activeKey = nil; store.remove(account); stopRefresh()
                message = Self.errorText(result.error); return
            }
            activeKey = key
            if rememberKey { store.write(key,account) }
            expiresAt = result.expiresAt
            isActive = true; message = "License hợp lệ – sẵn sàng sử dụng"
            startRefresh()
        } catch {
            message = (error as? LicenseError)?.message ?? "Không thể kết nối máy chủ. Kiểm tra Internet."
        }
    }
    func logout() {
        stopRefresh(); isActive = false; activeKey = nil; expiresAt = nil
        store.remove(account); message = "Đã đăng xuất và xoá key trên thiết bị"
    }
    private func startRefresh() {
        stopRefresh()
        timer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds:60_000_000_000)
                guard let self, let key = self.activeKey else { continue }
                await self.send(path:"validate",key:key,activation:false)
            }
        }
    }
    private func stopRefresh() { timer?.cancel(); timer = nil }
    private static func errorText(_ code:String?) -> String {
        switch code {
        case "LICENSE_NOT_FOUND": return "License Key không tồn tại"
        case "LICENSE_REVOKED","LICENSE_INVALID": return "License đã bị khóa hoặc thu hồi"
        case "LICENSE_EXPIRED": return "License đã hết hạn"
        case "DEVICE_ALREADY_BOUND","DEVICE_MISMATCH": return "Key đã liên kết với thiết bị khác"
        case "INVALID_KEY_OR_DEVICE","INVALID_INPUT": return "Key hoặc mã thiết bị không hợp lệ"
        default: return code ?? "License không hợp lệ"
        }
    }
}
private struct APIResult:Decodable { let success:Bool; let valid:Bool?; let error:String?; let expiresAt:String? }
private struct LicenseError:Error { let message:String; init(_ message:String){self.message=message} }
private struct SecureStore {
    private let service="com.minhduc.admin.license"
    func read(_ account:String)->String? {
        let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]
        var result:CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary,&result)==errSecSuccess,let data=result as? Data else{return nil}
        return String(data:data,encoding:.utf8)
    }
    func write(_ value:String,_ account:String) {
        let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account]
        let data=Data(value.utf8)
        if SecItemUpdate(q as CFDictionary,[kSecValueData as String:data] as CFDictionary)==errSecItemNotFound {
            var add=q; add[kSecValueData as String]=data; add[kSecAttrAccessible as String]=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary,nil)
        }
    }
    func remove(_ account:String) { SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account] as CFDictionary) }
}
private enum DeviceIdentity {
    static var current:String {
        let service="com.minhduc.admin.device", account="device-id"
        let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]
        var result:CFTypeRef?
        if SecItemCopyMatching(q as CFDictionary,&result)==errSecSuccess,let data=result as? Data,let value=String(data:data,encoding:.utf8){return value}
        let value=UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        SecItemAdd([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecValueData as String:Data(value.utf8),kSecAttrAccessible as String:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary,nil)
        return value
    }
}
