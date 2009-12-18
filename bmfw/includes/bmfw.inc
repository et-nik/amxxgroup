#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#pragma reqlib bmfw

#define BM_BASEFILE	"models/blockmaker/bm_block_"
#define BM_BASECLASS	"func_breakable"
#define BM_CLASSNAME	"func_bmfw"


enum { touch_all, touch_both, touch_down, touch_up }
enum Props { eConnected, eAlive }
enum Handlers { hSpawn, hTouch, hAddToFullPack, hPlayerPreThink, hPlayerPostThink, hUpdateClientData, hThink }
enum Blocks { bPlugin, bName[32], bModel[128], bCooldown, Float:bSize[3], Float:bSizeSmall[3], Float:bSizeLarge[3], bHandlers[Handlers] }

// Register block in framework
native _reg_block(const name[], const model[], const cooldown, const Float:size[3], const Float:sizesmall[3], const Float:sizelarge[3])

// Precache model in default directory
stock bm_precache_model(const fmt[], any:...)
{
	new filename[128]
	vformat(filename, charsmax(filename), fmt, 2)
	return precache_model(filename)
}

// Sum 2 vectors
stock bm_vector_sum(Float:vecDst[], const Float:vecSrc[])
{
	vecDst[0] += vecSrc[0];
	vecDst[1] += vecSrc[1];
	vecDst[2] += vecSrc[2];
}

// Copy one vector to another
stock bm_vector_copy(Float:vecDst[], const Float:vecSrc[])
{
	vecDst[0] = vecSrc[0];
	vecDst[1] = vecSrc[1];
	vecDst[2] = vecSrc[2];
}
