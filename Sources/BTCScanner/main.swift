import Foundation
import CryptoKit
import RIPEMD160
import BigInt

actor SharedState {
    private(set) var checkedCount: Int = 0
    private(set) var errorsCount: Int = 0
    
    func incrementChecked() {
        checkedCount += 1
    }
    
    func incrementErrors() {
        errorsCount += 1
    }
}

class BTCScanner {
    private let state = SharedState()
    private let numThreads: Int
    private let userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"
    private let timeout: TimeInterval = 5
    
    init(numThreads: Int = 1) {
        self.numThreads = numThreads
    }
    
    private func checkAddressBalance(address: String, retryCount: Int = 0) async throws -> (success: Bool, balance: Double) {
        let maxRetries = 3
        let urlString = "https://api.blockchain.info/haskoin-store/btc/address/\(address)/balance"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for address: ...\(String(address.suffix(4)))")
            throw NSError(domain: "BTCScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 429 {
                        if retryCount < maxRetries {
                            print("⏳ Rate limit hit, cooling down for 60 seconds... (Attempt \(retryCount + 1)/\(maxRetries))")
                            try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                            print("▶️ Retrying address: ...\(String(address.suffix(4)))")
                            return try await checkAddressBalance(address: address, retryCount: retryCount + 1)
                        } else {
                            print("❌ Max retries reached for address: ...\(String(address.suffix(4)))")
                        }
                    } else {
                        print("❌ HTTP Error \(httpResponse.statusCode) for address: ...\(String(address.suffix(4)))")
                    }
                }
                await state.incrementErrors()
                return (false, 0.0)
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let confirmed = json?["confirmed"] as? Int else {
                print("❌ Invalid JSON response for address: ...\(String(address.suffix(4)))")
                await state.incrementErrors()
                return (false, 0.0)
            }
            
            let balance = Double(confirmed) / 100000000.0
            return (true, balance)
            
        } catch {
            print("❌ Network error for address: ...\(String(address.suffix(4))): \(error.localizedDescription)")
            await state.incrementErrors()
            return (false, 0.0)
        }
    }
    
    private func generateBitcoinAddress(privateKey: P256.Signing.PrivateKey) throws -> String {
        let publicKey = privateKey.publicKey
        let publicKeyData = publicKey.x963Representation
        
        let sha256 = SHA256.hash(data: publicKeyData)
        let ripemd160 = RIPEMD160.hash(data: Data(sha256))
        
        var versionedHash = Data([0x00])
        versionedHash.append(ripemd160)
        
        let firstHash = SHA256.hash(data: versionedHash)
        let firstHashData = Data(firstHash)
        let doubleHash = SHA256.hash(data: firstHashData)
        let checksum = Data(doubleHash.prefix(4))
        
        var addressData = versionedHash
        addressData.append(checksum)
        
        return base58Encode(addressData)
    }
    
    private func base58Encode(_ data: Data) -> String {
        let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        var num = BigUInt(data)
        var encoded = ""
        let radix = BigUInt(alphabet.count)
        
        while num > 0 {
            let (quotient, remainder) = num.quotientAndRemainder(dividingBy: radix)
            let remainderInt = Int(remainder.description) ?? 0
            let index = alphabet.index(alphabet.startIndex, offsetBy: remainderInt)
            encoded = String(alphabet[index]) + encoded
            num = quotient
        }
        
        for byte in data {
            if byte == 0 {
                encoded = String(alphabet.first!) + encoded
            } else {
                break
            }
        }
        
        return encoded
    }
    
    private func saveWallet(address: String, privateKey: String, balance: Double) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        let shortAddress = String(address.suffix(4))
        
        if balance > 0 {
            let content = "\(timestamp) | \(address) | \(privateKey) | \(balance) BTC\n"
            let fileURL = URL(fileURLWithPath: "found_wallets.txt")
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(content.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            print("💰 Found wallet: ...\(shortAddress) | \(balance) BTC")
        } else {
            let emptyURL = URL(fileURLWithPath: "empty_wallets.txt")
            let pkeyURL = URL(fileURLWithPath: "empty_wallets_with_pkey.txt")
            
            if let handle = try? FileHandle(forWritingTo: emptyURL) {
                handle.seekToEndOfFile()
                handle.write("\(address)\n".data(using: .utf8)!)
                handle.closeFile()
            } else {
                try "\(address)\n".write(to: emptyURL, atomically: true, encoding: .utf8)
            }
            
            if let handle = try? FileHandle(forWritingTo: pkeyURL) {
                handle.seekToEndOfFile()
                handle.write("\(address) | \(privateKey)\n".data(using: .utf8)!)
                handle.closeFile()
            } else {
                try "\(address) | \(privateKey)\n".write(to: pkeyURL, atomically: true, encoding: .utf8)
            }
            print("✓ Checked: ...\(shortAddress)")
        }
    }
    
    private func scannerTask(id: Int) async {
        while true {
            do {
                let privateKey = P256.Signing.PrivateKey()
                let privateKeyHex = privateKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()
                
                let address = try generateBitcoinAddress(privateKey: privateKey)
                await state.incrementChecked()
                
                let (success, balance) = try await checkAddressBalance(address: address)
                
                if success {
                    try saveWallet(address: address, privateKey: privateKeyHex, balance: balance)
                    if balance > 0 {
                        return
                    }
                }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
            } catch {
                await state.incrementErrors()
                continue
            }
        }
    }
    
    func run() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<numThreads {
                group.addTask {
                    await self.scannerTask(id: i)
                }
            }
            await group.waitForAll()
        }
    }
}

// Replace the @main struct with this:
@available(macOS 12.0, *)
func main() async {
    let scanner = BTCScanner(numThreads: 12)
    await scanner.run()
}

// Call main
if #available(macOS 12.0, *) {
    await main()
} else {
    fatalError("This program requires macOS 12.0 or later")
}