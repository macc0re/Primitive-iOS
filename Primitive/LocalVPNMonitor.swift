import Foundation
import Darwin
import Combine

@MainActor
final class LocalVPNMonitor: ObservableObject {
    private let expectedTunnelAddress = "10.7.1.1"

    @Published private(set) var tunnelDetected = false
    @Published private(set) var localDevVPNConnected = false
    @Published private(set) var checkedAt: Date?

    var statusTitle: String {
        if localDevVPNConnected { return "Local Dev VPN Connected" }
        if tunnelDetected { return "Other VPN Detected" }
        return "Disconnected"
    }

    var statusDetail: String {
        if localDevVPNConnected {
            return "The VPN tunnel has the expected address (10.7.1.1/32)."
        }
        if tunnelDetected {
            return "A VPN tunnel is active, but its address does not match Local Dev VPN."
        }
        return "Connect Local Dev VPN for supported AirLift connections. Device pairing is independent."
    }

    func refresh() {
        let result = Self.inspectTunnel(expectedAddress: expectedTunnelAddress)
        tunnelDetected = result.anyTunnel
        localDevVPNConnected = result.expectedTunnel
        checkedAt = Date()
    }

    private static func inspectTunnel(expectedAddress: String) -> (anyTunnel: Bool, expectedTunnel: Bool) {
        var firstAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddress) == 0, let firstAddress else {
            return (false, false)
        }
        defer { freeifaddrs(firstAddress) }

        var foundTunnel = false
        var foundExpectedAddress = false
        var current: UnsafeMutablePointer<ifaddrs>? = firstAddress

        while let item = current {
            let interface = item.pointee
            guard let namePointer = interface.ifa_name else {
                current = interface.ifa_next
                continue
            }

            let name = String(cString: namePointer)
            let isTunnelInterface = name.hasPrefix("utun")
                || name.hasPrefix("ipsec")
                || name.hasPrefix("ppp")
            let isUp = (interface.ifa_flags & UInt32(IFF_UP)) != 0

            if isTunnelInterface && isUp {
                foundTunnel = true

                if let addressPointer = interface.ifa_addr,
                   addressPointer.pointee.sa_family == UInt8(AF_INET) {
                    let address = addressPointer.withMemoryRebound(
                        to: sockaddr_in.self,
                        capacity: 1
                    ) { pointer in
                        String(cString: inet_ntoa(pointer.pointee.sin_addr))
                    }

                    if address == expectedAddress {
                        foundExpectedAddress = true
                    }
                }
            }

            current = interface.ifa_next
        }

        return (foundTunnel, foundExpectedAddress)
    }
}
