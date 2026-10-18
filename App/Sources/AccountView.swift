import EraseKit
import EraseUI
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
	case system
	case dark
	case light

	var id: Self { self }

	var colorScheme: ColorScheme? {
		switch self {
		case .system: nil
		case .dark: .dark
		case .light: .light
		}
	}

	var title: LocalizedStringKey {
		switch self {
		case .system: "System"
		case .dark: "Dark"
		case .light: "Light"
		}
	}
}

struct AccountView: View {

	@AppStorage("theme") private var theme: AppTheme = .system

	@Environment(\.openURL) private var openURL

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading, spacing: Space.s3) {
					Text(Copy.text("auth.microsoftTitle"))
						.font(.eraseTitle3)
					Text(Copy.text("auth.microsoftBody"))
						.font(.eraseFootnote)
						.foregroundStyle(Palette.text2)
					Button {} label: {
						Text(Copy.text("auth.continueMicrosoft"))
					}
					.buttonStyle(.erasePrimary)
					.disabled(true)
					Text("Sign-in in the app is coming soon.")
						.font(.eraseCaption)
						.foregroundStyle(Palette.text3)
				}
				.padding(.vertical, Space.s2)
			}

			Section("Appearance") {
				Picker("Theme", selection: $theme) {
					ForEach(AppTheme.allCases) { theme in
						Text(theme.title).tag(theme)
					}
				}
				.pickerStyle(.segmented)

				Button {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						openURL(url)
					}
				} label: {
					LabeledContent("Language") {
						Text(Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "en")?.capitalized ?? "")
					}
				}
				.foregroundStyle(Palette.text)
			}

			Section("Erase") {
				Link(destination: Links.site) {
					Label("erasemc.com", systemImage: "globe")
				}
				Link(destination: Links.site.appending(path: "store")) {
					Label(Copy.text("nav.store"), systemImage: "bag")
				}
				Link(destination: Links.discord) {
					Label("Discord", systemImage: "bubble.left.and.bubble.right")
				}
				Link(destination: Links.telegramSupport) {
					Label(Copy.text("nav.support"), systemImage: "lifepreserver")
				}
			}

			Section {
				LabeledContent("Version", value: version)
			}
		}
		.scrollContentBackground(.hidden)
		.background(Palette.background)
		.font(.eraseCallout)
		.navigationTitle("Account")
	}

	private var version: String {
		let info = Bundle.main.infoDictionary
		let short = info?["CFBundleShortVersionString"] as? String ?? "?"
		let build = info?["CFBundleVersion"] as? String ?? "?"
		return "\(short) (\(build))"
	}
}
