class_name GameEnums
extends RefCounted

enum Team {
	BLUE = 0,
	RED = 1,
}

enum WeaponId {
	PISTOL = 0,
	SMG = 1,
	SHOTGUN = 2,
}

enum PickupType {
	HEALTH = 0,
	GRENADE = 1,
	WEAPON = 2,
	AMMO = 3,
	DAMAGE_POWERUP = 4,
	SPEED_POWERUP = 5,
}

enum HitFxType {
	ENVIRONMENT = 0,
	PLAYER = 1,
}

enum GameMode {
	TEAM_DEATHMATCH = 0,
	KING_OF_THE_HILL = 1,
	CAPTURE_THE_FLAG = 2,
}

enum PlatformState {
	READY = 0,
	BREAKING = 1,
	BROKEN = 2,
}
