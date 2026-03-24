import Foundation

enum VoiceRecitationMode: String, CaseIterable, Identifiable {
    case standard
    case handsFree

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .standard:
            return "Standard Voice Recitation"
        case .handsFree:
            return "Hands-Free Voice Recitation"
        }
    }

    var subtitle: String {
        switch self {
        case .standard:
            return "Best for normal use when you can look at and interact with your phone."
        case .handsFree:
            return "Best for the car or any situation where you should not be touching the phone."
        }
    }

    var accentTitle: String {
        switch self {
        case .standard:
            return "Guided"
        case .handsFree:
            return "Automatic"
        }
    }

    var systemImage: String {
        switch self {
        case .standard:
            return "waveform.badge.mic"
        case .handsFree:
            return "car.circle.fill"
        }
    }

    var detailPoints: [String] {
        switch self {
        case .standard:
            return [
                "Auto-starts listening when each verse appears",
                "Shows transcript, grading, and mismatch highlights",
                "Waits for your tap before moving on"
            ]
        case .handsFree:
            return [
                "Speaks the reference aloud for each verse",
                "Auto-grades and saves each result",
                "Advances through the queue without taps"
            ]
        }
    }
}
