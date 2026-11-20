import Foundation
import ServiceManagement

/// Deutsch, wenn das System auf Deutsch läuft, sonst Englisch.
func L(_ de: String, _ en: String) -> String {
    (Locale.preferredLanguages.first ?? "en").hasPrefix("de") ? de : en
}

/// Gespeicherte Einstellungen (UserDefaults).
enum Prefs {
    static let hostKey = "host"
    static let intervalKey = "interval"
    static let thresholdKey = "slowThresholdMs"
    static let welcomeShownKey = "welcomeShown"

    static let defaultHost = "google.de"
    static let defaultInterval = 5.0
    static let defaultThreshold = 150.0
    static let intervalChoices = [2.0, 5.0, 10.0, 30.0]
    static let thresholdChoices = [50.0, 100.0, 150.0, 300.0, 500.0]

    static let timeoutSeconds = 2
    static let failuresUntilRed = 2

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            hostKey: defaultHost,
            intervalKey: defaultInterval,
            thresholdKey: defaultThreshold,
        ])
    }

    /// Der eingestellte Host; bei leerer oder ungültiger Eingabe der Standard.
    static var host: String {
        let raw = (UserDefaults.standard.string(forKey: hostKey) ?? "").trimmingCharacters(in: .whitespaces)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        let valid = !raw.isEmpty && !raw.hasPrefix("-") && raw.unicodeScalars.allSatisfy(allowed.contains)
        return valid ? raw : defaultHost
    }

    static var interval: Double {
        let value = UserDefaults.standard.double(forKey: intervalKey)
        return value >= 1 ? value : defaultInterval
    }

    static var thresholdMs: Double {
        let value = UserDefaults.standard.double(forKey: thresholdKey)
        return value > 0 ? value : defaultThreshold
    }
}

/// Schickt einen einzelnen Ping und liefert die Latenz in Millisekunden, oder nil ohne Antwort.
func ping(_ host: String) -> Double? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/sbin/ping")
    process.arguments = ["-c", "1", "-t", String(Prefs.timeoutSeconds), host]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0,
          let output = String(data: data, encoding: .utf8),
          let range = output.range(of: #"time=([0-9.]+)"#, options: .regularExpression)
    else { return nil }
    return Double(output[range].dropFirst("time=".count))
}

/// „Beim Anmelden starten" als Schalter für die Oberfläche.
final class LoginItem: ObservableObject {
    @Published var enabled = SMAppService.mainApp.status == .enabled {
        didSet {
            guard enabled != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                NSLog("PingDot: Anmeldeobjekt konnte nicht geändert werden: \(error)")
                DispatchQueue.main.async { self.enabled = SMAppService.mainApp.status == .enabled }
            }
        }
    }
}
