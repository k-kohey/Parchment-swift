import Danger

let danger = Danger()
SwiftLint.lint(.modifiedAndCreatedFiles(directory: "Parchment-swift"), inline: true)
