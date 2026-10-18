import Foundation

/// Minecraft item textures for the end-of-match inventory, ported from the site's `lib/items.ts`.
/// The game names items by its parser alias (`strong_healing_splash_potion`, `steak`); each alias
/// maps to a vanilla texture in the app's `Items` asset folder.
public enum ItemTexture {

	static let textures: [String: String] = [
		"diamond_sword": "diamond_sword",
		"iron_sword": "iron_sword",
		"stone_sword": "stone_sword",
		"golden_sword": "gold_sword",
		"wooden_sword": "wood_sword",
		"netherite_sword": "netherite_sword",
		"diamond_axe": "diamond_axe",
		"wooden_axe": "wood_axe",
		"netherite_axe": "netherite_axe",
		"iron_pickaxe": "iron_pickaxe",
		"wooden_pickaxe": "wood_pickaxe",
		"diamond_helmet": "diamond_helmet",
		"diamond_chestplate": "diamond_chestplate",
		"diamond_leggings": "diamond_leggings",
		"diamond_boots": "diamond_boots",
		"netherite_helmet": "netherite_helmet",
		"netherite_chestplate": "netherite_chestplate",
		"netherite_leggings": "netherite_leggings",
		"netherite_boots": "netherite_boots",
		"leather_tunic": "leather_chestplate",
		"chainmail_chestplate": "chainmail_chestplate",
		"ender_pearl": "ender_pearl",
		"golden_apple": "apple_golden",
		"enchanted_golden_apple": "apple_golden",
		"golden_carrot": "carrot_golden",
		"steak": "beef_cooked",
		"cooked_beef": "beef_cooked",
		"bow": "bow_standby",
		"arrow": "arrow",
		"stick": "stick",
		"shears": "shears",
		"fishing_rod": "fishing_rod_uncast",
		"fire_charge": "fireball",
		"blaze_rod": "blaze_rod",
		"experience_bottle": "experience_bottle",
		"mace": "mace",
		"wind_charge": "wind_charge",
		"totem": "totem",
		"totem_of_undying": "totem",
		"nautilus_shell": "nautilus",
		"snowball": "snowball",
		"egg": "egg",
		"sandstone": "sandstone_normal",
		"white_wool": "wool_colored_white",
		"wool": "wool_colored_white",
		"end_stone": "end_stone",
		"tnt": "tnt_side",
		"ladder": "ladder",
		"cobweb": "web",
		"web": "web",
		"oak_planks": "planks_oak",
		"cobblestone": "cobblestone",
	]

	/// Potion bottles are drawn by their effect; unknown effects get the plain bottle.
	static let potionEffects: [(String, String)] = [
		("heal", "heal"),
		("regeneration", "regeneration"),
		("swiftness", "moveSpeed"),
		("speed", "moveSpeed"),
		("strength", "damageBoost"),
		("fire_resistance", "fireResistance"),
	]

	/// Asset name (`Items/<texture>`) for an alias, nil when the app has no texture for it.
	public static func asset(for alias: String) -> String? {
		let name = alias.hasPrefix("minecraft:") ? String(alias.dropFirst("minecraft:".count)) : alias
		if let file = textures[name] {
			return "Items/\(file)"
		}
		guard name.contains("potion") else {
			return nil
		}
		let effect = potionEffects.first { name.contains($0.0) }?.1
		if name.contains("splash") {
			return effect.map { "Items/potion_bottle_splash_\($0)" } ?? "Items/potion_bottle_splash"
		}
		return effect.map { "Items/potion_bottle_\($0)" } ?? "Items/potion_bottle_drinkable"
	}

	/// "strong_healing_splash_potion" reads as "Strong healing splash potion".
	public static func name(for alias: String) -> String {
		let name = alias.hasPrefix("minecraft:") ? String(alias.dropFirst("minecraft:".count)) : alias
		let words = name.replacingOccurrences(of: "_", with: " ")
		return words.prefix(1).uppercased() + words.dropFirst()
	}
}
