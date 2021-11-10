extends Node

const DAMAGE: String = "damage"
const ROF: String = "rof"
const RANGE: String = "range"
const PROJTYPE: String = "projType"

enum PROJTYPES_ENUM {HITSCAN, MISSILE}

const tower_data = {
	"GunT1": {
		"damage": 10,
		"rof": 1.0,
		"range": 350,
		"projType": "Instant"},
	"MissileT1": {
		"damage": 30,
		"rof": 1.0/3.0,
		"range": 550,
		"projType": "Missile"}
	}
	
const enemy_data = {
	"BlueTank": {
		"damage": 1,
		"speed": 150,
		"health": 50}
	}

const wave_data = {
	"TEST":  ["Enemy, 2, 1.0, 5.0", "Enemy, 6, 0.5, 5.0", "Enemy, 10, 0.5, 10.0"],
	"STREAM" : ["Enemy, 100000, 0.001, 1"]
}
