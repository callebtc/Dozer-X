import Cocoa

struct MenuBarVisibilityState: Equatable {
    var hideNormal = false
    var hideRemove = false
    static let expanded = MenuBarVisibilityState()
}

enum MenuBarVisibilityConfiguration {
    case unrestricted
    case allowing([String])

    func activate(completion: @escaping (Any?, Error?) -> Void) {
        switch self {
        case .unrestricted:
            DozerNativeVisibilityActivate(nil, completion)
        case .allowing(let bundles):
            DozerNativeVisibilityActivate(bundles, completion)
        }
    }
}

protocol MenuBarVisibilityAssertion: AnyObject {
    func update(_ configuration: MenuBarVisibilityConfiguration, completion: @escaping (Error?) -> Void)
    func invalidate()
}

protocol MenuBarVisibilityProviding {
    var isAvailable: Bool { get }
    func activate(
        _ configuration: MenuBarVisibilityConfiguration,
        completion: @escaping (Result<MenuBarVisibilityAssertion, Error>) -> Void
    )
}

final class NativeVisibilityAssertion: MenuBarVisibilityAssertion {
    private var value: AnyObject?
    private var isInvalidated = false
    private var isUpdating = false
    private var pendingUpdate: (configuration: MenuBarVisibilityConfiguration, completion: (Error?) -> Void)?

    init(_ value: AnyObject) { self.value = value }

    private var cancelled: Error { NSError(domain: "DozerNativeVisibility", code: NSUserCancelledError) }

    func update(_ configuration: MenuBarVisibilityConfiguration, completion: @escaping (Error?) -> Void) {
        guard !isInvalidated else {
            completion(cancelled)
            return
        }
        if isUpdating {
            let previous = pendingUpdate
            pendingUpdate = (configuration, completion)
            previous?.completion(cancelled)
            return
        }
        isUpdating = true
        if let previous = value { DozerNativeVisibilityInvalidate(previous) }
        value = nil
        configuration.activate { [weak self] replacement, error in
            guard let self = self, !self.isInvalidated else {
                if let replacement = replacement { DozerNativeVisibilityInvalidate(replacement) }
                return
            }
            self.isUpdating = false
            self.value = replacement as AnyObject?
            completion(error ?? (replacement == nil ? NSError(domain: "DozerNativeVisibility", code: 1) : nil))
            if let pending = self.pendingUpdate {
                self.pendingUpdate = nil
                self.update(pending.configuration, completion: pending.completion)
            }
        }
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }
        isInvalidated = true
        if let value = value { DozerNativeVisibilityInvalidate(value) }
        self.value = nil
        let pending = pendingUpdate
        pendingUpdate = nil
        pending?.completion(cancelled)
    }

    deinit { invalidate() }
}

struct NativeVisibilityService: MenuBarVisibilityProviding {
    var isAvailable: Bool { DozerNativeVisibilityIsAvailable() }

    func activate(
        _ configuration: MenuBarVisibilityConfiguration,
        completion: @escaping (Result<MenuBarVisibilityAssertion, Error>) -> Void
    ) {
        configuration.activate { assertion, error in
            if let assertion = assertion {
                completion(.success(NativeVisibilityAssertion(assertion as AnyObject)))
            } else {
                completion(.failure(error ?? NSError(domain: "DozerNativeVisibility", code: 1)))
            }
        }
    }
}

final class NativeMenuBarVisibility {
    static let recoveryPreference = "nativeMenuBarVisibilityNeedsRecovery"
    static var needsRecovery: Bool { UserDefaults.standard.bool(forKey: recoveryPreference) }

    enum Section: Int {
        case remove, normal, visible
    }

    private let inventory: MenuBarInventoryProviding
    private let service: MenuBarVisibilityProviding
    private let ownBundle: String
    private let preferences: UserDefaults
    private let runningBundles: () -> [String]
    private var assertion: MenuBarVisibilityAssertion?
    private var sections: [String: Section] = [:]
    private var hasSnapshot = false
    private var generation = 0
    private var isApplying = false
    private(set) var requestedState = MenuBarVisibilityState.expanded

    init(
        inventory: MenuBarInventoryProviding = MenuBarInventory(),
        service: MenuBarVisibilityProviding = NativeVisibilityService(),
        ownBundle: String = Bundle.main.bundleIdentifier ?? "com.mortennn.Dozer",
        preferences: UserDefaults = .standard,
        runningBundles: @escaping () -> [String] = {
            NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        }
    ) {
        self.inventory = inventory
        self.service = service
        self.ownBundle = ownBundle
        self.preferences = preferences
        self.runningBundles = runningBundles
    }

    static func classify(
        _ items: [MenuBarInventoryItem],
        normal: CGRect,
        remove: CGRect?,
        screen: CGRect? = nil
    ) -> [String: Section] {
        var result: [String: Section] = [:]
        for item in items {
            var section = Section.visible
            let center = CGPoint(x: item.frame.midX, y: item.frame.midY)
            if screen?.contains(center) != false,
               abs(item.frame.midY - normal.midY) < max(normal.height, item.frame.height),
               item.frame.midX < normal.midX {
                section = .normal
                if let remove = remove, item.frame.midX < remove.midX {
                    section = .remove
                }
            }
            if let previous = result[item.bundleIdentifier], previous.rawValue > section.rawValue {
                continue
            }
            result[item.bundleIdentifier] = section
        }
        return result
    }

    func apply(
        _ state: MenuBarVisibilityState,
        normal: CGRect?,
        remove: CGRect?,
        screen: CGRect? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        generation += 1
        let request = generation
        requestedState = state
        if state == .expanded {
            assertion?.invalidate()
            assertion = nil
            sections.removeAll()
            hasSnapshot = false
            guard service.isAvailable else {
                restore()
                completion(nil)
                return
            }
            startApplying(request: request, completion: completion)
            service.activate(.unrestricted) { [weak self] result in
                if case .success(let unrestricted) = result { unrestricted.invalidate() }
                guard let self = self, self.generation == request else {
                    return
                }
                self.restore()
                switch result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
            return
        }

        func fail(_ message: String) {
            restore()
            completion(NSError(
                domain: "DozerNativeVisibility",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        }
        guard service.isAvailable else {
            fail("Menu bar hiding is unavailable on this version of macOS. Dozer's visibility restrictions have been released.")
            return
        }
        guard inventory.isAuthorized else {
            inventory.requestAuthorization()
            fail("Allow Dozer in System Settings → Privacy & Security → Accessibility, then click a Dozer dot again.")
            return
        }
        preferences.set(true, forKey: Self.recoveryPreference)
        startApplying(request: request, completion: completion)

        let activate: ([String: Section]) -> Void = { [weak self] sections in
            guard let self = self, self.generation == request else {
                return
            }
            self.sections = sections
            self.hasSnapshot = true
            let hidden = Set(sections.compactMap { bundle, section -> String? in
                if section == .remove && state.hideRemove || section == .normal && state.hideNormal {
                    return bundle
                }
                return nil
            })
            let allowed = Set(self.runningBundles()).union(sections.keys).subtracting(hidden).union([self.ownBundle])
            let updating = self.assertion
            let finish: (Result<MenuBarVisibilityAssertion, Error>) -> Void = { [weak self] result in
                guard let self = self, self.generation == request else {
                    if case .success(let stale) = result, stale !== updating { stale.invalidate() }
                    return
                }
                self.isApplying = false
                switch result {
                case .success(let replacement):
                    let previous = self.assertion
                    self.assertion = replacement
                    if previous !== replacement { previous?.invalidate() }
                    completion(nil)
                case .failure(let error):
                    self.restore()
                    completion(error)
                }
            }
            if let updating = updating {
                updating.update(.allowing(allowed.sorted())) { error in
                    if let error = error { finish(.failure(error)) } else { finish(.success(updating)) }
                }
            } else {
                self.service.activate(.allowing(allowed.sorted()), completion: finish)
            }
        }

        if hasSnapshot {
            activate(sections)
        } else if let normal = normal, normal.width > 0, normal.height > 0,
                  normal.minX.isFinite, normal.minY.isFinite, normal.maxX.isFinite, normal.maxY.isFinite {
            inventory.snapshot { [weak self] items in
                guard let self = self, self.generation == request else {
                    return
                }
                activate(Self.classify(items, normal: normal, remove: remove, screen: screen))
            }
        } else {
            fail("Dozer could not read the separator's position. Show both dots in the menu bar and try again.")
        }
    }

    private func startApplying(request: Int, completion: @escaping (Error?) -> Void) {
        isApplying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, self.generation == request, self.isApplying else {
                return
            }
            self.restore()
            completion(NSError(
                domain: "DozerNativeVisibility",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "The menu bar did not respond. Dozer's visibility restrictions have been released."]
            ))
        }
    }

    func restore() {
        generation += 1
        isApplying = false
        requestedState = .expanded
        assertion?.invalidate()
        assertion = nil
        sections.removeAll()
        hasSnapshot = false
        preferences.removeObject(forKey: Self.recoveryPreference)
    }

    deinit { assertion?.invalidate() }
}
