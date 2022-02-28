@_implementationOnly import MapboxCommon_Private

internal protocol SimpleCameraAnimatorProtocol: CameraAnimator {
    var to: CameraOptions { get set }
    var completion: AnimationCompletion? { get set }
    var state: UIViewAnimatingState { get }
    func startAnimation(afterDelay delay: TimeInterval)
}

/// A camera animator that offers cubic bezier easing, delayed start, and a dynamically-updatable target
/// camera.
///
/// This animator has some overlap in functionality with ``BasicCameraAnimator``; however, since it
/// is via direct interpolation rather than via ``CameraView``, it has a simpler implementation and enables
/// more advanced use cases like dynamically updating ``SimpleCameraAnimator/to``.
internal final class SimpleCameraAnimator: NSObject, CameraAnimatorProtocol, SimpleCameraAnimatorProtocol {
    private let from: CameraOptions

    /// The target camera.
    ///
    /// This property can be updated dynamically while the animation is running, but it should
    /// generally maintain the same set of non-nil fields since nil fields will not be updated during the
    /// animation. For best results, the difference between old and new `to` should be small relative
    /// to the difference between `from` and `to`.
    internal var to: CameraOptions {
        didSet {
            func hasNilMismatch<T>(for keyPath: KeyPath<CameraOptions, T?>) -> Bool {
                return (oldValue[keyPath: keyPath] == nil) != (to[keyPath: keyPath] == nil)
            }
            if hasNilMismatch(for: \.center) ||
                hasNilMismatch(for: \.zoom) ||
                hasNilMismatch(for: \.padding) ||
                hasNilMismatch(for: \.anchor) ||
                hasNilMismatch(for: \.bearing) ||
                hasNilMismatch(for: \.pitch) {
                Log.warning(forMessage: "Animator updated with differing non-nil to-value properties.", category: "maps-ios")
            }
        }
    }

    private var startDate: Date?
    private let duration: TimeInterval
    private let unitBezier: UnitBezier
    private let mapboxMap: MapboxMapProtocol
    private let cameraOptionsInterpolator: CameraOptionsInterpolatorProtocol
    private let dateProvider: DateProvider
    private weak var delegate: CameraAnimatorDelegate?

    /// A completion block to invoke when the animation stops.
    ///
    /// If the animation is interrupted by a call to ``SimpleCameraAnimator/cancel()`` or
    /// ``SimpleCameraAnimator/stopAnimation()``, the compmletion block is invoked with
    /// `UIViewAnimatingPosition.current`. If the animation is not interrupted in this way, it is
    /// invoked after the total duration has elapsed with `.end`. This property is set to `nil` before
    /// the completion block is invoked.
    internal var completion: AnimationCompletion?

    /// The state of the animation. While the animation is running, the value is `.active`. Otherwise, the
    /// value is `.inactive`.
    internal private(set) var state: UIViewAnimatingState = .inactive

    /// Initializes a new ``SimpleCameraAnimator``.
    /// - Parameters:
    ///   - from: The initial camera.
    ///   - to: The target camera.
    ///   - duration: How long the animation should take.
    ///   - curve: Allows applying easing effects.
    ///   - mapboxMap: The map whose camera should be updated.
    ///   - cameraOptionsInterpolator: An object that calculates interpolated camera values.
    ///   - dateProvider: An object that provides the current date.
    ///   - delegate: A delegate to inform when the animation starts or stops running.
    internal init(from: CameraOptions,
                  to: CameraOptions,
                  duration: TimeInterval,
                  curve: TimingCurve,
                  mapboxMap: MapboxMapProtocol,
                  cameraOptionsInterpolator: CameraOptionsInterpolatorProtocol,
                  dateProvider: DateProvider,
                  delegate: CameraAnimatorDelegate) {
        self.from = from
        self.to = to
        self.duration = duration
        self.unitBezier = UnitBezier(p1: curve.p1, p2: curve.p2)
        self.mapboxMap = mapboxMap
        self.cameraOptionsInterpolator = cameraOptionsInterpolator
        self.dateProvider = dateProvider
        self.delegate = delegate
        super.init()
    }

    /// Starts the animation.
    ///
    /// This method sets ``BasicCameraAnimator/state`` to `.active` immediately regardless
    /// of `delay`. It also call the delegate to indicate that it has started running. Does nothing if `state`
    /// is not `.inactive`.
    /// - Parameter delay: An amount of time to wait before beginning to update the map's camera.
    internal func startAnimation(afterDelay delay: TimeInterval) {
        guard state == .inactive else {
            return
        }
        state = .active
        startDate = dateProvider.now + delay
        delegate?.cameraAnimatorDidStartRunning(self)
    }

    /// Cancels the animation.
    ///
    /// This method sets ``BasicCameraAnimator/state`` to `.inactive`, informs the delegate
    /// that the animation has stopped running, and clears and invokes
    /// ``SimpleCameraAnimator/completion``. Does nothing if `state` is not `.active`.
    internal func cancel() {
        guard state == .active else {
            return
        }
        state = .inactive
        startDate = nil
        delegate?.cameraAnimatorDidStopRunning(self)
        let completion = self.completion
        self.completion = nil
        completion?(.current)
    }

    /// An alias for ``SimpleCameraAnimator/cancel()``.
    internal func stopAnimation() {
        cancel()
    }

    /// Updates the map camera.
    ///
    /// For running animations, this method calculates the elapsed time since
    /// ``SimpleCameraAnimator/startAnimation(afterDelay:)`` was invoked plus any
    /// delay, and, if that value is non-negative, applies the timing function to get a fraction complete,
    /// computes an interpolated camera given that fraction, ``SimpleCameraAnimator/from``, and
    /// ``SimpleCameraAnimator/to``, and sets the camera on the map.
    ///
    /// If the fraction complete is greater than or equal to 1, it sets the camera one final time to `to`,
    /// sets ``SimpleCameraAnimator/state`` to `.inactive`, informs the delegate that it
    /// has stopped running, and clears and invokes ``SimpleCameraAnimator/completion``.
    internal func update() {
        guard state == .active, let startDate = startDate else {
            return
        }
        let elapsedTime = dateProvider.now.timeIntervalSince(startDate)
        guard elapsedTime >= 0 else {
            return
        }
        let fractionComplete = unitBezier.solve(min(elapsedTime / duration, 1), 1e-6)
        guard fractionComplete < 1 else {
            mapboxMap.setCamera(to: to)
            state = .inactive
            self.startDate = nil
            delegate?.cameraAnimatorDidStopRunning(self)
            let completion = self.completion
            self.completion = nil
            completion?(.end)
            return
        }
        let camera = cameraOptionsInterpolator.interpolate(
            from: from,
            to: to,
            fraction: fractionComplete)
        mapboxMap.setCamera(to: camera)
    }
}
