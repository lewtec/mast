import Foundation

struct OnboardingDefaults {
    let preset: String
    let command: String
    let url: String

    static func detect(at rootURL: URL) -> OnboardingDefaults {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: rootURL.appending(path: "hugo.toml").path()) || fileManager.fileExists(atPath: rootURL.appending(path: "config.toml").path()) {
            return forPreset("hugo")
        }

        if fileManager.fileExists(atPath: rootURL.appending(path: "package.json").path()) {
            return forPreset("vite")
        }

        return forPreset("custom")
    }

    static func forPreset(_ preset: String) -> OnboardingDefaults {
        switch preset {
        case "hugo":
            OnboardingDefaults(preset: preset, command: "hugo server --port {port}", url: "http://127.0.0.1:{port}")
        case "vite":
            OnboardingDefaults(preset: preset, command: "npm run dev -- --port {port}", url: "http://127.0.0.1:{port}")
        default:
            OnboardingDefaults(preset: "custom", command: "", url: "http://127.0.0.1:{port}")
        }
    }
}
