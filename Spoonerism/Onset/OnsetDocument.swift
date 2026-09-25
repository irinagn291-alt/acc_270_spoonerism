import Foundation

/// Role: Onset. Preference keys. Snapshot is JSON Data under spn.onset.v1. Demo is Simulator-only.
enum OnsetKey {
    static let snapshot = "spn.onset.v1"
    static let backup = "spn.onset.v1.backup"
    static let demo = "spn.demo.v1"
}

enum OnsetCodecError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case corrupt
}

/// Role: Onset. Codable OnsetDocument. schemaVersion from 1. WorkFold case is stored. Mended-ness is not a parallel bool.
enum OnsetDocument {
    static func encode(_ onset: Onset) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var copy = onset
        copy.schemaVersion = Onset.currentSchema
        return try encoder.encode(RootFile(onset: copy))
    }

    static func decode(_ data: Data) throws -> Onset {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw OnsetCodecError.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var onset = try decoder.decode(RootFile.self, from: data).onset
                onset.schemaVersion = Onset.currentSchema
                return onset
            } catch let error as OnsetCodecError {
                throw error
            } catch {
                throw OnsetCodecError.corrupt
            }
        default:
            throw OnsetCodecError.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootFile: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var hanging: OnsetHang
    var mendMarks: [MendMark]
    var muffMarks: [MuffMark]
    var peelLog: [PeelRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?

    init(onset: Onset) {
        schemaVersion = onset.schemaVersion
        onboardingComplete = onset.onboardingComplete
        works = onset.works
        hanging = onset.hanging
        mendMarks = onset.mendMarks
        muffMarks = onset.muffMarks
        peelLog = onset.peelLog
        cachedRows = onset.cachedRows
        focusedWorkID = onset.focusedWorkID
    }

    var onset: Onset {
        Onset(
            schemaVersion: schemaVersion,
            onboardingComplete: onboardingComplete,
            works: works,
            hanging: hanging,
            mendMarks: mendMarks,
            muffMarks: muffMarks,
            peelLog: peelLog,
            cachedRows: cachedRows,
            focusedWorkID: focusedWorkID
        )
    }
}
