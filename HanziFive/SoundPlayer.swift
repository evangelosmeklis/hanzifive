import Foundation
import AudioToolbox

enum SoundPlayer {
    static func playCorrect() {
        AudioServicesPlaySystemSound(1104)
    }

    static func playWrong() {
        AudioServicesPlaySystemSound(1107)
    }
}
