@testable import MapboxMaps

final class MockSimpleCameraAnimator: SimpleCameraAnimatorProtocol {
    @Stubbed var state: UIViewAnimatingState = .inactive

    @Stubbed var to: CameraOptions = .random()

    @Stubbed var completion: AnimationCompletion?

    let cancelStub = Stub<Void, Void>()
    func cancel() {
        cancelStub.call()
    }

    let stopAnimationStub = Stub<Void, Void>()
    func stopAnimation() {
        stopAnimationStub.call()
    }

    let startAnimationStub = Stub<TimeInterval, Void>()
    func startAnimation(afterDelay delay: TimeInterval) {
        startAnimationStub.call(with: delay)
    }
}
