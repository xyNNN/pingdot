import AppKit
import SwiftUI

func dotImage(_ color: NSColor) -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        // Punkt mit Ring, damit er sich von den Kamera-/Mikrofon-Punkten von macOS unterscheidet
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 5.5, y: 5.5, width: 7, height: 7)).fill()
        let ring = NSBezierPath(ovalIn: NSRect(x: 1.75, y: 1.75, width: 14.5, height: 14.5))
        ring.lineWidth = 1.5
        color.withAlphaComponent(0.6).setStroke()
        ring.stroke()
        return true
    }
    image.isTemplate = false
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let latencyItem = NSMenuItem(title: L("Messe …", "Measuring …"), action: nil, keyEquivalent: "")
    private let queue = DispatchQueue(label: "pingdot.ping")
    private var timer: Timer?
    private var measuring = false
    private var failures = 0
    private var settingsWindow: NSWindow?
    private var welcomeWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.registerDefaults()
        statusItem.button?.image = dotImage(.systemGray)
        statusItem.button?.setAccessibilityLabel("PingDot")

        let menu = NSMenu()
        menu.addItem(latencyItem)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: L("Einstellungen …", "Settings …"), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem(title: L("PingDot beenden", "Quit PingDot"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged),
                                               name: UserDefaults.didChangeNotification, object: nil)
        scheduleTimer()
        measure()

        if !UserDefaults.standard.bool(forKey: Prefs.welcomeShownKey) {
            UserDefaults.standard.set(true, forKey: Prefs.welcomeShownKey)
            showWelcome()
        }
    }

    // MARK: Messen

    private func scheduleTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: Prefs.interval, repeats: true) { [weak self] _ in self?.measure() }
        RunLoop.main.add(timer, forMode: .common)   // läuft auch bei geöffnetem Menü weiter
        self.timer = timer
    }

    @objc private func settingsChanged() {
        DispatchQueue.main.async {
            if self.timer?.timeInterval != Prefs.interval { self.scheduleTimer() }
        }
    }

    private func measure() {
        guard !measuring else { return }
        measuring = true
        let host = Prefs.host
        queue.async {
            let ms = ping(host)
            DispatchQueue.main.async {
                self.measuring = false
                self.show(ms, host: host)
            }
        }
    }

    private func show(_ ms: Double?, host: String) {
        guard let ms else {
            failures += 1
            latencyItem.title = "\(host): " + L("keine Antwort", "no response")
            if failures >= Prefs.failuresUntilRed {
                statusItem.button?.image = dotImage(.systemRed)
            }
            return
        }
        failures = 0
        latencyItem.title = "\(host): \(Int(ms.rounded())) ms"
        statusItem.button?.image = dotImage(ms > Prefs.thresholdMs ? .systemYellow : .systemGreen)
    }

    // MARK: Fenster

    private func makeWindow<Content: View>(title: String, content: Content) -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.title = title
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(window.contentViewController!.view.fittingSize)
        window.center()
        return window
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = makeWindow(title: L("PingDot – Einstellungen", "PingDot Settings"), content: SettingsView())
        }
        present(settingsWindow!)
    }

    private func showWelcome() {
        let window = makeWindow(title: "PingDot", content: WelcomeView { [weak self] in self?.welcomeWindow?.close() })
        welcomeWindow = window
        present(window)
    }
}

// `PingDot --once` misst einmal und gibt das Ergebnis aus (zum Testen).
if CommandLine.arguments.contains("--once") {
    Prefs.registerDefaults()
    let host = Prefs.host
    if let ms = ping(host) {
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
