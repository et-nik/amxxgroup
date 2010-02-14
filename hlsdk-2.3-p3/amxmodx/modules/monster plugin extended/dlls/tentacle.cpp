/***
*
*	Copyright (c) 1996-2002, Valve LLC. All rights reserved.
*	
*	This product contains software technology licensed from Id 
*	Software, Inc. ("Id Technology").  Id Technology (c) 1996 Id Software, Inc. 
*	All Rights Reserved.
*
*   This source code contains proprietary and confidential information of
*   Valve LLC and its suppliers.  Access to this code is restricted to
*   persons who have executed a written SDK license with Valve.  Any access,
*   use or distribution of this code by or to any unlicensed person is illegal.
*
****/
#if !defined( OEM_BUILD ) && !defined( HLDEMO_BUILD )

/*

	h_tentacle.cpp - silo of death tentacle monster (half life)

*/

#include	"extdll.h"
#include	"util.h"
#include	"cmbase.h"
#include    "cmbasemonster.h"
#include	"monsters.h"
#include	"weapons.h"



#define ACT_T_IDLE		1010
#define ACT_T_TAP			1020
#define ACT_T_STRIKE		1030
#define ACT_T_REARIDLE	1040






// stike sounds
#define TE_NONE -1
#define TE_SILO 0
#define TE_DIRT 1
#define TE_WATER 2

const char *CMTentacle::pHitSilo[] = 
{
	"tentacle/te_strike1.wav",
	"tentacle/te_strike2.wav",
};

const char *CMTentacle::pHitDirt[] = 
{
	"player/pl_dirt1.wav",
	"player/pl_dirt2.wav",
	"player/pl_dirt3.wav",
	"player/pl_dirt4.wav",
};

const char *CMTentacle::pHitWater[] = 
{
	"player/pl_slosh1.wav",
	"player/pl_slosh2.wav",
	"player/pl_slosh3.wav",
	"player/pl_slosh4.wav",
};





// animation sequence aliases 
typedef enum
{
	TENTACLE_ANIM_Pit_Idle,

	TENTACLE_ANIM_rise_to_Temp1,
	TENTACLE_ANIM_Temp1_to_Floor,
	TENTACLE_ANIM_Floor_Idle,
	TENTACLE_ANIM_Floor_Fidget_Pissed,
	TENTACLE_ANIM_Floor_Fidget_SmallRise,
	TENTACLE_ANIM_Floor_Fidget_Wave,
	TENTACLE_ANIM_Floor_Strike,
	TENTACLE_ANIM_Floor_Tap,
	TENTACLE_ANIM_Floor_Rotate,
	TENTACLE_ANIM_Floor_Rear,
	TENTACLE_ANIM_Floor_Rear_Idle,
	TENTACLE_ANIM_Floor_to_Lev1,

	TENTACLE_ANIM_Lev1_Idle,
	TENTACLE_ANIM_Lev1_Fidget_Claw,
	TENTACLE_ANIM_Lev1_Fidget_Shake,
	TENTACLE_ANIM_Lev1_Fidget_Snap,
	TENTACLE_ANIM_Lev1_Strike,
	TENTACLE_ANIM_Lev1_Tap,
	TENTACLE_ANIM_Lev1_Rotate,
	TENTACLE_ANIM_Lev1_Rear,
	TENTACLE_ANIM_Lev1_Rear_Idle,
	TENTACLE_ANIM_Lev1_to_Lev2,

	TENTACLE_ANIM_Lev2_Idle,
	TENTACLE_ANIM_Lev2_Fidget_Shake,
	TENTACLE_ANIM_Lev2_Fidget_Swing,
	TENTACLE_ANIM_Lev2_Fidget_Tut,
	TENTACLE_ANIM_Lev2_Strike,
	TENTACLE_ANIM_Lev2_Tap,
	TENTACLE_ANIM_Lev2_Rotate,
	TENTACLE_ANIM_Lev2_Rear,
	TENTACLE_ANIM_Lev2_Rear_Idle,
	TENTACLE_ANIM_Lev2_to_Lev3,

	TENTACLE_ANIM_Lev3_Idle,
	TENTACLE_ANIM_Lev3_Fidget_Shake,
	TENTACLE_ANIM_Lev3_Fidget_Side,
	TENTACLE_ANIM_Lev3_Fidget_Swipe,
	TENTACLE_ANIM_Lev3_Strike,
	TENTACLE_ANIM_Lev3_Tap,
	TENTACLE_ANIM_Lev3_Rotate,
	TENTACLE_ANIM_Lev3_Rear,
	TENTACLE_ANIM_Lev3_Rear_Idle,

	TENTACLE_ANIM_Lev1_Door_reach,

	TENTACLE_ANIM_Lev3_to_Engine,
	TENTACLE_ANIM_Engine_Idle,
	TENTACLE_ANIM_Engine_Sway,
	TENTACLE_ANIM_Engine_Swat,
	TENTACLE_ANIM_Engine_Bob,
	TENTACLE_ANIM_Engine_Death1,
	TENTACLE_ANIM_Engine_Death2,
	TENTACLE_ANIM_Engine_Death3,

	TENTACLE_ANIM_none
} TENTACLE_ANIM;





//=========================================================
// Classify - indicates this monster's place in the 
// relationship table.
//=========================================================
int	CMTentacle :: Classify ( void )
{
	return	CLASS_ALIEN_MONSTER;
}

//
// Tentacle Spawn
//
void CMTentacle :: Spawn( )
{
	Precache( );

	pev->solid			= SOLID_BBOX;
	pev->movetype		= MOVETYPE_FLY;
	pev->effects		= 0;
	pev->health			= gSkillData.TentacleHealth;
	pev->sequence		= 0;

	SET_MODEL(ENT(pev), "models/tentacle2.mdl");
	UTIL_SetSize( pev, Vector( -32, -32, 0 ), Vector( 32, 32, 64 ) );

	pev->takedamage		= DAMAGE_AIM;
	pev->flags			|= FL_MONSTER;
	
	m_bloodColor		= BLOOD_COLOR_GREEN;

	SetThink( Start );
	SetTouch( HitTouch );
	SetUse( CommandUse );

	pev->nextthink = gpGlobals->time + 0.2;

	ResetSequenceInfo( );
	m_iDir = 1;

	pev->yaw_speed = 18;
	m_flInitialYaw = pev->angles.y;
	pev->ideal_yaw = m_flInitialYaw;


	m_iHitDmg = 20;

	if (m_flMaxYaw <= 0)
		m_flMaxYaw = 65;

	m_MonsterState = MONSTERSTATE_IDLE;

	// SetThink( Test );
	UTIL_SetOrigin( pev, pev->origin );
}

void CMTentacle :: Precache( )
{
	PRECACHE_MODEL("models/tentacle2.mdl");

	PRECACHE_SOUND("ambience/flies.wav");
	PRECACHE_SOUND("ambience/squirm2.wav");

	PRECACHE_SOUND("tentacle/te_alert1.wav");
	PRECACHE_SOUND("tentacle/te_alert2.wav");
	PRECACHE_SOUND("tentacle/te_flies1.wav");
	PRECACHE_SOUND("tentacle/te_move1.wav");
	PRECACHE_SOUND("tentacle/te_move2.wav");
	PRECACHE_SOUND("tentacle/te_roar1.wav");
	PRECACHE_SOUND("tentacle/te_roar2.wav");
	PRECACHE_SOUND("tentacle/te_search1.wav");
	PRECACHE_SOUND("tentacle/te_search2.wav");
	PRECACHE_SOUND("tentacle/te_sing1.wav");
	PRECACHE_SOUND("tentacle/te_sing2.wav");
	PRECACHE_SOUND("tentacle/te_squirm2.wav");
	PRECACHE_SOUND("tentacle/te_strike1.wav");
	PRECACHE_SOUND("tentacle/te_strike2.wav");
	PRECACHE_SOUND("tentacle/te_swing1.wav");
	PRECACHE_SOUND("tentacle/te_swing2.wav");

	PRECACHE_SOUND_ARRAY( pHitSilo );
	PRECACHE_SOUND_ARRAY( pHitDirt );
	PRECACHE_SOUND_ARRAY( pHitWater );
}


CMTentacle::CMTentacle( )
{
	m_flMaxYaw = 65;
	m_iTapSound = 0;
}

void CMTentacle::KeyValue( KeyValueData *pkvd )
{
	if (FStrEq(pkvd->szKeyName, "sweeparc"))
	{
		m_flMaxYaw = atof(pkvd->szValue) / 2.0;
		pkvd->fHandled = TRUE;
	}
	else if (FStrEq(pkvd->szKeyName, "sound"))
	{
		m_iTapSound = atoi(pkvd->szValue);
		pkvd->fHandled = TRUE;

	}
	else
		CMBaseMonster::KeyValue( pkvd );
}



int CMTentacle :: Level( float dz )
{
	if (dz < 216)
		return 0;
	if (dz < 408)
		return 1;
	if (dz < 600)
		return 2;
	return 3;
}


float CMTentacle :: MyHeight( )
{
	switch ( MyLevel( ) )
	{
	case 1:
		return 256;
	case 2:
		return 448;
	case 3:
		return 640;
	}
	return 0;
}


int CMTentacle :: MyLevel( )
{
	switch( pev->sequence )
	{
	case TENTACLE_ANIM_Pit_Idle: 
		return -1;

	case TENTACLE_ANIM_rise_to_Temp1:
	case TENTACLE_ANIM_Temp1_to_Floor:
	case TENTACLE_ANIM_Floor_to_Lev1:
		return 0;

	case TENTACLE_ANIM_Floor_Idle:
	case TENTACLE_ANIM_Floor_Fidget_Pissed:
	case TENTACLE_ANIM_Floor_Fidget_SmallRise:
	case TENTACLE_ANIM_Floor_Fidget_Wave:
	case TENTACLE_ANIM_Floor_Strike:
	case TENTACLE_ANIM_Floor_Tap:
	case TENTACLE_ANIM_Floor_Rotate:
	case TENTACLE_ANIM_Floor_Rear:
	case TENTACLE_ANIM_Floor_Rear_Idle:
		return 0;

	case TENTACLE_ANIM_Lev1_Idle:
	case TENTACLE_ANIM_Lev1_Fidget_Claw:
	case TENTACLE_ANIM_Lev1_Fidget_Shake:
	case TENTACLE_ANIM_Lev1_Fidget_Snap:
	case TENTACLE_ANIM_Lev1_Strike:
	case TENTACLE_ANIM_Lev1_Tap:
	case TENTACLE_ANIM_Lev1_Rotate:
	case TENTACLE_ANIM_Lev1_Rear:
	case TENTACLE_ANIM_Lev1_Rear_Idle:
		return 1;

	case TENTACLE_ANIM_Lev1_to_Lev2:
		return 1;

	case TENTACLE_ANIM_Lev2_Idle:
	case TENTACLE_ANIM_Lev2_Fidget_Shake:
	case TENTACLE_ANIM_Lev2_Fidget_Swing:
	case TENTACLE_ANIM_Lev2_Fidget_Tut:
	case TENTACLE_ANIM_Lev2_Strike:
	case TENTACLE_ANIM_Lev2_Tap:
	case TENTACLE_ANIM_Lev2_Rotate:
	case TENTACLE_ANIM_Lev2_Rear:
	case TENTACLE_ANIM_Lev2_Rear_Idle:
		return 2;

	case TENTACLE_ANIM_Lev2_to_Lev3:
		return 2;

	case TENTACLE_ANIM_Lev3_Idle:
	case TENTACLE_ANIM_Lev3_Fidget_Shake:
	case TENTACLE_ANIM_Lev3_Fidget_Side:
	case TENTACLE_ANIM_Lev3_Fidget_Swipe:
	case TENTACLE_ANIM_Lev3_Strike:
	case TENTACLE_ANIM_Lev3_Tap:
	case TENTACLE_ANIM_Lev3_Rotate:
	case TENTACLE_ANIM_Lev3_Rear:
	case TENTACLE_ANIM_Lev3_Rear_Idle:
		return 3;

	case TENTACLE_ANIM_Lev1_Door_reach:
		return -1;
	}
	return -1;
}


void CMTentacle :: Test( void )
{
	pev->sequence = TENTACLE_ANIM_Floor_Strike;
	pev->framerate = 0;
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.1;
}



//
// TentacleThink
//
void CMTentacle :: Cycle( void )
{
	float m_flLastEnemySightTime = gpGlobals->time;
	
	// ALERT( at_console, "%s %.2f %d %d\n", STRING( pev->targetname ), pev->origin.z, m_MonsterState, m_IdealMonsterState );
	pev->nextthink = gpGlobals-> time + 0.1;

	// ALERT( at_console, "%s %d %d %d %f %f\n", STRING( pev->targetname ), pev->sequence, m_iGoalAnim, m_iDir, pev->framerate, pev->health );

	if (m_MonsterState == MONSTERSTATE_SCRIPT || m_IdealMonsterState == MONSTERSTATE_SCRIPT)
	{
		pev->angles.y = m_flInitialYaw;
		pev->ideal_yaw = m_flInitialYaw;	
		ClearConditions( IgnoreConditions() );
		MonsterThink( );
		m_iGoalAnim = TENTACLE_ANIM_Pit_Idle;
		return;
	}

	DispatchAnimEvents( );
	StudioFrameAdvance( );

	ChangeYaw( pev->yaw_speed );
	

		Look(1000);
		m_hEnemy = BestVisibleEnemy();

	if (m_hEnemy != NULL) 
	{
			
		Vector vecDir;
		vecDir = m_hEnemy->v.origin - pev->origin;
		m_flLastEnemySightTime = gpGlobals->time;
		m_vecPrevSound = m_hEnemy->v.origin;

		m_flSoundYaw = UTIL_VecToYaw ( vecDir ) - m_flInitialYaw;
		m_iSoundLevel = Level( vecDir.z );

		if (m_flSoundYaw < -180)
			m_flSoundYaw += 360;
		if (m_flSoundYaw > 180)
			m_flSoundYaw -= 360;

		// ALERT( at_console, "sound %d %.0f\n", m_iSoundLevel, m_flSoundYaw );
		if (m_flLastEnemySightTime < gpGlobals->time)
		{
			// play "I hear new something" sound
			char *sound;	

			switch( RANDOM_LONG(0,1) )
			{
			case 0: sound = "tentacle/te_alert1.wav"; break;
			case 1: sound = "tentacle/te_alert2.wav"; break;
			}

			// UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), sound, 1.0, ATTN_NORM, 0, 100);
		}
		m_flSoundTime = gpGlobals->time + RANDOM_FLOAT( 5.0, 10.0 );
	} 

	// clip ideal_yaw
	float dy = m_flSoundYaw;
	switch( pev->sequence )
	{
	case TENTACLE_ANIM_Floor_Rear:
	case TENTACLE_ANIM_Floor_Rear_Idle:
	case TENTACLE_ANIM_Lev1_Rear:
	case TENTACLE_ANIM_Lev1_Rear_Idle:
	case TENTACLE_ANIM_Lev2_Rear:
	case TENTACLE_ANIM_Lev2_Rear_Idle:
	case TENTACLE_ANIM_Lev3_Rear:
	case TENTACLE_ANIM_Lev3_Rear_Idle:
		if (dy < 0 && dy > -m_flMaxYaw)
			dy = -m_flMaxYaw;
		if (dy > 0 && dy < m_flMaxYaw)
			dy = m_flMaxYaw;
		break;
	default:
		if (dy < -m_flMaxYaw)
			dy = -m_flMaxYaw;
		if (dy > m_flMaxYaw)
			dy = m_flMaxYaw;
	}
	pev->ideal_yaw = m_flInitialYaw + dy;

	if (m_fSequenceFinished)
	{
		// ALERT( at_console, "%s done %d %d\n", STRING( pev->targetname ), pev->sequence, m_iGoalAnim );
		if (pev->health <= 1)
		{
			m_iGoalAnim = TENTACLE_ANIM_Pit_Idle;
			if (pev->sequence == TENTACLE_ANIM_Pit_Idle)
			{
				UTIL_Remove (this ->edict() );
			}
		}
		else if ( m_flSoundTime > gpGlobals->time )
		{
			if (m_flSoundYaw >= -(m_flMaxYaw + 30) && m_flSoundYaw <= (m_flMaxYaw + 30))
			{
				// strike
				m_iGoalAnim = LookupActivity( ACT_T_STRIKE + m_iSoundLevel );
			}
			else if (m_flSoundYaw >= -m_flMaxYaw * 2 && m_flSoundYaw <= m_flMaxYaw * 2) 
			{
				// tap
				m_iGoalAnim = LookupActivity( ACT_T_TAP + m_iSoundLevel );
			}
			else
			{
				// go into rear idle
				m_iGoalAnim = LookupActivity( ACT_T_REARIDLE + m_iSoundLevel );
			}
		}
		else if (pev->sequence == TENTACLE_ANIM_Pit_Idle)
		{
			// stay in pit until hear noise
			m_iGoalAnim = TENTACLE_ANIM_Pit_Idle;
		}
		else if (pev->sequence == m_iGoalAnim)
		{
			if (MyLevel() >= 0 && gpGlobals->time < m_flSoundTime)
			{
				if (RANDOM_LONG(0,9) < m_flSoundTime - gpGlobals->time)
				{
					// continue stike
					m_iGoalAnim = LookupActivity( ACT_T_STRIKE + m_iSoundLevel );
				}
				else
				{
					// tap
					m_iGoalAnim = LookupActivity( ACT_T_TAP + m_iSoundLevel );
				}
			}
			else if (MyLevel( ) < 0)
			{
				m_iGoalAnim = LookupActivity( ACT_T_IDLE + 0 );
			}
			else
			{
				if (m_flNextSong < gpGlobals->time)
				{
					// play "I hear new something" sound
					char *sound;	

					switch( RANDOM_LONG(0,1) )
					{
					case 0: sound = "tentacle/te_sing1.wav"; break;
					case 1: sound = "tentacle/te_sing2.wav"; break;
					}

					EMIT_SOUND(ENT(pev), CHAN_VOICE, sound, 1.0, ATTN_NORM);

					m_flNextSong = gpGlobals->time + RANDOM_FLOAT( 10, 20 );
				}

				if (RANDOM_LONG(0,15) == 0)
				{
					// idle on new level
					m_iGoalAnim = LookupActivity( ACT_T_IDLE + RANDOM_LONG(0,3) );
				}
				else if (RANDOM_LONG(0,3)  == 0)
				{
					// tap
					m_iGoalAnim = LookupActivity( ACT_T_TAP + MyLevel( ) );
				}
				else
				{
					// idle
					m_iGoalAnim = LookupActivity( ACT_T_IDLE + MyLevel( ) );
				}
			}
			if (m_flSoundYaw < 0)
				m_flSoundYaw += RANDOM_FLOAT( 2, 8 );
			else
				m_flSoundYaw -= RANDOM_FLOAT( 2, 8 );
		}

		pev->sequence = FindTransition( pev->sequence, m_iGoalAnim, &m_iDir );

		if (m_iDir > 0)
		{
			pev->frame = 0;
		}
		else
		{
			m_iDir = -1; // just to safe
			pev->frame = 255;
		}
		ResetSequenceInfo( );

		m_flFramerateAdj = RANDOM_FLOAT( -0.2, 0.2 );
		pev->framerate = m_iDir * 1.0 + m_flFramerateAdj;

		switch( pev->sequence)
		{
		case TENTACLE_ANIM_Floor_Tap:
		case TENTACLE_ANIM_Lev1_Tap:
		case TENTACLE_ANIM_Lev2_Tap:
		case TENTACLE_ANIM_Lev3_Tap:
			{
				Vector vecSrc;
				UTIL_MakeVectors( pev->angles );

				TraceResult tr1, tr2;

				vecSrc = pev->origin + Vector( 0, 0, MyHeight() - 4);
				UTIL_TraceLine( vecSrc, vecSrc + gpGlobals->v_forward * 512, ignore_monsters, ENT( pev ), &tr1 );

				vecSrc = pev->origin + Vector( 0, 0, MyHeight() + 8);
				UTIL_TraceLine( vecSrc, vecSrc + gpGlobals->v_forward * 512, ignore_monsters, ENT( pev ), &tr2 );

				// ALERT( at_console, "%f %f\n", tr1.flFraction * 512, tr2.flFraction * 512 );

				m_flTapRadius = SetBlending( 0, RANDOM_FLOAT( tr1.flFraction * 512, tr2.flFraction * 512 ) );
			}
			break;
		default:
			m_flTapRadius = 336; // 400 - 64
			break;
		}
		pev->view_ofs.z = MyHeight( );
		// ALERT( at_console, "seq %d\n", pev->sequence );
	}

	if (m_flLastEnemySightTime + 2.0 > gpGlobals->time)
	{
		// 1.5 normal speed if hears sounds
		pev->framerate = m_iDir * 1.5 + m_flFramerateAdj;
	}
	else if (m_flLastEnemySightTime + 5.0 > gpGlobals->time)
	{
		// slowdown to normal
		pev->framerate = m_iDir + m_iDir * (5 - (gpGlobals->time - m_flLastEnemySightTime)) / 2 + m_flFramerateAdj;
	}
}



void CMTentacle::CommandUse( edict_t *pActivator, edict_t *pCaller, USE_TYPE useType, float value )
{
	// ALERT( at_console, "%s triggered %d\n", STRING( pev->targetname ), useType ); 
	switch( useType )
	{
	case USE_OFF:
		pev->takedamage = DAMAGE_NO;
		SetThink( DieThink );
		m_iGoalAnim = TENTACLE_ANIM_Engine_Death1;
		break;
	case USE_SET:
		break;
	case USE_TOGGLE:
		pev->takedamage = DAMAGE_NO;
		SetThink( DieThink );
		m_iGoalAnim = TENTACLE_ANIM_Engine_Idle;
		break;
	}

}



void CMTentacle :: DieThink( void )
{
	pev->nextthink = gpGlobals-> time + 0.1;

	DispatchAnimEvents( );
	StudioFrameAdvance( );

	ChangeYaw( 24 );

	if (m_fSequenceFinished)
	{
		if (pev->sequence == m_iGoalAnim)
		{
			switch( m_iGoalAnim )
			{
			case TENTACLE_ANIM_Engine_Idle:
			case TENTACLE_ANIM_Engine_Sway:
			case TENTACLE_ANIM_Engine_Swat:
			case TENTACLE_ANIM_Engine_Bob:
				m_iGoalAnim = TENTACLE_ANIM_Engine_Sway + RANDOM_LONG( 0, 2 );
				break;
			case TENTACLE_ANIM_Engine_Death1:
			case TENTACLE_ANIM_Engine_Death2:
			case TENTACLE_ANIM_Engine_Death3:
				UTIL_Remove( this->edict() );
				return;
			}
		}

		// ALERT( at_console, "%d : %d => ", pev->sequence, m_iGoalAnim );
		pev->sequence = FindTransition( pev->sequence, m_iGoalAnim, &m_iDir );
		// ALERT( at_console, "%d\n", pev->sequence );

		if (m_iDir > 0)
		{
			pev->frame = 0;
		}
		else
		{
			pev->frame = 255;
		}
		ResetSequenceInfo( );

		float dy;
		switch( pev->sequence )
		{
		case TENTACLE_ANIM_Floor_Rear:
		case TENTACLE_ANIM_Floor_Rear_Idle:
		case TENTACLE_ANIM_Lev1_Rear:
		case TENTACLE_ANIM_Lev1_Rear_Idle:
		case TENTACLE_ANIM_Lev2_Rear:
		case TENTACLE_ANIM_Lev2_Rear_Idle:
		case TENTACLE_ANIM_Lev3_Rear:
		case TENTACLE_ANIM_Lev3_Rear_Idle:
		case TENTACLE_ANIM_Engine_Idle:
		case TENTACLE_ANIM_Engine_Sway:
		case TENTACLE_ANIM_Engine_Swat:
		case TENTACLE_ANIM_Engine_Bob:
		case TENTACLE_ANIM_Engine_Death1:
		case TENTACLE_ANIM_Engine_Death2:
		case TENTACLE_ANIM_Engine_Death3:
			pev->framerate = RANDOM_FLOAT( m_iDir - 0.2, m_iDir + 0.2 );
			dy = 180;
			break;
		default:
			pev->framerate = 1.5;
			dy = 0;
			break;
		}
		pev->ideal_yaw = m_flInitialYaw + dy;
	}
}


void CMTentacle :: HandleAnimEvent( MonsterEvent_t *pEvent )
{
	char *sound;

	switch( pEvent->event )
	{
	case 1:	// bang 
		{
			Vector vecSrc, vecAngles;
			GetAttachment( 0, vecSrc, vecAngles );

			// Vector vecSrc = pev->origin + m_flTapRadius * Vector( cos( pev->angles.y * (3.14192653 / 180.0) ), sin( pev->angles.y * (M_PI / 180.0) ), 0.0 );

			// vecSrc.z += MyHeight( );

			switch( m_iTapSound )
			{
			case TE_SILO:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitSilo ), 1.0, ATTN_NORM, 0, 100);
				break;
			case TE_NONE:
				break;
			case TE_DIRT:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitDirt ), 1.0, ATTN_NORM, 0, 100);
				break;
			case TE_WATER:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitWater ), 1.0, ATTN_NORM, 0, 100);
				break;
			}
          gpGlobals->force_retouch++;
		}
		break;

	case 3: // start killing swing
		m_iHitDmg = 200;
		// UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), "tentacle/te_swing1.wav", 1.0, ATTN_NORM, 0, 100);
		break;

	case 4: // end killing swing
		m_iHitDmg = 25;
		break;

	case 5: // just "whoosh" sound
		// UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), "tentacle/te_swing2.wav", 1.0, ATTN_NORM, 0, 100);
		break;

	case 2:	// tap scrape
	case 6: // light tap
		{
			Vector vecSrc = pev->origin + m_flTapRadius * Vector( cos( pev->angles.y * (M_PI / 180.0) ), sin( pev->angles.y * (M_PI / 180.0) ), 0.0 );

			vecSrc.z += MyHeight( );

			float flVol = RANDOM_FLOAT( 0.3, 0.5 );

			switch( m_iTapSound )
			{
			case TE_SILO:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitSilo ), flVol, ATTN_NORM, 0, 100);
				break;
			case TE_NONE:
				break;
			case TE_DIRT:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitDirt ), flVol, ATTN_NORM, 0, 100);
				break;
			case TE_WATER:
				UTIL_EmitAmbientSound(ENT(pev), vecSrc, RANDOM_SOUND_ARRAY( pHitWater ), flVol, ATTN_NORM, 0, 100);
				break;
			}
		}
		break;


	case 7: // roar
		switch( RANDOM_LONG(0,1) )
		{
		case 0: sound = "tentacle/te_roar1.wav"; break;
		case 1: sound = "tentacle/te_roar2.wav"; break;
		}

		UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), sound, 1.0, ATTN_NORM, 0, 100);
		break;

	case 8: // search
		switch( RANDOM_LONG(0,1) )
		{
		case 0: sound = "tentacle/te_search1.wav"; break;
		case 1: sound = "tentacle/te_search2.wav"; break;
		}

		UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), sound, 1.0, ATTN_NORM, 0, 100);
		break;

	case 9: // swing
		switch( RANDOM_LONG(0,1) )
		{
		case 0: sound = "tentacle/te_move1.wav"; break;
		case 1: sound = "tentacle/te_move2.wav"; break;
		}

		UTIL_EmitAmbientSound(ENT(pev), pev->origin + Vector( 0, 0, MyHeight()), sound, 1.0, ATTN_NORM, 0, 100);
		break;

	default:
		CMBaseMonster::HandleAnimEvent( pEvent );
	}
}


//
// TentacleStart
//
// void CMTentacle :: Start( CBaseEntity *pActivator, CBaseEntity *pCaller, USE_TYPE useType, float value )
void CMTentacle :: Start( void )
{
	SetThink( Cycle );


	
	pev->nextthink = gpGlobals->time + 0.1;
}




void CMTentacle :: HitTouch( edict_t *pOther )
{
	TraceResult tr = UTIL_GetGlobalTrace( );

	if (pOther->v.modelindex == pev->modelindex)
		return;

	if (m_flHitTime > gpGlobals->time)
		return;

	// only look at the ones where the player hit me
	if (tr.pHit == NULL || tr.pHit->v.modelindex != pev->modelindex)
		return;

	if (tr.iHitgroup >= 3)
	{
		UTIL_TakeDamage( pOther,pev, pev, 1000, DMG_CRUSH );
		// ALERT( at_console, "wack %3d : ", m_iHitDmg );
	}
	else if (tr.iHitgroup != 0)
	{
		UTIL_TakeDamage( pOther,pev, pev, 20, DMG_CRUSH );
		// ALERT( at_console, "tap  %3d : ", 20 );
	}
	else
	{
		UTIL_TakeDamage( pOther,pev, pev, 20, DMG_CRUSH );
	}

	m_flHitTime = gpGlobals->time + 0.5;

	// ALERT( at_console, "%s : ", STRING( tr.pHit->v.classname ) );

	// ALERT( at_console, "%.0f : %s : %d\n", pev->angles.y, STRING( pOther->pev->classname ), tr.iHitgroup );
}


int CMTentacle::TakeDamage( entvars_t* pevInflictor, entvars_t* pevAttacker, float flDamage, int bitsDamageType )
{
	if (flDamage > pev->health)
	{
		pev->health = 1;
	}
	else
	{
		pev->health -= flDamage;
	}
	return 1;
}




void CMTentacle :: Killed( entvars_t *pevAttacker, int iGib )
{
	m_iGoalAnim = TENTACLE_ANIM_Pit_Idle;
	return;
}



class CMTentacleMaw : public CMBaseMonster
{
public:
	void Spawn( );
	void Precache( );
};


//
// Tentacle Spawn
//
void CMTentacleMaw :: Spawn( )
{
	Precache( );
	SET_MODEL(ENT(pev), "models/maw.mdl");
	UTIL_SetSize(pev, Vector(-32, -32, 0), Vector(32, 32, 64));

	pev->solid			= SOLID_NOT;
	pev->movetype		= MOVETYPE_STEP;
	pev->effects		= 0;
	pev->health			= gSkillData.TentacleHealth;
	pev->yaw_speed		= 8;
	pev->sequence		= 0;
	
	pev->angles.x		= 90;
	// ResetSequenceInfo( );
}

void CMTentacleMaw :: Precache( )
{
	PRECACHE_MODEL("models/maw.mdl");
}

#endif