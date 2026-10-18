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

	@Environment(AuthModel.self) private var auth

	@State private var showsSettings = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: Space.s4) {
				if auth.identity == nil {
					ProgressView(Copy.text("auth.loading"))
						.frame(maxWidth: .infinity, minHeight: 200)
				} else if !auth.isSignedIn {
					SignInCard()
				} else if let player = auth.playerName {
					CabinetView(player: player)
				} else {
					LinkCard()
				}
			}
			.padding(Space.s4)
		}
		.background(Palette.background)
		.navigationTitle(Copy.text("account.title"))
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					showsSettings = true
				} label: {
					Label("Settings", systemImage: "gearshape")
				}
			}
		}
		.sheet(isPresented: $showsSettings) {
			NavigationStack { SettingsView() }
		}
		.refreshable { await auth.refresh() }
		.task { await auth.refresh() }
	}
}

private struct SignInCard: View {

	@Environment(AuthModel.self) private var auth

	@Environment(\.webAuthenticationSession) private var webAuthenticationSession

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Image(systemName: "gamecontroller.fill")
				.font(.system(size: 34))
				.foregroundStyle(Palette.accentText)
			Text(Copy.text("auth.microsoftTitle"))
				.font(.eraseTitle2)
			Text(Copy.text("auth.microsoftBody"))
				.font(.eraseCallout)
				.foregroundStyle(Palette.text2)

			if auth.identity?.configured == false {
				Text(Copy.text("auth.notConfigured"))
					.font(.eraseFootnote)
					.foregroundStyle(Palette.warn)
			} else {
				Button {
					Task { await auth.signIn(with: webAuthenticationSession) }
				} label: {
					HStack {
						if auth.busy { ProgressView().tint(Palette.accentInk) }
						Text(Copy.text("auth.continueMicrosoft"))
					}
				}
				.buttonStyle(.erasePrimary)
				.disabled(auth.busy)
			}

			if let failure = auth.failure {
				Text(Copy.text(failure.key))
					.font(.eraseFootnote)
					.foregroundStyle(Palette.loss)
			}
		}
		.panel(padding: Space.s5)
	}
}

/// Signed in with Xbox, but no player joined the server with this account yet.
private struct LinkCard: View {

	@Environment(AuthModel.self) private var auth

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("auth.unlinkedTitle")).font(.eraseTitle2)
			Text(Copy.text("auth.unlinkedBody"))
				.font(.eraseCallout)
				.foregroundStyle(Palette.text2)

			if let code = auth.linkCode {
				Text(Copy.text("auth.linkCommand", ["code": code.code]))
					.font(.eraseCallout)
				HStack {
					Text(verbatim: "/link \(code.code)")
						.font(Typeface.mono(22, .bold))
						.foregroundStyle(Palette.accentText)
						.textSelection(.enabled)
					Spacer()
					Button {
						UIPasteboard.general.string = "/link \(code.code)"
					} label: {
						Image(systemName: "doc.on.doc")
					}
				}
				.padding(Space.s3)
				.background(Palette.sunken, in: .rect(cornerRadius: Radius.sm))
				Text(Copy.text("auth.codeExpires"))
					.font(.eraseFootnote)
					.foregroundStyle(Palette.text3)
			}

			Button(Copy.text("auth.refreshCode")) {
				Task { await auth.requestLinkCode() }
			}
			.buttonStyle(.erasePrimary)

			Button(Copy.text("auth.checkAgain")) {
				Task { await auth.refresh() }
			}
			.frame(maxWidth: .infinity)

			if auth.failure == .linkFailed {
				Text(Copy.text("auth.linkFailed")).font(.eraseFootnote).foregroundStyle(Palette.loss)
			}

			Button(Copy.text("auth.signOut"), role: .destructive) {
				Task { await auth.signOut() }
			}
			.frame(maxWidth: .infinity)
		}
		.panel(padding: Space.s5)
		// Picks up the link as soon as `/link` is run in the game.
		.task(id: auth.linkCode?.code) {
			guard auth.linkCode != nil else { return }
			while !Task.isCancelled, auth.playerName == nil {
				try? await Task.sleep(for: .seconds(4))
				await auth.refresh()
			}
		}
	}
}

extension AuthModel.Failure {
	var key: String {
		switch self {
		case .cancelled: "auth.cancelled"
		case .xbox: "auth.xboxMissing"
		case .failed: "auth.loginFailed"
		case .linkFailed: "auth.linkFailed"
		}
	}
}

struct SettingsView: View {

	@AppStorage("theme") private var theme: AppTheme = .system

	@Environment(AuthModel.self) private var auth

	@Environment(\.openURL) private var openURL

	@Environment(\.dismiss) private var dismiss

	var body: some View {
		List {
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
				Link(destination: Links.discord) {
					Label("Discord", systemImage: "bubble.left.and.bubble.right")
				}
				Link(destination: Links.telegramSupport) {
					Label(Copy.text("nav.support"), systemImage: "lifepreserver")
				}
			}

			if auth.isSignedIn {
				Section {
					Button(Copy.text("auth.signOut"), role: .destructive) {
						Task {
							await auth.signOut()
							dismiss()
						}
					}
				}
			}

			Section {
				LabeledContent("Version", value: version)
			}
		}
		.font(.eraseCallout)
		.navigationTitle("Settings")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Done") { dismiss() }
			}
		}
	}

	private var version: String {
		let info = Bundle.main.infoDictionary
		let short = info?["CFBundleShortVersionString"] as? String ?? "?"
		let build = info?["CFBundleVersion"] as? String ?? "?"
		return "\(short) (\(build))"
	}
}
