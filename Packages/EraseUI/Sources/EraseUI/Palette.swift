import SwiftUI
import UIKit

/// The site's colour tokens (`Imprint-Web/app/globals.css`), resolved per appearance.
/// Dark is the default; light is a full equal theme.
public enum Palette {
	public static let background = Color(dark: 0x090C09, light: 0xF6F8F4)
	public static let sunken = Color(dark: 0x060806, light: 0xEEF2EA)
	public static let surface = Color(dark: 0x101510, light: 0xFFFFFF)
	public static let surfaceRaised = Color(dark: 0x151B14, light: 0xFFFFFF)
	public static let surfaceHover = Color(dark: 0x1A211A, light: 0xF2F5EF)
	public static let surfaceActive = Color(dark: 0x202820, light: 0xE9EEE4)

	public static let line = Color(dark: (0xFFFFFF, 0.07), light: (0x0C120B, 0.09))
	public static let lineStrong = Color(dark: (0xFFFFFF, 0.13), light: (0x0C120B, 0.16))

	public static let text = Color(dark: 0xECF1EA, light: 0x0C120B)
	public static let text2 = Color(dark: 0xAAB6A9, light: 0x4A544A)
	public static let text3 = Color(dark: 0x8A968A, light: 0x5E6A5D)

	/// The lime fill never changes between themes and always carries near-black ink.
	public static let accent = Color(hex: 0xA8F038)
	public static let accentInk = Color(hex: 0x0A1206)
	/// Lime used as text darkens on light grounds to stay readable.
	public static let accentText = Color(dark: 0xA8F038, light: 0x47700D)
	public static let accentSoft = Color(dark: (0xA8F038, 0.12), light: (0x4F7A10, 0.10))

	public static let win = Color(dark: 0x5FD98B, light: 0x12703F)
	public static let loss = Color(dark: 0xFF6B6B, light: 0xB62E2E)
	public static let warn = Color(dark: 0xF5B942, light: 0xA8710A)
	public static let gold = Color(dark: 0xF2C14E, light: 0x8A6410)
	public static let silver = Color(dark: 0xC6D0D8, light: 0x6D7780)
	public static let bronze = Color(dark: 0xCF8F4F, light: 0x97632F)
	public static let casual = Color(dark: 0x62D9FF, light: 0x0A6D8F)
}

extension Color {

	init(hex: UInt32, opacity: Double = 1) {
		self.init(uiColor: UIColor(hex: hex, alpha: opacity))
	}

	init(dark: UInt32, light: UInt32) {
		self.init(dark: (dark, 1), light: (light, 1))
	}

	init(dark: (UInt32, Double), light: (UInt32, Double)) {
		self.init(uiColor: UIColor { traits in
			traits.userInterfaceStyle == .light
				? UIColor(hex: light.0, alpha: light.1)
				: UIColor(hex: dark.0, alpha: dark.1)
		})
	}
}

extension UIColor {

	convenience init(hex: UInt32, alpha: Double) {
		self.init(
			red: CGFloat((hex >> 16) & 0xFF) / 255,
			green: CGFloat((hex >> 8) & 0xFF) / 255,
			blue: CGFloat(hex & 0xFF) / 255,
			alpha: alpha
		)
	}
}
