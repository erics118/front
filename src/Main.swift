import AppKit

enum FrontError: Error {
    case missingCliArg
    case missingFrontmostApp
    case missingApp(String)
    case failedToLaunchApp(String)
}

func appNameToURL(_ name: String) throws -> URL {
    let appName = name.hasSuffix(".app") ? name : name + ".app"

    // hopefully it won't be too slow to check all these folders
    let appFolders = [
        "/Applications/", // global apps
        "/Applications/Utilities", // more global apps
        "\(FileManager.default.homeDirectoryForCurrentUser)/Applications/", // user apps
        "/System/Library/CoreServices/", // many system utility apps are here
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/", // safari is special
    ]

    for folder in appFolders {
        let path = folder + appName
        if FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
    }

    throw FrontError.missingApp(name)
}

func bundleIdToURL(_ id: String) throws -> URL {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
        throw FrontError.missingApp(id)
    }
    return url
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

func printHelp() {
    print("""
    Usage: front [-b <bundle-id>|-n <app-name>|-p <path>|-h]

    Options:
        -h              Print this help message
        -b <bundle-id>  Activate or hide the app with the given bundle ID
        -n <app-name>   Activate or hide the app with the given name
        -p <path>       Activate or hide the app at the given path

    Examples:
        front -h
        front -b com.apple.Finder
        front -n Safari
        front -p /Applications/TextEdit.app
    """)
}

let args = CommandLine.arguments.dropFirst()

guard let type = args.first else {
    printHelp()
    exit(0)
}

guard let data = args.dropFirst().first else {
    printHelp()
    exit(0)
}

switch type {
case "-b": try await activateOrHideApp(bundleIdToURL(data))
case "-n": try await activateOrHideApp(appNameToURL(data))
case "-p": try await activateOrHideApp(URL(fileURLWithPath: data))
default: printHelp()
}
