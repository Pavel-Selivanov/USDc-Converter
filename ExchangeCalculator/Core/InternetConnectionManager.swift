//
//  InternetConnectionManager.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/11/26.
//

import Foundation
import Network

public final class InternetConnectionManager {
    public static let shared = InternetConnectionManager()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "Connectivity.Monitor")

    private let stateQueue = DispatchQueue(label: "Connectivity.State", attributes: .concurrent)
    private var _isConnected: Bool = true
    private var statusContinuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    
    // Connectivity verification
    private var connectivityCheckTask: Task<Void, Never>?
    private let connectivityTimeout: TimeInterval = 10.0
    
    /// The single public flag indicating whether connectivity is available (thread-safe read).
    public var isConnectedToNetwork: Bool {
        stateQueue.sync { _isConnected }
    }

    public var connectionStatusUpdates: AsyncStream<Bool> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let id = UUID()
            stateQueue.async(flags: .barrier) { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                statusContinuations[id] = continuation
                continuation.yield(_isConnected)
            }

            continuation.onTermination = { [weak self] _ in
                self?.stateQueue.async(flags: .barrier) { [weak self] in
                    self?.statusContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        // First check: path status must be satisfied
        guard path.status == .satisfied else {
            setConnected(false)
            return
        }
        
        // Second check: verify the path has usable interfaces
        // This helps filter out VPN connections that are still establishing
        let hasUsableInterface = path.availableInterfaces.contains { interface in
            // Check for WiFi, Cellular, or Wired (Ethernet) - skip VPN-only interfaces
            interface.type == .wifi || interface.type == .cellular || interface.type == .wiredEthernet
        }
        
        guard hasUsableInterface else {
            setConnected(false)
            return
        }
        
        // Third check: for VPN connections, verify actual internet connectivity
        // VPN can report .satisfied before the tunnel is fully established
        if path.usesInterfaceType(.other) || path.isExpensive {
            // Cancel any existing connectivity check
            connectivityCheckTask?.cancel()
            
            // Perform actual connectivity verification
            connectivityCheckTask = Task { [weak self] in
                let isReallyConnected = await self?.verifyInternetConnectivity() ?? false
                guard !Task.isCancelled else { return }
                self?.setConnected(isReallyConnected)
            }
        } else {
            // Regular WiFi/Cellular without VPN - trust the path status
            setConnected(true)
        }
    }
    
    /// Verifies real internet connectivity by attempting to connect to a reliable endpoint
    /// Returns true only if connection succeeds within the timeout period
    private func verifyInternetConnectivity() async -> Bool {
        // Use Apple's captive portal detection endpoint - it's lightweight and reliable
        guard let url = URL(string: "https://captive.apple.com/hotspot-detect.html") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = connectivityTimeout
        request.httpMethod = "HEAD" // HEAD request is lighter than GET
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // Apple's captive portal returns 200 for successful connectivity
            return httpResponse.statusCode == 200
        } catch {
            // If we can't reach the endpoint, we don't have real internet connectivity
            return false
        }
    }

    private func setConnected(_ value: Bool) {
        stateQueue.async(flags: .barrier) { [weak self] in
            guard let self, _isConnected != value else { return }

            _isConnected = value
            statusContinuations.values.forEach { continuation in
                continuation.yield(value)
            }
        }
    }

    deinit {
        connectivityCheckTask?.cancel()
        monitor.cancel()
    }
}
