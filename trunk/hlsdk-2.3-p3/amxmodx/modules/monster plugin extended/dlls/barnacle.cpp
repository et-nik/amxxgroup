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
//=========================================================
// barnacle - stationary ceiling mounted 'fishing' monster
//=========================================================

#include	"extdll.h"
#include	"util.h"
#include	"cmbase.h"
#include    "cmbasemonster.h"
#include	"monsters.h"
#include	"schedule.h"

#define	BARNACLE_BODY_HEIGHT	44 // how 'tall' the barnacle's model is.
#define BARNACLE_PULL_SPEED		8
#define BARNACLE_KILL_VICTIM_DELAY	5 // how many seconds after pulling prey in to gib them. 

//=========================================================
// Monster's Anim Events Go Here
//=========================================================
#define	BARNACLE_AE_PUKEGIB	2




//=========================================================
// Classify - indicates this monster's place in the 
// relationship table.
//=========================================================
int	CMBarnacle :: Classify ( void )
{
	return	CLASS_ALIEN_MONSTER;
}

//=========================================================
// HandleAnimEvent - catches the monster-specific messages
// that occur when tagged animation frames are played.
//
// Returns number of events handled, 0 if none.
//=========================================================
void CMBarnacle :: HandleAnimEvent( MonsterEvent_t *pEvent )
{
	switch( pEvent->event )
	{
	case BARNACLE_AE_PUKEGIB:
		CMGib::SpawnRandomGibs( pev, 1, 1 );	
		break;
	default:
		CMBaseMonster::HandleAnimEvent( pEvent );
		break;
	}
}

//=========================================================
// Spawn
//=========================================================
void CMBarnacle :: Spawn()
{
	Precache( );

	SET_MODEL(ENT(pev), "models/barnacle.mdl");
	UTIL_SetSize( pev, Vector(-16, -16, -32), Vector(16, 16, 0) );

	pev->solid			= SOLID_SLIDEBOX;
	pev->movetype		= MOVETYPE_NONE;
	pev->takedamage		= DAMAGE_AIM;
	m_bloodColor		= BLOOD_COLOR_RED;
	pev->effects		= EF_INVLIGHT; // take light from the ceiling 
	pev->health			= gSkillData.BarnacleHealth;
	m_flFieldOfView		= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
	m_MonsterState		= MONSTERSTATE_NONE;
	m_flKillVictimTime	= 0;
	m_flDmgVictimTime	= 0;
	m_cGibs				= 0;
	m_fLiftingPrey		= FALSE;
	m_flTongueAdj		= -100;

	InitBoneControllers();

	SetActivity ( ACT_IDLE );

	SetThink ( BarnacleThink );
	pev->nextthink = gpGlobals->time + 0.5;

	UTIL_SetOrigin ( pev, pev->origin );
}

int CMBarnacle::TakeDamage( entvars_t *pevInflictor, entvars_t *pevAttacker, float flDamage, int bitsDamageType )
{
	return CMBaseMonster::TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
}

//=========================================================
//=========================================================
void CMBarnacle :: BarnacleThink ( void )
{
	
	edict_t *pTouchEnt;
	edict_t *pEdict = m_hEnemy;
	CMBaseMonster *pVictim = GetClassPtr((CMBaseMonster *)VARS(pEdict));

	float flLength;

	pev->nextthink = gpGlobals->time + 0.1;

	if ( m_hEnemy != NULL && UTIL_IsPlayer(m_hEnemy) )
	{
// barnacle has prey.

		if ( !UTIL_IsAlive(m_hEnemy))
		{
			// someone (maybe even the barnacle) killed the prey. Reset barnacle.
			m_fLiftingPrey = FALSE;// indicate that we're not lifting prey.
			m_hEnemy = NULL;
			pev->health = gSkillData.BarnacleHealth;
			SetActivity ( ACT_IDLE );
			return;
		}

		if ( m_fLiftingPrey )
		{
			if ( m_hEnemy != NULL && m_hEnemy->v.deadflag != DEAD_NO)
			{
				// crap, someone killed the prey on the way up.
				m_hEnemy = NULL;
				m_fLiftingPrey = FALSE;
				pev->health = gSkillData.BarnacleHealth;
				SetActivity ( ACT_IDLE );
				return;
			}

	// still pulling prey.
						
			
			Vector vecNewEnemyOrigin = m_hEnemy->v.origin;
			vecNewEnemyOrigin.x = pev->origin.x;
			vecNewEnemyOrigin.y = pev->origin.y;
			pev->health = 10000;
					
										
			// guess as to where their neck is
            m_flAltitude -= BARNACLE_PULL_SPEED;
			vecNewEnemyOrigin.z += BARNACLE_PULL_SPEED;
			

			if ( fabs( pev->origin.z - ( m_hEnemy->v.origin.z + m_hEnemy->v.view_ofs.z - 8 ) ) < BARNACLE_BODY_HEIGHT )
			{
		// prey has just been lifted into position ( if the victim origin + eye height + 8 is higher than the bottom of the barnacle, it is assumed that the head is within barnacle's body )
				m_fLiftingPrey = FALSE;
				pev->health = 10000;
				m_hEnemy->v.gravity = 1;

				EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_bite3.wav", 1, ATTN_NORM );					
					SetActivity ( ACT_EAT );							
					m_flKillVictimTime = gpGlobals->time + 10;
					m_flDmgVictimTime = gpGlobals->time + 1; 
					
							
				
			}
			//UTIL_SetOrigin(&m_hEnemy->v, vecNewEnemyOrigin );
			m_hEnemy->v.origin.x = pev->origin.x;
			m_hEnemy->v.origin.y = pev->origin.y;
			m_hEnemy->v.origin.z = vecNewEnemyOrigin.z;
		}
		else
		{
	// prey is lifted fully into feeding position and is dangling there.

			
			// bite prey every once in a while
			if (m_hEnemy != NULL && RANDOM_LONG(0,20) == 0)
			{
				switch ( RANDOM_LONG(0,2) )
				{
				case 0:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew1.wav", 1, ATTN_NORM );	break;
				case 1:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew2.wav", 1, ATTN_NORM );	break;
				case 2:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew3.wav", 1, ATTN_NORM );	break;
				}			
			}
			if ( m_flDmgVictimTime != -1 && gpGlobals->time > m_flDmgVictimTime)
			{
				if (UTIL_IsPlayer(m_hEnemy))
				{
					m_flDmgVictimTime = gpGlobals->time + 1;
					UTIL_TakeDamage ( m_hEnemy,pev, pev, 20, DMG_ALWAYSGIB );

				}
			}
			if ( m_flKillVictimTime != -1 && gpGlobals->time > m_flKillVictimTime)
			{
				if (UTIL_IsPlayer(m_hEnemy))
				{
					UTIL_TakeDamage ( m_hEnemy,pev, pev, 10000, DMG_ALWAYSGIB );
					EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_bite3.wav", 1, ATTN_NORM );

				}

			}
		}
	}
	else
	{

// barnacle has no prey right now, so just idle and check to see if anything is touching the tongue.

		// If idle and no nearby client, don't think so often
		if ( FNullEnt( FIND_CLIENT_IN_PVS( edict() ) ) )
			pev->nextthink = gpGlobals->time + RANDOM_FLOAT(1,1.5);	// Stagger a bit to keep barnacles from thinking on the same frame

		if ( m_fSequenceFinished )
		{// this is done so barnacle will fidget.
			SetActivity ( ACT_IDLE );
			m_flTongueAdj = -100;
		}

		if ( m_cGibs && RANDOM_LONG(0,99) == 1 )
		{
			// cough up a gib.
			CMGib::SpawnRandomGibs( pev, 1, 1 );
			m_cGibs--;

			switch ( RANDOM_LONG(0,2) )
			{
			case 0:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew1.wav", 1, ATTN_NORM );	break;
			case 1:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew2.wav", 1, ATTN_NORM );	break;
			case 2:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_chew3.wav", 1, ATTN_NORM );	break;
			}
		}

		pTouchEnt = TongueTouchEnt( &flLength );

		if ( pTouchEnt != NULL && m_fTongueExtended && UTIL_IsPlayer(pTouchEnt))
		{
			// tongue is fully extended, and is touching someone.
			//if ( UTIL_IsAlive(pTouchEnt) )
			{
				EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_alert2.wav", 1, ATTN_NORM );	

				SetSequenceByName ( "attack1" );
				m_flTongueAdj = -20;
				m_hEnemy = pTouchEnt;
							
				pTouchEnt->v.gravity = 0.01;
				
				pTouchEnt->v.movetype = MOVETYPE_FLY;
				pTouchEnt->v.velocity = g_vecZero;
				pTouchEnt->v.basevelocity = g_vecZero;
				pTouchEnt->v.origin.x = pev->origin.x;
				pTouchEnt->v.origin.y = pev->origin.y;

				m_fLiftingPrey = TRUE;// indicate that we should be lifting prey.
				m_flKillVictimTime = -1;
				m_flDmgVictimTime = -1;// set this to a bogus time while the victim is lifted.

				m_flAltitude = (pev->origin.z - UTIL_EyePosition(pTouchEnt).z);
				
			}
		}
		else
		{
			// calculate a new length for the tongue to be clear of anything else that moves under it. 
			if ( m_flAltitude < flLength )
			{
				// if tongue is higher than is should be, lower it kind of slowly.
				m_flAltitude += BARNACLE_PULL_SPEED;
				m_fTongueExtended = FALSE;
			}
			else
			{
				m_flAltitude = flLength;
				m_fTongueExtended = TRUE;
			}

		}

	}

	// ALERT( at_console, "tounge %f\n", m_flAltitude + m_flTongueAdj );
	SetBoneController( 0, -(m_flAltitude + m_flTongueAdj) );
	StudioFrameAdvance( 0.1 );
}

//=========================================================
// Killed.
//=========================================================
void CMBarnacle :: Killed( entvars_t *pevAttacker, int iGib )
{
	
	pev->solid = SOLID_NOT;
	pev->takedamage = DAMAGE_NO;


	if ( m_hEnemy != NULL )
	{
			edict_t *pEdict = m_hEnemy;
			CMBaseMonster *pVictim = GetClassPtr((CMBaseMonster *)VARS(pEdict));
		

		if ( pVictim )
		{			
			
			pVictim->BarnacleVictimReleased();
		}
	}
	pev->health = 1;
	//	CGib::SpawnRandomGibs( pev, 4, 1 );

	switch ( RANDOM_LONG ( 0, 1 ) )
	{
	case 0:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_die1.wav", 1, ATTN_NORM );	break;
	case 1:	EMIT_SOUND( ENT(pev), CHAN_WEAPON, "barnacle/bcl_die3.wav", 1, ATTN_NORM );	break;
	}
	
	SetActivity ( ACT_DIESIMPLE );
	SetBoneController( 0, 0 );

	StudioFrameAdvance( 0.1 );

	pev->nextthink = gpGlobals->time + 0.1;
	SetThink ( WaitTillDead );

}

//=========================================================
//=========================================================
void CMBarnacle :: WaitTillDead ( void )
{
	pev->nextthink = gpGlobals->time + 0.1;

	float flInterval = StudioFrameAdvance( 0.1 );
	DispatchAnimEvents ( flInterval );

	if ( m_fSequenceFinished )
	{
		// death anim finished. 
		StopAnimation();
		SetThink ( NULL );
		UTIL_Remove (this -> edict() );
	}
}

//=========================================================
// Precache - precaches all resources this monster needs
//=========================================================
void CMBarnacle :: Precache()
{
	PRECACHE_MODEL("models/barnacle.mdl");

	PRECACHE_SOUND("barnacle/bcl_alert2.wav");//happy, lifting food up
	PRECACHE_SOUND("barnacle/bcl_bite3.wav");//just got food to mouth
	PRECACHE_SOUND("barnacle/bcl_chew1.wav");
	PRECACHE_SOUND("barnacle/bcl_chew2.wav");
	PRECACHE_SOUND("barnacle/bcl_chew3.wav");
	PRECACHE_SOUND("barnacle/bcl_die1.wav" );
	PRECACHE_SOUND("barnacle/bcl_die3.wav" );
}	

//=========================================================
// TongueTouchEnt - does a trace along the barnacle's tongue
// to see if any entity is touching it. Also stores the length
// of the trace in the int pointer provided.
//=========================================================
#define BARNACLE_CHECK_SPACING	8
edict_t *CMBarnacle :: TongueTouchEnt ( float *pflLength )
{
	TraceResult	tr;
	float		length;

	// trace once to hit architecture and see if the tongue needs to change position.
	UTIL_TraceLine ( pev->origin, pev->origin - Vector ( 0 , 0 , 2048 ), ignore_monsters, ENT(pev), &tr );
	length = fabs( pev->origin.z - tr.vecEndPos.z );
	if ( pflLength )
	{
		*pflLength = length;
	}

	Vector delta = Vector( BARNACLE_CHECK_SPACING, BARNACLE_CHECK_SPACING, 0 );
	Vector mins = pev->origin - delta;
	Vector maxs = pev->origin + delta;
	maxs.z = pev->origin.z;
	mins.z -= length;

	edict_t *pList[10];
	int count = UTIL_EntitiesInBox( pList, 10, mins, maxs, (FL_CLIENT|FL_MONSTER) );
	if ( count )
	{
		for ( int i = 0; i < count; i++ )
		{
			// only clients and monsters
			if ( pList[i] != this->edict() && pList[ i ]->v.deadflag == DEAD_NO )	// this ent is one of our enemies. Barnacle tries to eat it.
			{
				return pList[i];
			}
		}
	}

	return NULL;
}
