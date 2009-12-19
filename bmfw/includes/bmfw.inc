#include <amxmodx>
#include <engine>
#include <hamsandwich>

#pragma reqlib bmfw

#define BM_BASEFILE	"models/blockmaker/bm_block_"
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
