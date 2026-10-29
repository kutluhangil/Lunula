import AppKit
import CoreLocation

public protocol LocationProviding: Sendable {
    func currentCoordinate() async throws -> (latitude: Double, longitude: Double)
}

/// One-shot, ~3 km accuracy. Asks for permission only when weather actually needs it (home became visible).
public final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    // Manager and continuation are touched on the main thread only.
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<(latitude: Double, longitude: Double), Error>?

    override public init() { super.init() }

    public func currentCoordinate() async throws -> (latitude: Double, longitude: Double) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { self.begin(continuation) }
        }
    }

    private func begin(_ continuation: CheckedContinuation<(latitude: Double, longitude: Double), Error>) {
        self.continuation?.resume(throwing: CancellationError())
        self.continuation = continuation
        let manager = self.manager ?? CLLocationManager()
        self.manager = manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        switch manager.authorizationStatus {
        case .notDetermined:
            NSApp.activate()
            manager.requestWhenInUseAuthorization()  // continues in locationManagerDidChangeAuthorization
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        default:
            finish(.failure(CLError(.denied)))
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized: manager.requestLocation()
        case .notDetermined: break
        default: finish(.failure(CLError(.denied)))
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        finish(.success((c.latitude, c.longitude)))
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<(latitude: Double, longitude: Double), Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
