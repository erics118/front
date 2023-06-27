import AppKit

enum E: Error {
    case FailedToLaunchApp(String)
    case CouldNotFindApp(String)
    case NoCLIArg
    case CouldNotGetFrontmostApp
}

func getFrontApp() throws -> NSRunningApplication {
    if let app = NSWorkspace.shared.frontmostApplication {
        return app
    } else {
        throw E.CouldNotGetFrontmostApp
    }
}

// guard let bundleIdentifier = app?.bundleIdentifier else {
//     print("Could not get frontmost application bundle identifier")
//     exit(1)
// }

@available(*, deprecated)
func launchAppWithBundleId(_ bundleId: String) {
    // eg "com.cron.electron"
    NSWorkspace.shared.launchApplication(bundleId)
}

func getHomeDirectory() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser
}

func getUserApplicationDirectory() -> URL {
    return getHomeDirectory().appendingPathComponent("Applications")
}

func launchAppWithPath(_ path: String) async throws {
    do {
        try await NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: path),
            configuration: NSWorkspace.OpenConfiguration() /* ,
             completionHandler: { app, error in
                 if let error = error {
                     print("Could not open application: \(error)")
                     exit(1)
                 }
                 print("Launched \(app!.bundleIdentifier!)")
             } */
        )
    } catch {
        throw E.FailedToLaunchApp(path)
    }
    // do {
    //     sleep(4)
    // }
}

func launchAppWithName(_ name: String) async throws {
    let appPaths = [
        "/Applications/\(name).app",
        "\(getUserApplicationDirectory().path)/\(name).app",
        "/System/Applications/\(name).app",
    ]

    for path in appPaths {
        if FileManager.default.fileExists(atPath: path) {
            try await launchAppWithPath(path)
            return
        }
    }

    throw E.CouldNotFindApp(name)
    // if NSWorkspace.shared.runningApplications.contains(where: { $0.localizedName == app }) {
    //     print("\(app) is already running")
    // } else {
    //     print("Could not find application: \(app)")
    //     exit(1)
    // }
}

func launchOrHideAppWithName(_ name: String) async throws {
    let front = try getFrontApp()

    var front_name = front.localizedName

    if front_name == "Code" {
        front_name = "Visual Studio Code"
    }

    // TODO: if there are no Finder windows, open a new window for finder
    // instead of trying to hide Finder, which switches to a different app

    if front_name == name {
        front.hide()
    } else {
        try await launchAppWithName(name)
    }
}

func launchOrHideAppWithPath(_ path: String) async throws {
    let front = try getFrontApp()

    if front.bundleURL?.path == path {
        front.hide()
    } else {
        try await launchAppWithPath(path)
    }
}

func getFirstArg() throws -> String {
    if let firstArg = CommandLine.arguments.dropFirst().first {
        return firstArg
    } else {
        throw E.NoCLIArg
    }
}

let arg = try getFirstArg()

if arg.starts(with: "/") {
    try await launchOrHideAppWithPath(arg)
} else {
    try await launchOrHideAppWithName(arg)
}
