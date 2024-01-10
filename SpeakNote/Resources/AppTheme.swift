//
//  AppTheme.swift
//  SpeakNote
//
//  Created by Sailor on 12/17/23.
//

import Foundation

import UIKit

struct AppColors {    
    static let primaryGreen = UIColor(hex: "4ba885")
    static let secondaryGreen = UIColor(hex: "025b4e")
    static let thirdGreen = UIColor(hex: "005831")
    static let borderColor = UIColor.black.cgColor //UIColor(hex: "005b4a").cgColor
}

struct AppLayout {
    static let leadingConstant: CGFloat = 30
    static let trailingConstant: CGFloat = -30
    static let borderWidth: CGFloat = 1.0
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = scanner.string.startIndex

        var rgbValue: UInt64 = 0

        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff,
            alpha: 1
        )
    }
}
