import Foundation
import SwiftData

// MARK: - Recovery (WP-DB5)
//
// Support-safe operations: never silently delete a durable store. Quarantine
// moves corrupt data aside so a fresh store can open and the original remains
// for diagnosis or manual restore.

/// Result of inspecting a file-backed SwiftData store path.
public enum PersistenceStoreDiagnosis: Equatable, Sendable {
    /// No file at the expected store URL.
    case missing
    /// File exists and opens with the current factory/migration plan.
    case presentReadable
    /// File exists but cannot be opened (corrupt, incompatible, or locked).
    case presentUnopenable
}

public enum PersistenceRecoveryError: Error, Equatable, Sendable {
    case storeMissing
    case quarantineFailed
    case destinationExists
}

/// Support-safe recovery helpers. Does not claim outdoor quality or cloud sync.
public enum PersistenceRecovery {
    /// Suffix / directory used when setting aside a bad store.
    public static let quarantineDirectoryName = "StoreQuarantine"

    /// Classify the store at `storeURL` without mutating it.
    public static func diagnose(
        storeURL: URL,
        fileManager: FileManager = .default
    ) -> PersistenceStoreDiagnosis {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return .missing
        }
        do {
            _ = try WaykinPersistenceContainerFactory.makeFileBacked(
                url: storeURL,
                reset: false,
                fileManager: fileManager
            )
            return .presentReadable
        } catch {
            return .presentUnopenable
        }
    }

    /// Move a store (and common sidecar files) into a quarantine directory.
    /// Does **not** delete the original bytes — only relocates them.
    ///
    /// - Returns: Directory containing the quarantined store artifacts.
    @discardableResult
    public static func quarantineStore(
        at storeURL: URL,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws -> URL {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            throw PersistenceRecoveryError.storeMissing
        }

        let parent = storeURL.deletingLastPathComponent()
        let quarantineRoot = parent.appendingPathComponent(quarantineDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: quarantineRoot, withIntermediateDirectories: true)

        let stamp = Int(now.timeIntervalSince1970)
        let destination = quarantineRoot.appendingPathComponent(
            "\(storeURL.lastPathComponent).\(stamp)",
            isDirectory: true
        )
        if fileManager.fileExists(atPath: destination.path) {
            throw PersistenceRecoveryError.destinationExists
        }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        let baseName = storeURL.lastPathComponent
        let candidates = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal"),
            // Some configurations use "-shm" / "-wal" suffix style:
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        var movedAny = false
        for source in candidates where fileManager.fileExists(atPath: source.path) {
            let name = source.lastPathComponent
            let target = destination.appendingPathComponent(name)
            do {
                try fileManager.moveItem(at: source, to: target)
                movedAny = true
            } catch {
                throw PersistenceRecoveryError.quarantineFailed
            }
        }

        // Also move related files that share the store basename prefix in the parent.
        if let children = try? fileManager.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil) {
            for child in children {
                let name = child.lastPathComponent
                guard name.hasPrefix(baseName), name != baseName else { continue }
                // Skip quarantine directory itself.
                if name == quarantineDirectoryName { continue }
                let target = destination.appendingPathComponent(name)
                if fileManager.fileExists(atPath: target.path) { continue }
                if fileManager.fileExists(atPath: child.path) {
                    try? fileManager.moveItem(at: child, to: target)
                    movedAny = true
                }
            }
        }

        guard movedAny else {
            throw PersistenceRecoveryError.quarantineFailed
        }
        return destination
    }

    /// After a failed open: quarantine the bad store, then open a fresh empty store at the same URL.
    /// Original data remains under `StoreQuarantine/` — never silently deleted.
    public static func openFreshAfterQuarantine(
        storeURL: URL,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws -> (container: ModelContainer, storeURL: URL, quarantineURL: URL) {
        let quarantineURL = try quarantineStore(at: storeURL, fileManager: fileManager, now: now)
        let opened = try WaykinPersistenceContainerFactory.makeFileBacked(
            url: storeURL,
            reset: false,
            fileManager: fileManager
        )
        return (opened.container, opened.storeURL, quarantineURL)
    }
}
