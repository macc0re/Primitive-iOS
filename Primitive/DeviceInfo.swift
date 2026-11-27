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
    let imageURL: URL?

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
        let imageHashes: [String: String] = [
            "iPhone14,6": "a88e812b0f83cddd273d46dc44a898ec6dd7c90d",
            "iPhone14,7": "4ea44d41f1cc3a3a91229b490ba0fed2b6de19c3",
            "iPhone14,8": "310f3c8e8fcf1e3cc1ab0f7db2b4735b0523cd4b",
            "iPhone15,2": "7eff2dfbf230b0887bfc32187f3b7f0e7f450713",
            "iPhone15,3": "c960a752fbc08daf5cddda1a271edb270a0f8520",
            "iPhone15,4": "dfb49c5b8fb0023e4ab060c49ae89b57e5ad2190",
            "iPhone15,5": "69d6770ff6f8c43513bece77d72e2842ede23cd2",
            "iPhone16,1": "c7b539e24c240eb0ab24ebd608712494d3f4fd02",
            "iPhone16,2": "b19ea241d6859cf7dd785b2b987ac27c9e700489",
            "iPhone17,1": "6f2efda860b18f66237c05852665b12b6833c1fc",
            "iPhone17,2": "9ec271b39b94169fb12b3f567a86e7adde280d47",
            "iPhone17,3": "d6eb976c75dac562fc7e68b64d747fe9513cd089",
            "iPhone17,4": "250967caa105b20934cbc42f232ae20602dde014",
            "iPad13,18": "839f9d93b71b90d342b1747202baeb51e6ba31dc",
            "iPad13,19": "79d46b1e8567ab18137c50b89d3862b8273cf8d"
        ]
        let imageURL = imageHashes[identifier].flatMap { URL(string: "https://ipsw.me/images/devices/\($0).webp") }
        let version = UIDevice.current.systemVersion
        let build = systemBuildNumber()
        return PrimitiveDeviceProfile(
            marketingName: detected?.0 ?? UIDevice.current.model,
            identifier: identifier,
            chip: detected?.1 ?? "Not identified",
            operatingSystem: "\(UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS") \(version)",
            systemBuild: build,
            symbol: detected?.2 ?? (UIDevice.current.userInterfaceIdiom == .pad ? "ipad.gen2" : "iphone.gen3"),
            imageURL: imageURL
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
