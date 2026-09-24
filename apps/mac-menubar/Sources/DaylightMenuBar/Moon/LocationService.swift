// CoreLocation adapter for the native moon observation panel.
// Exports: LocationService, LocationState, ObserverLocation, LocationStartResolution
// Deps: Foundation Date, CoreLocation, DaylightStore

import Foundation
import CoreLocation

struct ObserverLocation: Equatable, Hashable {
    let latitudeDegrees: Double
    let longitudeDegrees: Double
}

enum LocationState: Equatable {
    case waiting
    case authorized(ObserverLocation)
    case unavailable(String)
}

enum LocationStartResolution: Equatable {
    case needsPrompt
    case useCached(ObserverLocation)
    case requestLive
    case unavailable(String)
}

final class LocationService: NSObject, CLLocationManagerDelegate {
    var onStateChanged: ((LocationState) -> Void)?

    static let observerLocationCacheTTL: TimeInterval = 7 * 24 * 60 * 60

    private let store: DaylightStore
    private let now: () -> Date
    private let manager = CLLocationManager()
    private var hasStarted = false

    static func needsPermissionPrompt(store: DaylightStore, now: Date = Date()) -> Bool {
        let cachedLocation = freshCachedObserverLocation(from: store, now: now)
        return resolution(for: CLLocationManager().authorizationStatus, cachedLocation: cachedLocation) == .needsPrompt
    }

    static func freshCachedObserverLocation(from store: DaylightStore, now: Date = Date()) -> ObserverLocation? {
        guard let cached = store.cachedObserverLocation(),
              now.timeIntervalSince(cached.timestamp) < observerLocationCacheTTL else {
            return nil
        }
        return cached.observerLocation
    }

    static func resolution(for authorizationStatus: CLAuthorizationStatus, cachedLocation: ObserverLocation?) -> LocationStartResolution {
        switch authorizationStatus {
        case .notDetermined:
            if let cachedLocation { return .useCached(cachedLocation) }
            return .needsPrompt
        case .authorizedAlways, .authorizedWhenInUse:
            return .requestLive
        case .denied, .restricted:
            // A revoked permission must not be bypassed with a stored coordinate.
            return .unavailable("Location permission is disabled")
        @unknown default:
            return .unavailable("Location status is unknown")
        }
    }

    init(store: DaylightStore = DaylightStore(), now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func start() {
        hasStarted = true
        let cachedLocation = Self.freshCachedObserverLocation(from: store, now: now())
        switch Self.resolution(for: manager.authorizationStatus, cachedLocation: cachedLocation) {
        case .needsPrompt:
            onStateChanged?(.waiting)
            manager.requestWhenInUseAuthorization()
        case let .useCached(location):
            onStateChanged?(.authorized(location))
        case .requestLive:
            if let cachedLocation {
                onStateChanged?(.authorized(cachedLocation))
            } else {
                onStateChanged?(.waiting)
            }
            manager.requestLocation()
        case let .unavailable(reason):
            if manager.authorizationStatus == .denied {
                store.clearObserverLocation()
            }
            onStateChanged?(.unavailable(reason))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        start()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            onStateChanged?(.unavailable("Location is unavailable"))
            return
        }
        let location = ObserverLocation(
            latitudeDegrees: coordinate.latitude,
            longitudeDegrees: coordinate.longitude
        )
        store.saveObserverLocation(location, timestamp: now())
        onStateChanged?(.authorized(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onStateChanged?(.unavailable("Location lookup failed"))
    }
}
