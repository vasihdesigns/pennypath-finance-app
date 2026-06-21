//
//  CloudBackup.swift
//  PennyPath
//
//  One-tap backup of the user's data straight into the app's iCloud Drive
//  container (iCloud.com.vasih.PennyPath → Documents). iOS uploads it to the
//  user's iCloud automatically, and because the container is published
//  (NSUbiquitousContainers in Info.plist) the files are visible under
//  Files → iCloud Drive → PennyPath and can be re-imported with the normal picker.
//
//  Unlike the destructive Reset flow, a backup written here is NOT mirrored as a
//  CloudKit record, so it survives a "Reset & clear everything" — it's a real
//  backup, not a sync. Callers fall back to the share sheet when iCloud is off.
//

import Foundation

enum CloudBackup {
    /// Must match the entitlement's ubiquity-container identifier.
    static let containerID = "iCloud.com.vasih.PennyPath"

    enum BackupError: LocalizedError {
        case unavailable
        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "iCloud Drive isn't available. Sign in to iCloud and turn on iCloud Drive, then try again."
            }
        }
    }

    /// Resolve and write off the main thread — `url(forUbiquityContainerIdentifier:)`
    /// blocks and Apple explicitly warns against calling it on the main thread.
    private static let ioQueue = DispatchQueue(label: "com.vasih.PennyPath.cloud-backup",
                                               qos: .userInitiated)

    /// Whether the iCloud container is reachable right now (off the main thread).
    static func isAvailable() async -> Bool {
        await withCheckedContinuation { cont in
            ioQueue.async { cont.resume(returning: documentsURL() != nil) }
        }
    }

    /// Write a timestamped JSON snapshot into the iCloud container and return its
    /// URL. `data` is produced on the caller's actor (it reads the model context);
    /// only the file I/O happens here, off the main thread.
    @discardableResult
    static func writeBackup(_ data: Data, now: Date = .now) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            ioQueue.async {
                do { cont.resume(returning: try writeSync(data, now: now)) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    /// Find the newest backup, download it from iCloud if it isn't local yet, and
    /// return its on-disk URL — ready for the importer. `nil` when none exists.
    static func downloadLatestBackup() async throws -> URL? {
        try await withCheckedThrowingContinuation { cont in
            ioQueue.async {
                guard let url = newestBackupURL() else { cont.resume(returning: nil); return }
                do {
                    try ensureDownloaded(url)
                    cont.resume(returning: url)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Internals (always called on `ioQueue`)

    /// The container's Documents folder, created if needed. `nil` when iCloud is
    /// signed out / Drive is off / the container isn't provisioned yet.
    private static func documentsURL() -> URL? {
        guard let base = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return nil
        }
        let docs = base.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }

    private static func newestBackupURL() -> URL? {
        guard let docs = documentsURL() else { return nil }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files
            .filter { $0.lastPathComponent.hasPrefix("PennyPath-Backup-") && $0.pathExtension == "json" }
            .max { modified($0) < modified($1) }
    }

    /// Pull a backup down from iCloud if it isn't local yet (cross-device restore).
    /// Bounded so a stalled download can't hang the restore forever; the read that
    /// follows will surface a clear error if the bytes still aren't there.
    private static func ensureDownloaded(_ url: URL) throws {
        func status() -> URLUbiquitousItemDownloadingStatus? {
            (try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]))?
                .ubiquitousItemDownloadingStatus
        }
        if status() == .current { return }
        try FileManager.default.startDownloadingUbiquitousItem(at: url)
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if status() == .current { return }
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    private static func writeSync(_ data: Data, now: Date) throws -> URL {
        guard let docs = documentsURL() else { throw BackupError.unavailable }
        let dest = docs.appendingPathComponent("PennyPath-Backup-\(stamp.string(from: now)).json")

        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: dest, options: .forReplacing,
                                       error: &coordinationError) { url in
            do { try data.write(to: url, options: .atomic) }
            catch { writeError = error }
        }
        if let writeError { throw writeError }
        if let coordinationError { throw coordinationError }
        return dest
    }

    private static func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }

    private static let stamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
