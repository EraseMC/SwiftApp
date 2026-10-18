import SwiftUI

extension View {

	/// A flat card separated by a hairline, the site's default panel.
	public func panel(padding: CGFloat = Space.s4) -> some View {
		self
			.padding(padding)
			.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
			.overlay {
				RoundedRectangle(cornerRadius: Radius.md)
					.strokeBorder(Palette.line)
			}
	}

	/// Liquid Glass on iOS 26 and later, a material on earlier systems.
	@ViewBuilder
	public func eraseGlass(cornerRadius: CGFloat = Radius.lg, tint: Color? = nil, interactive: Bool = false) -> some View {
		#if compiler(>=6.2)
		if #available(iOS 26, *) {
			glassEffect(
				Glass.regular.tint(tint).interactive(interactive),
				in: .rect(cornerRadius: cornerRadius)
			)
		} else {
			materialBackground(cornerRadius: cornerRadius, tint: tint)
		}
		#else
		materialBackground(cornerRadius: cornerRadius, tint: tint)
		#endif
	}

	private func materialBackground(cornerRadius: CGFloat, tint: Color?) -> some View {
		background {
			RoundedRectangle(cornerRadius: cornerRadius)
				.fill(.ultraThinMaterial)
				.overlay {
					if let tint {
						RoundedRectangle(cornerRadius: cornerRadius).fill(tint.opacity(0.18))
					}
				}
				.overlay {
					RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Palette.line)
				}
		}
	}
}

/// The site's press feedback: scale to 0.97 with a fast ease-out.
public struct PressableStyle: ButtonStyle {

	public init() {}

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.97 : 1)
			.animation(Motion.press, value: configuration.isPressed)
	}
}

/// The lime call-to-action, identical in both themes.
public struct PrimaryButtonStyle: ButtonStyle {

	public init() {}

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.body.weight(.semibold))
			.foregroundStyle(Palette.accentInk)
			.padding(.horizontal, Space.s5)
			.padding(.vertical, Space.s3)
			.frame(maxWidth: .infinity)
			.background(Palette.accent, in: .rect(cornerRadius: Radius.sm))
			.scaleEffect(configuration.isPressed ? 0.97 : 1)
			.animation(Motion.press, value: configuration.isPressed)
	}
}

extension ButtonStyle where Self == PrimaryButtonStyle {
	public static var erasePrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == PressableStyle {
	public static var pressable: PressableStyle { PressableStyle() }
}
