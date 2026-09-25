import Foundation

/// Role: Onset. Projects Onset to UserDefaults spn.onset.v1 plus an atomic Application Support file. Views never touch this type.
actor OnsetVault {
    private let directory: URL
    private let suiteName: String?
    private let fileManager: FileManager

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.suiteName = suiteName
        self.fileManager = fileManager
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Spoonerism", isDirectory: true)
    }

    func load() -> (onset: Onset, warning: OnsetWarning?) {
        if let onset = decode(defaults().data(forKey: OnsetKey.snapshot)) {
            return (onset, nil)
        }
        if let onset = decode(read(fileURL)) {
            return (onset, nil)
        }
        if let onset = decode(defaults().data(forKey: OnsetKey.backup)) {
            return (onset, .recoveredFromBackup)
        }
        if let onset = decode(read(backupURL)) {
            return (onset, .recoveredFromBackup)
        }
        let hadPayload = defaults().data(forKey: OnsetKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ onset: Onset) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try OnsetDocument.encode(onset)
        let box = defaults()
        if let current = box.data(forKey: OnsetKey.snapshot) {
            box.set(current, forKey: OnsetKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        box.set(data, forKey: OnsetKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func wipe() throws {
        let box = defaults()
        box.removeObject(forKey: OnsetKey.snapshot)
        box.removeObject(forKey: OnsetKey.backup)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
    }

    func demoPlanted() -> Bool {
        defaults().object(forKey: OnsetKey.demo) != nil
    }

    func markDemoPlanted() {
        defaults().set(true, forKey: OnsetKey.demo)
    }

    private func decode(_ data: Data?) -> Onset? {
        guard let data else { return nil }
        return try? OnsetDocument.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("onset.json", isDirectory: false)
    }

    private var backupURL: URL {
        directory.appendingPathComponent("onset.json.backup", isDirectory: false)
    }

    private func defaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
