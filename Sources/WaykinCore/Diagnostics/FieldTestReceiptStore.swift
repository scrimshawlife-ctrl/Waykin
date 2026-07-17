import Foundation

public protocol FieldTestReceiptStoring {
    @discardableResult
    func save(_ receipt: FieldTestReceipt) throws -> URL
    func loadLatest() throws -> FieldTestReceipt?
}

public enum FieldTestReceiptStoreError: Error, Equatable {
    case createDirectoryFailed
    case encodingFailed
    case writeFailed
    case readFailed
    case retentionFailed
}

public final class FileFieldTestReceiptStore: FieldTestReceiptStoring {
    public static let defaultRetentionLimit = 20
    public let directoryURL: URL
    public let retentionLimit: Int

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        directoryURL: URL,
        retentionLimit: Int = FileFieldTestReceiptStore.defaultRetentionLimit,
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL
        self.retentionLimit = max(1, retentionLimit)
        self.fileManager = fileManager
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public static func applicationSupport(fileManager: FileManager = .default) -> FileFieldTestReceiptStore {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return FileFieldTestReceiptStore(
            directoryURL: base
                .appendingPathComponent("Waykin", isDirectory: true)
                .appendingPathComponent("FieldTestReceipts", isDirectory: true),
            fileManager: fileManager
        )
    }

    @discardableResult
    public func save(_ receipt: FieldTestReceipt) throws -> URL {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            throw FieldTestReceiptStoreError.createDirectoryFailed
        }

        let data: Data
        do {
            data = try encoder.encode(receipt)
        } catch {
            throw FieldTestReceiptStoreError.encodingFailed
        }

        let destination = directoryURL.appendingPathComponent(filename(for: receipt), isDirectory: false)
        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            throw FieldTestReceiptStoreError.writeFailed
        }

        do {
            try enforceRetention()
        } catch {
            throw FieldTestReceiptStoreError.retentionFailed
        }
        return destination
    }

    public func loadLatest() throws -> FieldTestReceipt? {
        try decodedReceipts().max { lhs, rhs in
            if lhs.receipt.startedAt == rhs.receipt.startedAt {
                return lhs.receipt.receiptID.uuidString < rhs.receipt.receiptID.uuidString
            }
            return lhs.receipt.startedAt < rhs.receipt.startedAt
        }?.receipt
    }

    private func enforceRetention() throws {
        let receipts = try decodedReceipts().sorted { lhs, rhs in
            if lhs.receipt.startedAt == rhs.receipt.startedAt {
                return lhs.receipt.receiptID.uuidString < rhs.receipt.receiptID.uuidString
            }
            return lhs.receipt.startedAt < rhs.receipt.startedAt
        }
        guard receipts.count > retentionLimit else { return }
        for stored in receipts.prefix(receipts.count - retentionLimit) {
            try fileManager.removeItem(at: stored.url)
        }
    }

    private func decodedReceipts() throws -> [(url: URL, receipt: FieldTestReceipt)] {
        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("field-test-") }
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
            throw FieldTestReceiptStoreError.readFailed
        }

        do {
            return try urls.map { url in
                (url, try decoder.decode(FieldTestReceipt.self, from: Data(contentsOf: url)))
            }
        } catch {
            throw FieldTestReceiptStoreError.readFailed
        }
    }

    private func filename(for receipt: FieldTestReceipt) -> String {
        let milliseconds = Int64((receipt.startedAt.timeIntervalSince1970 * 1_000).rounded())
        return "field-test-\(milliseconds)-\(receipt.receiptID.uuidString.lowercased()).json"
    }
}
