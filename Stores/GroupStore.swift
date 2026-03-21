import Foundation

private struct GroupStoreSnapshot: Codable {
    var groups: [Group]
    var memberships: [GroupMembership]
    var assignments: [Assignment]

    private enum CodingKeys: String, CodingKey {
        case groups
        case memberships
        case assignments
    }

    nonisolated init(groups: [Group], memberships: [GroupMembership], assignments: [Assignment]) {
        self.groups = groups
        self.memberships = memberships
        self.assignments = assignments
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groups = try container.decode([Group].self, forKey: .groups)
        memberships = try container.decode([GroupMembership].self, forKey: .memberships)
        assignments = try container.decode([Assignment].self, forKey: .assignments)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groups, forKey: .groups)
        try container.encode(memberships, forKey: .memberships)
        try container.encode(assignments, forKey: .assignments)
    }
}

enum GroupStore {

    nonisolated private static let fileName = "groups.json"
    nonisolated private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cachedSnapshot: GroupStoreSnapshot?

    nonisolated static func load() -> (groups: [Group], memberships: [GroupMembership], assignments: [Assignment]) {
        cacheLock.lock()
        if let cachedSnapshot {
            cacheLock.unlock()
            return (cachedSnapshot.groups, cachedSnapshot.memberships, cachedSnapshot.assignments)
        }
        cacheLock.unlock()

        do {
            let url = try fileURL()

            guard FileManager.default.fileExists(atPath: url.path) else {
                let emptySnapshot = GroupStoreSnapshot(groups: [], memberships: [], assignments: [])
                updateCache(with: emptySnapshot)
                return ([], [], [])
            }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let snapshot = try decoder.decode(GroupStoreSnapshot.self, from: data)
            updateCache(with: snapshot)
            return (snapshot.groups, snapshot.memberships, snapshot.assignments)
        } catch {
            assertionFailure("Failed to load groups: \(error)")
            return ([], [], [])
        }
    }

    static func save(
        groups: [Group],
        memberships: [GroupMembership],
        assignments: [Assignment]
    ) {
        do {
            let url = try fileURL()
            try ensureDirectoryExists(for: url)
            let snapshot = GroupStoreSnapshot(groups: groups, memberships: memberships, assignments: assignments)
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: .atomic)
            updateCache(with: snapshot)
        } catch {
            assertionFailure("Failed to save groups: \(error)")
        }
    }

    nonisolated private static func updateCache(with snapshot: GroupStoreSnapshot) {
        cacheLock.lock()
        cachedSnapshot = snapshot
        cacheLock.unlock()
    }

    nonisolated private static func fileURL() throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return baseDirectory
            .appendingPathComponent("Anchored", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private static func ensureDirectoryExists(for url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    nonisolated private static let decoder = JSONDecoder()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
