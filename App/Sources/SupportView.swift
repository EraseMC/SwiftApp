import EraseUI
import SwiftUI

/// Answers first, then a person: the site's FAQ and the Discord and Telegram support channels.
struct SupportView: View {

	/// The FAQ entries generated from the site's `faqs` list.
	private var questions: [(String, String)] {
		(0..<20).compactMap { index in
			let question = Copy.text("faq.\(index).q")
			guard question != "faq.\(index).q" else { return nil }
			return (question, Copy.text("faq.\(index).a"))
		}
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: Space.s4) {
				Text(Copy.text("support.body"))
					.font(.eraseCallout)
					.foregroundStyle(Palette.text2)

				SectionHeader(LocalizedStringKey(Copy.text("support.faq")))
				VStack(spacing: 0) {
					ForEach(questions, id: \.0) { question, answer in
						DisclosureGroup {
							Text(verbatim: answer)
								.font(.eraseCallout)
								.foregroundStyle(Palette.text2)
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.top, Space.s2)
						} label: {
							Text(verbatim: question)
								.font(.eraseHeadline)
								.foregroundStyle(Palette.text)
						}
						.padding(Space.s4)
					}
				}
				.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
				.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))

				channel(
					icon: "ticket.fill",
					title: "support.discordTicketTitle",
					body: "support.discordTicketBody",
					action: "support.openDiscord",
					url: Links.discord
				)
				channel(
					icon: "paperplane.fill",
					title: "support.telegramTitle",
					body: "support.telegramBody",
					action: "support.openTelegram",
					url: Links.telegramSupport
				)
			}
			.padding(Space.s4)
			.readableWidth()
		}
		.background(Palette.background)
		.navigationTitle(Copy.text("support.title"))
	}

	private func channel(icon: String, title: String, body: String, action: String, url: URL) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Image(systemName: icon)
				.font(.title3)
				.foregroundStyle(Palette.accentText)
			Text(Copy.text(title)).font(.eraseTitle3)
			Text(Copy.text(body)).font(.eraseCallout).foregroundStyle(Palette.text2)
			Link(destination: url) {
				Text(Copy.text(action)).frame(maxWidth: .infinity)
			}
			.buttonStyle(.erasePrimary)
		}
		.panel(padding: Space.s5)
	}
}
