import AppKit

enum FrontError: Error {
    case missingCliArg
    case missingFrontmostApp
    case missingApp(String)
    case failedToLaunchApp(String)
}

func appNameToURL(_ name: String) throws -> URL {
    let appPaths = [
        "/Applications/\(name).app",
        "\(FileManager.default.homeDirectoryForCurrentUser)/Applications/\(name).app",
        "/System/Applications/\(name).app",
    ]

    for path in appPaths {
        if FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
    }

    throw FrontError.missingApp(name)
}

func activateApp(_ path: URL) async throws {
    do {
        try await NSWorkspace.shared.openApplication(
            at: path,
            configuration: NSWorkspace.OpenConfiguration()
        )
    } catch {
        throw FrontError.failedToLaunchApp(path.absoluteString)
    }
}

func activateOrHideApp(_ path: URL) async throws {
    // TODO: if there are no Finder windows, open a new window for finder
    // instead of trying to hide Finder, which switches to a different app

    guard let front = NSWorkspace.shared.frontmostApplication else {
        throw FrontError.missingFrontmostApp
    }

    if front.bundleURL == path {
        front.hide()
    } else {
        try await activateApp(path)
    }
}

func getFirstArg() throws -> String {
    if let firstArg = CommandLine.arguments.dropFirst().first {
        return firstArg
    } else {
        throw FrontError.missingCliArg
    }
}

let arg = try getFirstArg()

if arg.starts(with: "/") {
    try await activateOrHideApp(URL(fileURLWithPath: arg))
} else {
    try await activateOrHideApp(appNameToURL(arg))
}
