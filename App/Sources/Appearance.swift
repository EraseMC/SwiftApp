import EraseUI
import UIKit

/// UIKit chrome that SwiftUI does not style: navigation titles in the display face.
enum Appearance {

	static func apply() {
		let navigation = UINavigationBar.appearance()
		navigation.largeTitleTextAttributes = [.font: font("Geologica-Bold", size: 34, style: .largeTitle)]
		navigation.titleTextAttributes = [.font: font("Geologica-SemiBold", size: 17, style: .headline)]
	}

	private static func font(_ name: String, size: CGFloat, style: UIFont.TextStyle) -> UIFont {
		let base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .bold)
		return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
	}
}
