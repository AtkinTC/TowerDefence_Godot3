extends Node

#################
### RESOURCES ###
#################
enum RESOURCE_TYPE {GOLD, MANA}
const GOLD: String = "gold"
const MANA: String = "mana"
const RESOURCE_NAMES = {RESOURCE_TYPE.GOLD: GOLD, RESOURCE_TYPE.MANA: MANA}

##############
### TOWERS ###
##############
enum PLACEMENT_TYPE {RANGED, MELEE, BOTH}

const DAMAGE: String = "damage"
const ROF: String = "rof"
const RANGE: String = "range"
const PROJTYPE: String = "projType"
const MAX_CHAINS: String = "max_chains"
const PLACEMENT: String = "placement"
const BLOCKER: String = "blocker"
const BLOCKER_NAV: String = "blocker_nav"
const COST: String = "cost"

const tower_data = {
	"GunT1": {
		DAMAGE: 10,
		ROF: 1.0,
		RANGE: 250,
		PROJTYPE: "Instant",
		COST: {GOLD: 1}},
	"MissileT1": {
		DAMAGE: 30,
		ROF: 1.0/3.0,
		RANGE: 400,
		PROJTYPE: "Missile"},
	"ArcTower": {
		DAMAGE: 20,
		ROF: 0.5,
		RANGE: 200,
		PROJTYPE: "Beam",
		MAX_CHAINS: 3,
		COST: {GOLD: 5, MANA: 1}
		},
	"BlockerTower": {
		DAMAGE: 20,
		ROF: 1,
		RANGE: 50,
		PROJTYPE: "Area",
		PLACEMENT: PLACEMENT_TYPE.MELEE,
		BLOCKER: true,
		BLOCKER_NAV: 10,
		COST: {GOLD: 1}
		},
	"PulseTower": {
		DAMAGE: 10,
		ROF: 0.5,
		RANGE: 100,
		PROJTYPE: "Area",
		COST: {MANA: 2}
		},
	}

###############
### ENEMIES ###
###############
const PLAYER_DAMAGE: String = "player_damage"
const MOVE_SPEED: String = "move_speed"
const HEALTH: String = "health"
const REWARD: String = "reward"

const ENEMY_DATA = {
	"BasicEnemy":  {
		PLAYER_DAMAGE: 1,
		MOVE_SPEED: 100,
		HEALTH: 10,
		REWARD: {GOLD: 1}
		},
	"BlueTank": {
		PLAYER_DAMAGE: 1,
		MOVE_SPEED: 150,
		HEALTH: 50,
		REWARD: {GOLD: 1}
		}
	}

const wave_data = {
	"TEST":  ["BasicEnemy, 2, 1.0, 5.0", "BasicEnemy, 6, 0.5, 5.0", "BasicEnemy, 10, 0.5, 10.0"],
	"STREAM" : ["BasicEnemy, 100000, 1, 1"]
}
