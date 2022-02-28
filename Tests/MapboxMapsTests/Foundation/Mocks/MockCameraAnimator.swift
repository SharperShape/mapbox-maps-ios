import Foundation
@testable import MapboxMaps

final class MockCameraAnimator: NSObject, CameraAnimatorProtocol {
    func cancel() {
    }

    func update() {
    }

    var state: UIViewAnimatingState = .inactive

    func stopAnimation() {
    }
}
