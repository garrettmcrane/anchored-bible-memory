import Foundation

enum ScriptureProviderFactory {
    static func makeProvider(for translation: BibleTranslation) throws -> ScriptureProvider {
        switch translation {
        case .kjv:
            return KJVLocalScriptureProvider()
        case .esv:
            throw ScriptureProviderError.translationUnavailable(.esv)
        }
    }
}
