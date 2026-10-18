import Foundation

/// The site's own wording, generated into the app's `Web.xcstrings` by `tools/gen-strings.mjs`.
/// Keys are the site's (`tiers.title`), placeholders keep its `{name}` form.
public enum Copy {

	public static func text(_ key: String, _ vars: [String: any CustomStringConvertible] = [:]) -> String {
		var value = Bundle.main.localizedString(forKey: key, value: key, table: "Web")
		for (name, replacement) in vars {
			value = value.replacingOccurrences(of: "{\(name)}", with: replacement.description)
		}
		return value
	}
}
