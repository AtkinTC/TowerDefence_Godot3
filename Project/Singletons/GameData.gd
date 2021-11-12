extends Node

enum PLACEMENT_TYPE {RANGED, MELEE, BOTH}

const DAMAGE: String = "damage"
const ROF: String = "rof"
const RANGE: String = "range"
const PROJTYPE: String = "projType"
const MAX_CHAINS: String = "max_chains"
const PLACEMENT: String = "placement"


const tower_data = {
	"GunT1": {
		DAMAGE: 10,
		ROF: 1.0,
		RANGE: 250,
		PROJTYPE: "Instant"},
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
		MAX_CHAINS: 3
		},
	"BlockerTower": {
		DAMAGE: 20,
		ROF: 1,
		RANGE: 50,
		PROJTYPE: "Area",
		PLACEMENT: PLACEMENT_TYPE.MELEE
		}
	}
	
const enemy_data = {
	"BlueTank": {
		"damage": 1,
		"speed": 150,
		"health": 50}
	}

const wave_data = {
	"TEST":  ["Enemy, 2, 1.0, 5.0", "Enemy, 6, 0.5, 5.0", "Enemy, 10, 0.5, 10.0"],
	"STREAM" : ["Enemy, 100000, 0.5, 1"]
}
