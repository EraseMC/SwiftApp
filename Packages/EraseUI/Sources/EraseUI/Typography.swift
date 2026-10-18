import SwiftUI

/// The site's three faces: Geologica for headings, Onest for interface text,
/// JetBrains Mono for every number a reader might compare. All scale with Dynamic Type.
/// The fonts are registered by the app's Info.plist (`UIAppFonts`).
public enum Typeface {

	public enum Weight: Sendable {
		case regular
		case medium
		case semibold
		case bold
	}

	public static func display(_ size: CGFloat, _ weight: Weight = .bold, relativeTo style: Font.TextStyle = .title) -> Font {
		let name = switch weight {
		case .regular, .medium: "Geologica-Medium"
		case .semibold: "Geologica-SemiBold"
		case .bold: "Geologica-Bold"
		}
		return .custom(name, size: size, relativeTo: style)
	}

	public static func body(_ size: CGFloat, _ weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
		let name = switch weight {
		case .regular: "Onest-Regular"
		case .medium: "Onest-Medium"
		case .semibold: "Onest-SemiBold"
		case .bold: "Onest-Bold"
		}
		return .custom(name, size: size, relativeTo: style)
	}

	public static func mono(_ size: CGFloat, _ weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
		let name = switch weight {
		case .regular: "JetBrainsMonoRoman-Regular"
		case .medium, .semibold: "JetBrainsMonoRoman-Medium"
		case .bold: "JetBrainsMonoRoman-Bold"
		}
		return .custom(name, size: size, relativeTo: style)
	}
}

extension Font {
	public static let eraseHero = Typeface.display(34, .bold, relativeTo: .largeTitle)
	public static let eraseTitle = Typeface.display(28, .bold, relativeTo: .title)
	public static let eraseTitle2 = Typeface.display(22, .semibold, relativeTo: .title2)
	public static let eraseTitle3 = Typeface.display(19, .semibold, relativeTo: .title3)
	public static let eraseHeadline = Typeface.body(16, .semibold, relativeTo: .headline)
	public static let eraseBody = Typeface.body(16, .regular, relativeTo: .body)
	public static let eraseCallout = Typeface.body(15, .regular, relativeTo: .callout)
	public static let eraseFootnote = Typeface.body(13, .regular, relativeTo: .footnote)
	public static let eraseCaption = Typeface.body(11, .medium, relativeTo: .caption)
	public static let eraseStat = Typeface.mono(22, .bold, relativeTo: .title2)
	public static let eraseNumber = Typeface.mono(15, .medium, relativeTo: .body)
	public static let eraseSmallNumber = Typeface.mono(12, .medium, relativeTo: .footnote)
}
