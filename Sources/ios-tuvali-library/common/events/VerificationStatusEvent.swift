import Foundation

public struct VerificationStatusEvent: Event {
    public var status: VerificationStatus

    public enum VerificationStatus: Int {
        case ACCEPTED = 0
        case REJECTED = 1
    }
}
