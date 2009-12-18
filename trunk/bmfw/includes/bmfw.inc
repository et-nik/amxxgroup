#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#pragma reqlib bmfw

#define BM_BASEFILE	"models/blockmaker/bm_block_"

enum { point_hull, human_hull, large_hull, head_hull }
enum Props { eConnected, eAlive, eTt, eCt, eVisible, eSemiclip }
enum Handlers { hSpawn, hTouch, hAddToFullPack, hPlayerPreThink, hPlayerPostThink, hUpdateClientData, hThink }
enum Blocks { bPlugin, bName[32], bHandlers[Handlers], bModel[128], Float:bSize[3], Float:bSizeSmall[3], Float:bSizeLarge[3] }

// Sets player property
native _set_prop(id, Props:prop)

// Deletes player property
native _del_prop(id, Props:prop)

// Gets player property
native _get_prop(id, Props:prop)

// Register block in framework
native _reg_block(const name[], const model[], const Float:size[3])

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
