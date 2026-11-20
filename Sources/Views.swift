import SwiftUI

struct SettingsView: View {
    @AppStorage(Prefs.hostKey) private var host = Prefs.defaultHost
    @AppStorage(Prefs.intervalKey) private var interval = Prefs.defaultInterval
    @AppStorage(Prefs.thresholdKey) private var threshold = Prefs.defaultThreshold
    @StateObject private var login = LoginItem()

    var body: some View {
        Form {
            Section {
                TextField(L("Ziel", "Host"), text: $host, prompt: Text(Prefs.defaultHost))
                Picker(L("Messen alle", "Check every"), selection: $interval) {
                    ForEach(Prefs.intervalChoices, id: \.self) { Text("\(Int($0)) s").tag($0) }
                }
                Picker(L("Gelb ab", "Yellow above"), selection: $threshold) {
                    ForEach(Prefs.thresholdChoices, id: \.self) { Text("\(Int($0)) ms").tag($0) }
                }
            }
            Section {
                Toggle(L("Beim Anmelden starten", "Launch at login"), isOn: $login.enabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct WelcomeView: View {
    let close: () -> Void
    @StateObject private var login = LoginItem()

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text(L("Willkommen bei PingDot", "Welcome to PingDot"))
                .font(.title2.bold())
            Text(L("PingDot hat kein Fenster. Es sitzt als kleiner Punkt oben rechts in der Menüleiste und zeigt, ob dein Internet funktioniert.",
                   "PingDot has no window. It sits as a small dot in the menu bar at the top right and shows whether your internet is working."))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                legend(.green, L("Verbindung steht", "Connected"))
                legend(.yellow, L("Verbindung langsam", "Connection is slow"))
                legend(.red, L("Keine Verbindung", "No connection"))
            }

            Text(L("Ein Klick auf den Punkt zeigt die Latenz und die Einstellungen.",
                   "Click the dot to see the latency and the settings."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(L("Beim Anmelden starten", "Launch at login"), isOn: $login.enabled)

            Button(L("Los geht's", "Get started"), action: close)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
        }
        .padding(28)
        .frame(width: 380)
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 11, height: 11)
            Text(text)
        }
    }
}
