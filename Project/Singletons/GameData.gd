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
	"BasicEnemy2":  {
		PLAYER_DAMAGE: 2,
		MOVE_SPEED: 150,
		HEALTH: 20,
		REWARD: {GOLD: 3}
		},
	"BlueTank": {
		PLAYER_DAMAGE: 1,
		MOVE_SPEED: 150,
		HEALTH: 50,
		REWARD: {GOLD: 1}
		}
	}

############
### WAVE ###
############
const ENEMY_TYPE: String = "enemy_type"
const ENEMY_COUNT: String = "enemy_count"
const POST_SPAWN_DELAY: String = "post_spawn_delay"
const POST_WAVE_DELAY: String = "post_wave_delay"
const SPAWN_POINT_INDEX: String = "spawn_point_index"
const TARGET_POINT_INDEX: String = "target_point_index"
const SPAWN_GROUPS: String = "spawn_groups"

const WAVE_DATA = {
	"TestWave1": [
		{
		POST_WAVE_DELAY: 5,
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 2,
			POST_SPAWN_DELAY: 1
			}]
		},
		{	
		POST_WAVE_DELAY: 5,
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy2",
			ENEMY_COUNT: 5,
			POST_SPAWN_DELAY: 1
			}]
		},
		{	
		POST_WAVE_DELAY: 5,
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 10,
			POST_SPAWN_DELAY: 0.5
			}]
		},
	],
	"STREAM": [
		{
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 10000,
			POST_SPAWN_DELAY: 1
			}]
		}
	]
}
