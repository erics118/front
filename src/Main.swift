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

func getHomeDirectory() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser
}

func activateAppWithPath(_ path: String) async throws {
    do {
        try await NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: path),
            configuration: NSWorkspace.OpenConfiguration()
        )
    } catch {
        throw E.FailedToLaunchApp(path)
    }
}

func activateAppWithName(_ name: String) async throws {
    let appPaths = [
        "/Applications/\(name).app",
        "\(getHomeDirectory())/Applications/\(name).app",
        "/System/Applications/\(name).app",
    ]

    for path in appPaths {
        if FileManager.default.fileExists(atPath: path) {
            try await activateAppWithPath(path)
            return
        }
    }

    throw E.CouldNotFindApp(name)
}

func activateOrHideAppWithName(_ name: String) async throws {
    let front = try getFrontApp()

    var front_name = front.localizedName

    // visual studio code is weird. in Finder, it's called "Visual Studio Code",
    // but in the menu bar it's called "Code"
    if front_name == "Code" {
        front_name = "Visual Studio Code"
    }

    // TODO: if there are no Finder windows, open a new window for finder
    // instead of trying to hide Finder, which switches to a different app

    if front_name == name {
        front.hide()
    } else {
        try await activateAppWithName(name)
    }
}

func activateOrHideAppWithPath(_ path: String) async throws {
    let front = try getFrontApp()

    if front.bundleURL?.path == path {
        front.hide()
    } else {
        try await activateAppWithPath(path)
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
    try await activateOrHideAppWithPath(arg)
} else {
    try await activateOrHideAppWithName(arg)
}
