# front

A macOS CLI in Swift to activate/hide apps.

This was originally made to be used with  [skhd](https://github.com/koekeishiya/skhd), but it is not necessary.

## Installation

Compile the project with `make` and copy the binary to wherever you want.

Xcode is not required to compile the project, but Xcode command line tools may
need to be installed are.

## Usage

```
> front -h
Usage: front [-b <bundle-id>|-n <app-name>|-p <path>]

Options:
    -b <bundle-id>  Activate or hide the app with the given bundle ID
    -n <app-name>   Activate or hide the app with the given name
    -p <path>       Activate or hide the app at the given path

Examples:
    front -n Safari
    front -b com.apple.Finder
    front -p /Applications/TextEdit.app
```
