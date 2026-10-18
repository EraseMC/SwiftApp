import SwiftUI

/// One radius rule, as on the site.
public enum Radius {
	/// Chips, small badges, tiny icons.
	public static let xs: CGFloat = 6
	/// Buttons, inputs, controls.
	public static let sm: CGFloat = 10
	/// Panels and cards.
	public static let md: CGFloat = 14
	/// Sheets and feature surfaces.
	public static let lg: CGFloat = 20
}

/// The 4pt spacing scale.
public enum Space {
	public static let s1: CGFloat = 4
	public static let s2: CGFloat = 8
	public static let s3: CGFloat = 12
	public static let s4: CGFloat = 16
	public static let s5: CGFloat = 20
	public static let s6: CGFloat = 24
	public static let s8: CGFloat = 32
	public static let s10: CGFloat = 40
	public static let s12: CGFloat = 48
	public static let s16: CGFloat = 64
}

/// Motion mirrors `lib/motion.ts`: ease-out for entering, springs for moving, exits faster than enters.
public enum Motion {
	public static let press = Animation.easeOut(duration: 0.12)
	public static let hover = Animation.easeOut(duration: 0.16)
	public static let popover = Animation.easeOut(duration: 0.22)
	public static let reveal = Animation.easeOut(duration: 0.5)
	public static let scope = Animation.spring(duration: 0.36, bounce: 0.14)
	public static let sheet = Animation.spring(duration: 0.4, bounce: 0.06)
}
