import Foundation
import UIKit
import Darwin

struct PrimitiveDeviceProfile {
    let marketingName: String
    let identifier: String
    let chip: String
    let operatingSystem: String
    let systemBuild: String
    let symbol: String

    static var current: PrimitiveDeviceProfile {
        let identifier = machineIdentifier()
        let names: [String: (String, String, String)] = [
            "iPhone14,6": ("iPhone SE (3rd generation)", "A15 Bionic", "iphone.gen3"),
            "iPhone14,7": ("iPhone 14", "A15 Bionic", "iphone.gen3"),
            "iPhone14,8": ("iPhone 14 Plus", "A15 Bionic", "iphone.gen3"),
            "iPhone15,2": ("iPhone 14 Pro", "A16 Bionic", "iphone.gen3"),
            "iPhone15,3": ("iPhone 14 Pro Max", "A16 Bionic", "iphone.gen3"),
            "iPhone15,4": ("iPhone 15", "A16 Bionic", "iphone.gen3"),
            "iPhone15,5": ("iPhone 15 Plus", "A16 Bionic", "iphone.gen3"),
            "iPhone16,1": ("iPhone 15 Pro", "A17 Pro", "iphone.gen3"),
            "iPhone16,2": ("iPhone 15 Pro Max", "A17 Pro", "iphone.gen3"),
            "iPhone17,3": ("iPhone 16", "A18", "iphone.gen3"),
            "iPhone17,4": ("iPhone 16 Plus", "A18", "iphone.gen3"),
            "iPhone17,1": ("iPhone 16 Pro", "A18 Pro", "iphone.gen3"),
            "iPhone17,2": ("iPhone 16 Pro Max", "A18 Pro", "iphone.gen3"),
            "iPad13,18": ("iPad (10th generation)", "A14 Bionic", "ipad.gen2"),
            "iPad13,19": ("iPad (10th generation)", "A14 Bionic", "ipad.gen2")
        ]
        let detected = names[identifier]
        let version = UIDevice.current.systemVersion
        let build = systemBuildNumber()
        return PrimitiveDeviceProfile(
            marketingName: detected?.0 ?? UIDevice.current.model,
            identifier: identifier,
            chip: detected?.1 ?? "Not identified",
            operatingSystem: "\(UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS") \(version)",
            systemBuild: build,
            symbol: detected?.2 ?? (UIDevice.current.userInterfaceIdiom == .pad ? "ipad.gen2" : "iphone.gen3")
        )
    }

    private static func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = systemInfo.machine
        return withUnsafePointer(to: machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: machine)) {
                String(cString: $0)
            }
        }
    }

    private static func systemBuildNumber() -> String {
        var size = 0
        guard sysctlbyname("kern.osversion", nil, &size, nil, 0) == 0, size > 0 else {
            return "Build unavailable"
        }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.osversion", &value, &size, nil, 0) == 0 else {
            return "Build unavailable"
        }
        return String(cString: value)
    }
}
