import Foundation
import Darwin
import Combine

@MainActor
final class LocalVPNMonitor: ObservableObject {
    @Published private(set) var tunnelDetected = false
    @Published private(set) var checkedAt: Date?

    var statusTitle: String {
        tunnelDetected ? "VPN tunnel detected" : "No VPN tunnel detected"
    }

    var statusDetail: String {
        tunnelDetected
            ? "A VPN tunnel is active. Confirm that Local Dev VPN is the connected VPN."
            : "Connect Local Dev VPN before starting device pairing."
    }

    func refresh() {
        tunnelDetected = Self.hasActiveTunnelInterface()
        checkedAt = Date()
    }

    private static func hasActiveTunnelInterface() -> Bool {
        var firstAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddress) == 0, let firstAddress else {
            return false
        }
        defer { freeifaddrs(firstAddress) }

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while let item = current {
            let interface = item.pointee
            if let namePointer = interface.ifa_name {
                let name = String(cString: namePointer)
                let isTunnelInterface = name.hasPrefix("utun")
                    || name.hasPrefix("ipsec")
                    || name.hasPrefix("ppp")
                let isUp = (interface.ifa_flags & UInt32(IFF_UP)) != 0
                let hasAddress = interface.ifa_addr != nil
                if isTunnelInterface && isUp && hasAddress {
                    return true
                }
            }
            current = interface.ifa_next
        }
        return false
    }
}
