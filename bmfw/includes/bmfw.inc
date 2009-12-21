#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>

#pragma reqlib bmfw

#define BM_BASEFILE	"models/bmfw/bm_block_"
#define BM_BASECLASS	"func_breakable"
#define BM_CLASSNAME	"func_bmfw"

#define BM_MODELLARGE	"_large"
#define BM_MODELSMALL	"_small"

#define TOUCH_NONE	1<<0
#define TOUCH_ALL	1<<1
#define TOUCH_BOTH	1<<2
#define TOUCH_HEAD	1<<3
#define TOUCH_FOOT	1<<4
#define TOUCH_OTHER	1<<5

enum Handlers { hSpawn, hTouch, hThink, hAddToFullPack, hPlayerPreThink, hPlayerPostThink, hUpdateClientData }
enum Blocks { bPlugin, bName[32], bModel[128], bCooldown, bTouch, Float:bSize[3], Float:bSizeSmall[3], Float:bSizeLarge[3], bHandlers[Handlers] }

// Set handler
native _set_handler(const id, const blockid, const value, const Handlers:handler)

// Register block in framework
native _reg_block(const name[], const ver[], const model[], const touch, const Float:cdown, const Float:size[], const Float:sizesmall[], const Float:sizelarge[])

// Save blocks to file
native _bm_save(const id)

// Cleanup map and load maps from file
native _bm_load()

// Cleanup map
native _bm_cleanup()

// Rotate block by aiming
native _bm_rotate_block(const ent, const opt)

// Create block by aiming
native _bm_create_block(const bType, const Float:vorigin[3], const size[2])

// Get the block list
native _bm_list_blocks()

// Precache model in default directory
stock bm_precache_model(const fmt[], any:...)
{
	new filename[128]
	vformat(filename, charsmax(filename), fmt, 2)
	return precache_model(filename)
}

// Multiply vector
stock bm_vector_mul(Float:vec[], const Float:ammount)
{
	vec[0] *= ammount
	vec[1] *= ammount
	vec[2] *= ammount
}

// Substract 2 vectors
stock bm_vector_substract(Float:vecDst[], const Float:vecSrc[])
{
	vecDst[0] -= vecSrc[0]
	vecDst[1] -= vecSrc[1]
	vecDst[2] -= vecSrc[2]
}

// Sum 2 vectors
stock bm_vector_sum(Float:vecDst[], const Float:vecSrc[])
{
	vecDst[0] += vecSrc[0]
	vecDst[1] += vecSrc[1]
	vecDst[2] += vecSrc[2]
}

// Copy one vector to another
stock bm_vector_copy(Float:vecDst[], const Float:vecSrc[])
{
	vecDst[0] = vecSrc[0];
	vecDst[1] = vecSrc[1];
	vecDst[2] = vecSrc[2];
}

stock bm_vector_compare(const Float:vecA[], const Float:vecB[])
{
	if((vecA[0] == vecB[0]) && (vecA[1] == vecB[1]) && (vecA[2] == vecB[2]))
		return true

	return false
}

