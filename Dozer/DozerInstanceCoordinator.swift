import Cocoa
import Darwin

protocol DozerRunningInstance: AnyObject {
    var processIdentifier: pid_t { get }
    var isTerminated: Bool { get }
    func terminate() -> Bool
}

extension NSRunningApplication: DozerRunningInstance {}

final class DozerInstanceCoordinator {
    enum Startup {
        case primary(recovered: Bool)
        case secondary
    }

    static let restoreNotification = Notification.Name("com.mortennn.Dozer.restoreMenuBarVisibility")

    private let lockURL: URL
    private let processIdentifier: pid_t
    private let runningInstances: () -> [DozerRunningInstance]
    private let timeout: TimeInterval
    private var lockDescriptor: Int32 = -1
    private var recoveryTimer: Timer?

    init(
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.mortennn.Dozer",
        lockURL: URL? = nil,
        processIdentifier: pid_t = ProcessInfo.processInfo.processIdentifier,
        runningInstances: (() -> [DozerRunningInstance])? = nil,
        timeout: TimeInterval = 5
    ) {
        self.lockURL = lockURL ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("MenuBarVisibility.lock")
        self.processIdentifier = processIdentifier
        self.runningInstances = runningInstances ?? {
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).map { $0 as DozerRunningInstance }
        }
        self.timeout = timeout
    }

    func start(completion: @escaping (Result<Startup, Error>) -> Void) {
        do {
            try FileManager.default.createDirectory(
                at: lockURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } catch {
            completion(.failure(error))
            return
        }
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else {
            completion(.failure(POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)))
            return
        }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let failure = errno
            close(descriptor)
            if failure == EWOULDBLOCK {
                completion(.success(.secondary))
            } else {
                completion(.failure(POSIXError(POSIXErrorCode(rawValue: failure) ?? .EIO)))
            }
            return
        }
        lockDescriptor = descriptor
        let previous = runningInstances().filter { $0.processIdentifier != processIdentifier && !$0.isTerminated }
        guard !previous.isEmpty else {
            completion(.success(.primary(recovered: false)))
            return
        }
        var refused = false
        for instance in previous {
            if !instance.terminate() && !instance.isTerminated { refused = true }
        }
        guard !refused else {
            stop()
            completion(.failure(recoveryError))
            return
        }
        let deadline = Date.timeIntervalSinceReferenceDate + timeout
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if previous.allSatisfy({ $0.isTerminated }) {
                timer.invalidate()
                self.recoveryTimer = nil
                completion(.success(.primary(recovered: true)))
            } else if Date.timeIntervalSinceReferenceDate >= deadline {
                self.stop()
                completion(.failure(self.recoveryError))
            }
        }
        recoveryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    }

    private var recoveryError: Error {
        NSError(
            domain: "DozerInstanceRecovery",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Another Dozer instance is still running. Quit it before opening this copy. No additional icons have been hidden."]
        )
    }

    func stop() {
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        guard lockDescriptor >= 0 else {
            return
        }
        flock(lockDescriptor, LOCK_UN)
        close(lockDescriptor)
        lockDescriptor = -1
    }

    deinit { stop() }
}
