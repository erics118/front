import AppKit

func appNameToURL(_ name: String) throws -> URL {
    let appName = name.hasSuffix(".app") ? name : name + ".app"

    switch appName {
    case "Finder.app": return URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
    case "Safari.app": return URL(fileURLWithPath: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
    default: break
    }

    let appFolders = [
        // user-installed global apps
        URL(fileURLWithPath: "/Applications/", isDirectory: true),

        // system apps
        // they show even though they show up in /Applications to the user
        // eg, App Store, Music, System Settings
        URL(fileURLWithPath: "/System/Applications/", isDirectory: true),

        // system utility apps
        // eg, Terminal, Activity Monitor, Disk Utility
        URL(fileURLWithPath: "/System/Applications/Utilities/", isDirectory: true),

        // single-user apps
        // "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/" as String, // user apps
        FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)[0],
    ]

    // let appFolders = FileManager.default.urls(for: .applicationDirectory, in: .allDomainsMask)

    // print(appFolders)

    for folder in appFolders {
        let path = folder.appending(component: appName, directoryHint: .isDirectory)
        if FileManager.default.fileExists(atPath: path.path) {
            return path
        }
    }

    print("Error: unable to find app with name \(name)")
    exit(1)
}

func bundleIdToURL(_ id: String) throws -> URL {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
        print("Error: unable to find app with bundle id \(id)")
        exit(1)
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
        print("Error: failed to launch app with path \(path)")
        exit(1)
    }
}

func activateOrHideApp(_ path: URL) async throws {
    // TODO: if there are no Finder windows, open a new window for finder
    // instead of trying to hide Finder, which switches to a different app

    guard let front = NSWorkspace.shared.frontmostApplication else {
        print("Error: missing frontmost app")
        exit(1)
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
        -h, --help                     Print this help message
        -b, --bundle-id <bundle-id>    Activate or hide the app with the given bundle ID
        -n, --name <app-name>          Activate or hide the app with the given name
        -p, --path <path>              Activate or hide the app at the given path

    Examples:
        front -h
        front -b com.apple.Finder
        front -n Safari
        front -p /Applications/Firefox.app
    """)
}

let args = CommandLine.arguments.dropFirst()

guard let type = args.first else {
    print("Error: missing argument")
    exit(1)
}

switch type {
case "-b", "--bundle-id":
    guard let data = args.dropFirst().first else {
        print("Error: missing bundle id argument")
        exit(1)
    }
    try await activateOrHideApp(bundleIdToURL(data))

case "-n", "--name":
    guard let data = args.dropFirst().first else {
        print("Error: missing name argument")
        exit(1)
    }
    try await activateOrHideApp(appNameToURL(data))

case "-p", "--path":
    guard let data = args.dropFirst().first else {
        print("Error: missing path argument")
        exit(1)
    }
    try await activateOrHideApp(URL(fileURLWithPath: data))
case "-h", "--help":
    printHelp()
default:
    print("Error: invalid argument")
    exit(1)
}
