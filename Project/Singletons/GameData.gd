extends Node

##################
### STRUCTURES ###
##################

const SPAWN_DELAY: String = "spawn_delay"

const STRUCTURE_DATA = {}

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
		COST: {GOLD: 2}},
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
		COST: {GOLD: 8}
		},
	"BlockerTower": {
		DAMAGE: 20,
		ROF: 0.5,
		RANGE: 64,
		PROJTYPE: "Area",
		PLACEMENT: PLACEMENT_TYPE.MELEE,
		BLOCKER: true,
		BLOCKER_NAV: 10,
		COST: {GOLD: 3}
		},
	"PulseTower": {
		DAMAGE: 10,
		ROF: 0.5,
		RANGE: 100,
		PROJTYPE: "Area",
		COST: {GOLD: 5}
		},
	}

###############
### UNITS ###
###############
const ATTACK_DAMAGE: String = "attack_damage"
const ATTACK_RANGE: String = "attack_range"
const MOVE_DELAY: String = "move_delay"
const ATTACK_DELAY: String = "attack_delay"
const HEALTH: String = "health"
const REWARD: String = "reward"

const UNIT_DATA = {
	"BasicUnit":  {
		ATTACK_DAMAGE: 1,
		MOVE_DELAY: 1,
		ATTACK_DELAY: 1,
		HEALTH: 2,
		REWARD: {GOLD: 1}
		},
	"BasicUnit2":  {
		ATTACK_DAMAGE: 2,
		MOVE_DELAY: 1,
		ATTACK_DELAY: 1,
		HEALTH: 4,
		REWARD: {GOLD: 3}
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
			POST_SPAWN_DELAY: 1,
			}]
		},
		{	
		POST_WAVE_DELAY: 5,
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy2",
			ENEMY_COUNT: 4,
			POST_SPAWN_DELAY: 1
			}]
		},
		{	
		POST_WAVE_DELAY: 5,
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 10,
			POST_SPAWN_DELAY: 0.5
			},
			{
			ENEMY_TYPE: "BasicEnemy2",
			ENEMY_COUNT: 5,
			POST_SPAWN_DELAY: 1,
			}]
		},
	],
	"TestWaveStream1": [
		{
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 10000,
			POST_SPAWN_DELAY: 1
			}]
		}
	],
	"TestWaveStream2": [
		{
		SPAWN_GROUPS: [{
			ENEMY_TYPE: "BasicEnemy",
			ENEMY_COUNT: 10000,
			POST_SPAWN_DELAY: 1,
			SPAWN_POINT_INDEX: 0,
			TARGET_POINT_INDEX: 1
			},
			{
			ENEMY_TYPE: "BasicEnemy2",
			ENEMY_COUNT: 10000,
			POST_SPAWN_DELAY: 1,
			SPAWN_POINT_INDEX: 1,
			TARGET_POINT_INDEX: 0
			}]
		}
	]
}
