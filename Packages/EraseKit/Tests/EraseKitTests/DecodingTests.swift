import Foundation
import Testing
@testable import EraseKit

@Suite struct DecodingTests {

	@Test func networkStatusWithNanoseconds() throws {
		let json = """
			{"online":16,"maxPlayers":17,"version":"1.26.50","address":"erasemc.com","port":19132,"season":1,"updatedAt":"2026-10-18T14:48:30.537594138Z"}
			"""
		let status = try JSONDecoder.imprint.decode(NetworkStatus.self, from: Data(json.utf8))

		#expect(status.online == 16)
		#expect(status.isReachable)
		#expect(abs(status.updatedAt.timeIntervalSince1970 - 1_792_334_910.537594) < 0.001)
	}

	@Test func unreachableServerKeepsNilCounts() throws {
		let json = """
			{"online":null,"maxPlayers":null,"version":null,"address":"erasemc.com","port":19132,"season":1,"updatedAt":"2026-10-18T14:48:30Z"}
			"""
		let status = try JSONDecoder.imprint.decode(NetworkStatus.self, from: Data(json.utf8))

		#expect(status.online == nil)
		#expect(!status.isReachable)
	}

	@Test(arguments: ["2026-10-18T14:48:30Z", "2026-10-18T14:48:30.5Z", "2026-10-18T14:48:30.123456789+03:00"])
	func instantsParse(_ text: String) {
		#expect(ImprintDate.parse(text) != nil)
	}
}

@Suite struct ItemTextureTests {

	@Test func aliasesResolve() {
		#expect(ItemTexture.asset(for: "steak") == "Items/beef_cooked")
		#expect(ItemTexture.asset(for: "minecraft:ender_pearl") == "Items/ender_pearl")
		#expect(ItemTexture.asset(for: "strong_healing_splash_potion") == "Items/potion_bottle_splash_heal")
		#expect(ItemTexture.asset(for: "potion") == "Items/potion_bottle_drinkable")
		#expect(ItemTexture.asset(for: "bedrock") == nil)
		#expect(ItemTexture.name(for: "strong_healing_splash_potion") == "Strong healing splash potion")
	}
}
