import AppKit
import ServiceManagement

// Einstellungen
let host = "google.de"
let interval: TimeInterval = 5      // Sekunden zwischen zwei Messungen
let timeoutSeconds = 2              // Ping-Timeout
let slowThresholdMs = 150.0         // ab hier gelb
let failuresUntilRed = 2            // so viele Fehlschläge in Folge, bis der Punkt rot wird

/// Schickt einen einzelnen Ping und liefert die Latenz in Millisekunden, oder nil ohne Antwort.
func ping() -> Double? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/sbin/ping")
    process.arguments = ["-c", "1", "-t", String(timeoutSeconds), host]
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

func dotImage(_ color: NSColor) -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10)).fill()
        return true
    }
    image.isTemplate = false
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let latencyItem = NSMenuItem(title: "Messe …", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Beim Anmelden starten", action: #selector(toggleLogin), keyEquivalent: "")
    private let queue = DispatchQueue(label: "pingdot.ping")
    private var measuring = false
    private var failures = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.image = dotImage(.systemGray)

        let menu = NSMenu()
        menu.addItem(latencyItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        refreshLoginItem()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.measure() }
        RunLoop.main.add(timer, forMode: .common)   // läuft auch bei geöffnetem Menü weiter
        measure()
    }

    private func measure() {
        guard !measuring else { return }
        measuring = true
        queue.async {
            let ms = ping()
            DispatchQueue.main.async {
                self.measuring = false
                self.show(ms)
            }
        }
    }

    private func show(_ ms: Double?) {
        guard let ms else {
            failures += 1
            latencyItem.title = "\(host): keine Antwort"
            if failures >= failuresUntilRed {
                statusItem.button?.image = dotImage(.systemRed)
            }
            return
        }
        failures = 0
        latencyItem.title = "\(host): \(Int(ms.rounded())) ms"
        statusItem.button?.image = dotImage(ms > slowThresholdMs ? .systemYellow : .systemGreen)
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("PingDot: Anmeldeobjekt konnte nicht geändert werden: \(error)")
        }
        refreshLoginItem()
    }

    private func refreshLoginItem() {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

// `PingDot --once` misst einmal und gibt das Ergebnis aus (zum Testen).
if CommandLine.arguments.contains("--once") {
    if let ms = ping() {
        print("\(host): \(ms) ms")
        exit(0)
    }
    print("\(host): keine Antwort")
    exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
