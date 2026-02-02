import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    enum NotificationType {
        case success
        case error
    }

    static func notify(_ type: NotificationType) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        let feedback: UINotificationFeedbackGenerator.FeedbackType = type == .success ? .success : .error
        generator.notificationOccurred(feedback)
        #endif
    }
}
