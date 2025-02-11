//
//  Auto-generated file. Do not edit.
//

import UIKit

extension UIColor {
    
    @available(iOS 13.0, *)
    public static func themColor(named: String) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: darkColors[named] ?? "") : UIColor(hex: lightColors[named] ?? "")
        }
    }
    
    private static var lightColors: [String: String] {
        var colors = [String: String]()
        guard let bundlePath = Bundle.main.path(forResource: "Common", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath)
        else {
            assertionFailure("Common bundle is nil")
            return colors
        }
        if let path = bundle.path(forResource: "colors_light", ofType: "strings"),
           let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
            colors = dictionary
        }
        return colors
    }
    
    private static var darkColors: [String: String] {
        var colors = [String: String]()
        guard let bundlePath = Bundle.main.path(forResource: "Common", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath)
        else {
            assertionFailure("Common bundle is nil")
            return colors
        }
        if let path = bundle.path(forResource: "colors_dark", ofType: "strings"),
           let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
            colors = dictionary
        }
        return colors
    }

    fileprivate convenience init(hex: String) {
        let r, g, b: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let end = hex.index(hex.endIndex, offsetBy: -1)

        let hexString = String(hex[start..<end])
        let hexNumber = Int(hexString, radix: 16) ?? 0
        r = CGFloat((hexNumber >> 16) & 0xFF) / 255.0
        g = CGFloat((hexNumber >> 8) & 0xFF) / 255.0
        b = CGFloat(hexNumber & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
