import Foundation
import MapboxMaps

@objc(CustomLocationProviderExample)
internal class CustomLocationProviderExample: UIViewController, ExampleProtocol {

    var mapView: MapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let centerCoordinate = CLLocationCoordinate2D(latitude: 40.7131854, longitude: -74.0165265)
        let options = MapInitOptions(cameraOptions: CameraOptions(center: centerCoordinate, zoom: 10))
        mapView = MapView(frame: view.frame, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(mapView)

        mapView.mapboxMap.onNext(.mapLoaded) { _ in
            // initialize the custom location provoder with the location of your choice
            let customLocationProvider = CustomLocationProvider(currentLocation: CLLocation(latitude: 40.7131854, longitude: -74.0165265))
            self.mapView.location.overrideLocationProvider(with: customLocationProvider)
            var puck = LocationIndicatorLayer(id: "thing")
            puck.accuracyRadius = .constant(0.0)
            self.mapView.location.options.puckBearingSource = .course
            self.mapView.location.options.puckType = .puck2D()
        }
    }
}

class CustomLocationProvider: LocationProvider {
    var locationProviderOptions: LocationOptions

    let authorizationStatus: CLAuthorizationStatus

    let accuracyAuthorization: CLAccuracyAuthorization

    let heading: CLHeading?

    private let currentLocation: CLLocation

    private weak var delegate: LocationProviderDelegate?

    func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
        delegate.locationProvider(self, didUpdateLocations: [currentLocation])
    }

    func requestAlwaysAuthorization() {
        //
    }

    func requestWhenInUseAuthorization() {
        //
    }

    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        //
    }

    func startUpdatingLocation() {
        //
    }

    func stopUpdatingLocation() {
        //
    }

    var headingOrientation: CLDeviceOrientation

    func startUpdatingHeading() {
        //
    }

    func stopUpdatingHeading() {
        //
    }

    func dismissHeadingCalibrationDisplay() {
        //
    }

    init(currentLocation: CLLocation) {
        self.locationProviderOptions = .init()
        self.authorizationStatus = .notDetermined
        self.accuracyAuthorization = .fullAccuracy
        self.headingOrientation = .portrait
        self.heading = nil
        self.currentLocation = currentLocation
    }
}

