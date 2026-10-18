import EraseKit
import SwiftUI

extension PlayerRank {

	/// The rank's Minecraft colour. Dark ranks are lifted on dark grounds and
	/// light ones darkened on light grounds so every name stays readable.
	public var tint: Color {
		let hex = UInt32(color.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0xAAAAAA
		return Color(uiColor: UIColor { traits in
			let base = UIColor(hex: hex, alpha: 1)
			var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
			base.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

			if traits.userInterfaceStyle == .light {
				return UIColor(hue: hue, saturation: saturation, brightness: min(brightness, 0.62), alpha: 1)
			}
			return UIColor(hue: hue, saturation: saturation, brightness: max(brightness, 0.72), alpha: 1)
		})
	}
}

/// A player's name in the colour of their rank.
public struct RankedName: View {

	let name: String

	let rank: PlayerRank

	public init(_ name: String, rank: PlayerRank) {
		self.name = name
		self.rank = rank
	}

	public var body: some View {
		Text(verbatim: name)
			.foregroundStyle(rank.tint)
			.lineLimit(1)
	}
}

/// The rendered skin head from Imprint, kept pixel-sharp.
public struct PlayerHead: View {

	let name: String

	let size: CGFloat

	public init(_ name: String, size: CGFloat = 32) {
		self.name = name
		self.size = size
	}

	public var body: some View {
		AsyncImage(url: API.skinURL(name, part: .head, size: 64)) { phase in
			if let image = phase.image {
				image.resizable().interpolation(.none)
			} else {
				Palette.surfaceActive
			}
		}
		.frame(width: size, height: size)
		.clipShape(.rect(cornerRadius: max(Radius.xs, size * 0.18)))
		.accessibilityHidden(true)
	}
}

/// A mode's pixel icon from the app's asset catalogue.
public struct ModeIcon: View {

	let mode: Mode

	let size: CGFloat

	public init(_ mode: Mode, size: CGFloat = 24) {
		self.mode = mode
		self.size = size
	}

	public var body: some View {
		Image(mode.icon, bundle: .main)
			.resizable()
			.interpolation(.none)
			.frame(width: size, height: size)
			.accessibilityHidden(true)
	}
}

/// A labelled figure: big monospaced number, quiet label above.
public struct StatTile: View {

	let label: LocalizedStringKey

	let value: String

	let tint: Color

	public init(_ label: LocalizedStringKey, value: String, tint: Color = Palette.text) {
		self.label = label
		self.value = value
		self.tint = tint
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: Space.s1) {
			Text(label)
				.font(.eraseCaption)
				.textCase(.uppercase)
				.foregroundStyle(Palette.text3)
			Text(verbatim: value)
				.font(.eraseStat)
				.foregroundStyle(tint)
				.contentTransition(.numericText())
				.lineLimit(1)
				.minimumScaleFactor(0.6)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.panel(padding: Space.s3)
		.accessibilityElement(children: .combine)
	}
}

/// The site's pill toggle (Ranked | Casual), with a sliding thumb.
public struct PillPicker<Value: Hashable, Label: View>: View {

	@Binding var selection: Value

	let options: [Value]

	let label: (Value) -> Label

	@Namespace private var thumb

	public init(selection: Binding<Value>, options: [Value], @ViewBuilder label: @escaping (Value) -> Label) {
		self._selection = selection
		self.options = options
		self.label = label
	}

	public var body: some View {
		HStack(spacing: 2) {
			ForEach(options, id: \.self) { option in
				let selected = option == selection
				Button {
					withAnimation(Motion.scope) { selection = option }
				} label: {
					label(option)
						.font(.eraseFootnote.weight(.semibold))
						.foregroundStyle(selected ? Palette.accentInk : Palette.text2)
						.padding(.horizontal, Space.s4)
						.padding(.vertical, Space.s2)
						.background {
							if selected {
								Capsule()
									.fill(Palette.accent)
									.matchedGeometryEffect(id: "thumb", in: thumb)
							}
						}
						.contentShape(.capsule)
				}
				.buttonStyle(.plain)
				.accessibilityAddTraits(selected ? .isSelected : [])
			}
		}
		.padding(3)
		.background(Palette.sunken, in: .capsule)
		.overlay(Capsule().strokeBorder(Palette.line))
		.sensoryFeedback(.selection, trigger: selection)
	}
}

/// A section title in the display face with an optional trailing accessory.
public struct SectionHeader<Accessory: View>: View {

	let title: LocalizedStringKey

	let accessory: Accessory

	public init(_ title: LocalizedStringKey, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
		self.title = title
		self.accessory = accessory()
	}

	public var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text(title)
				.font(.eraseTitle3)
				.foregroundStyle(Palette.text)
			Spacer()
			accessory
		}
		.padding(.top, Space.s2)
	}
}

/// Loading, failure and empty states shared by every data screen.
public struct LoadState<Value, Content: View>: View {

	let phase: Phase<Value>

	let retry: () async -> Void

	let content: (Value) -> Content

	public init(_ phase: Phase<Value>, retry: @escaping () async -> Void, @ViewBuilder content: @escaping (Value) -> Content) {
		self.phase = phase
		self.retry = retry
		self.content = content
	}

	public var body: some View {
		switch phase {
		case .loading:
			ProgressView()
				.controlSize(.large)
				.frame(maxWidth: .infinity, minHeight: 240)
		case .failed(let error):
			ContentUnavailableView {
				Label(error.isNotFound ? "Not found" : "Couldn't load", systemImage: error.isNotFound ? "questionmark.circle" : "wifi.exclamationmark")
			} description: {
				Text(verbatim: error.message)
			} actions: {
				if !error.isNotFound {
					Button("Try again") { Task { await retry() } }
						.buttonStyle(.bordered)
				}
			}
			.frame(minHeight: 240)
		case .loaded(let value):
			content(value)
		}
	}
}

public enum Phase<Value> {
	case loading
	case failed(APIError)
	case loaded(Value)

	public var value: Value? {
		if case .loaded(let value) = self {
			return value
		}
		return nil
	}
}

extension Phase: Sendable where Value: Sendable {}
