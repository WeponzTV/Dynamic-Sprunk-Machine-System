/*
	Project: Dynamic Sprunk Machine System (SA-MP)
	Version: 1.0 (June 2022)
	Credits: Weponz
	Support: https://discord.gg/fugKZrqBth

	** As Seen On YouTube: https://www.youtube.com/WeponzTV **
*/
#define FILTERSCRIPT
#include <a_samp>
#include <streamer>
#include <sscanf2>

#include <YSI_Data\y_iterate>
#include <YSI_Visual\y_commands>

#define REMOVE_DEFAULT_MACHINES//Comment out to keep default vending machines

#define SPUNK_DB_LOCATION "sprunks.db"//This file is located in scriptfiles

#define MAX_SPRUNKS 100//Only increase this number if the script tells you to

#define SPRUNK_PRICE 1//Price: $1
#define SPRUNK_HEALTH 10.0//Adds 10 HP
#define SPRUNK_KEY KEY_SECONDARY_ATTACK//Enter Key

forward OnPlayerUseMachine(playerid);

new DB:sprunk_database;
new DBResult:sprunk_result;

new Iterator:Sprunks<MAX_SPRUNKS>;

enum sprunk_data
{
	sprunk_object,
	sprunk_area,
	sprunk_interior,
	sprunk_world,
	Float:sprunk_x,
	Float:sprunk_y,
	Float:sprunk_z,
	Float:sprunk_r
};
new SprunkData[MAX_SPRUNKS][sprunk_data];

public OnFilterScriptInit()
{
    sprunk_database = db_open(SPUNK_DB_LOCATION);
    db_query(sprunk_database, "CREATE TABLE IF NOT EXISTS `SPRUNKS` (`ID` INTEGER PRIMARY KEY, `X` FLOAT, `Y` FLOAT, `Z` FLOAT, `R` FLOAT, `INTERIOR` INTEGER, `WORLD` INTEGER)");

    new query[64];
    for(new i = 0; i < MAX_SPRUNKS; i++)
    {
    	format(query, sizeof(query), "SELECT * FROM `SPRUNKS` WHERE `ID` = %i", i);
		sprunk_result = db_query(sprunk_database, query);
		if(db_num_rows(sprunk_result))
		{
			SprunkData[i][sprunk_x] = db_get_field_assoc_float(sprunk_result, "X");
			SprunkData[i][sprunk_y] = db_get_field_assoc_float(sprunk_result, "Y");
			SprunkData[i][sprunk_z] = db_get_field_assoc_float(sprunk_result, "Z");
			SprunkData[i][sprunk_r] = db_get_field_assoc_float(sprunk_result, "R");

			SprunkData[i][sprunk_interior] = db_get_field_assoc_int(sprunk_result, "INTERIOR");
			SprunkData[i][sprunk_world] = db_get_field_assoc_int(sprunk_result, "WORLD");

			SprunkData[i][sprunk_object] = CreateDynamicObject(1775, SprunkData[i][sprunk_x], SprunkData[i][sprunk_y], SprunkData[i][sprunk_z], 0.0, 0.0, SprunkData[i][sprunk_r], SprunkData[i][sprunk_world], SprunkData[i][sprunk_interior], -1, 100.0);
			SprunkData[i][sprunk_area] = CreateDynamicSphere(SprunkData[i][sprunk_x], SprunkData[i][sprunk_y], SprunkData[i][sprunk_z], 1.5, SprunkData[i][sprunk_world], SprunkData[i][sprunk_interior], -1, 0);

			Iter_Add(Sprunks, i);
		}
		db_free_result(sprunk_result);
    }
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Sprunks)
	{
		DestroyDynamicObject(SprunkData[i][sprunk_object]);
		DestroyDynamicArea(SprunkData[i][sprunk_area]);

		Iter_Remove(Sprunks, i);
	}

    db_close(sprunk_database);
	return 1;
}

public OnPlayerConnect(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;

	ApplyAnimation(playerid, "VENDING", "VEND_Drink2_P", 0, 0, 0, 0, 0, 1);
	ApplyAnimation(playerid, "VENDING", "VEND_Use", 0, 0, 0, 0, 0, 1);

	#if defined REMOVE_DEFAULT_MACHINES
		RemoveBuildingForPlayer(playerid, 955, 0.0, 0.0, 0.0, 6000.0);//Sprunk Vending Machine #1
		RemoveBuildingForPlayer(playerid, 956, 0.0, 0.0, 0.0, 6000.0);//Normal Vending Machine #1
		RemoveBuildingForPlayer(playerid, 1209, 0.0, 0.0, 0.0, 6000.0);//Soda Vending Machine #1
		RemoveBuildingForPlayer(playerid, 1302, 0.0, 0.0, 0.0, 6000.0);//Soda Vending Machine #2
		RemoveBuildingForPlayer(playerid, 1775, 0.0, 0.0, 0.0, 6000.0);//Sprunk Vending Machine #2
		RemoveBuildingForPlayer(playerid, 1776, 0.0, 0.0, 0.0, 6000.0);//Normal Vending Machine #2
	#endif
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(IsPlayerNPC(playerid)) return 1;

	if((((newkeys & (SPRUNK_KEY)) == (SPRUNK_KEY)) && ((oldkeys & (SPRUNK_KEY)) != (SPRUNK_KEY))))
	{
		if(IsPlayerInAnyDynamicArea(playerid, 0))
		{
			foreach(new i : Sprunks)
			{
				if(IsPlayerInDynamicArea(playerid, SprunkData[i][sprunk_area], 0))
				{
					new Float:x = SprunkData[i][sprunk_x], Float:y = SprunkData[i][sprunk_y];
					x -= (1.0 * floatsin(-SprunkData[i][sprunk_r], degrees));
					y -= (1.0 * floatcos(-SprunkData[i][sprunk_r], degrees));

					SetPlayerPos(playerid, x, y, SprunkData[i][sprunk_z]);
					SetPlayerFacingAngle(playerid, SprunkData[i][sprunk_r]);
					SetCameraBehindPlayer(playerid);

					GivePlayerMoney(playerid, -SPRUNK_PRICE);

					ApplyAnimation(playerid, "VENDING", "VEND_Use", 4.1, 0, 0, 0, 0, 0);
					return SetTimerEx("OnPlayerUseMachine", 2600, false, "d", playerid);
				}
			}
		}
	}
	return 1;
}

public OnPlayerUseMachine(playerid)
{
	new Float:health;				
	GetPlayerHealth(playerid, health);
	if((health + SPRUNK_HEALTH) <= 100.0) { SetPlayerHealth(playerid, (health + SPRUNK_HEALTH)); }
	return ApplyAnimation(playerid, "VENDING", "VEND_Drink2_P", 4.1, 0, 0, 0, 0, 0);
}

YCMD:createsprunk(playerid, params[], help)
{
	new query[256], Float:pos[4], id = Iter_Free(Sprunks);
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "SERVER: You must be logged in as RCON admin to use this command.");
	if(id == INVALID_ITERATOR_SLOT) return SendClientMessage(playerid, -1, "SERVER: You have reached the max aloud sprunk machines. (Increase MAX_SPRUNKS in sprunk.pwn)");
	
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	GetPlayerFacingAngle(playerid, pos[3]);

	SprunkData[id][sprunk_x] = pos[0];
	SprunkData[id][sprunk_y] = pos[1];
	SprunkData[id][sprunk_z] = pos[2];

	SprunkData[id][sprunk_r] = pos[3]; // There is no reason to complicate

	SprunkData[id][sprunk_interior] = GetPlayerInterior(playerid);
	SprunkData[id][sprunk_world] = GetPlayerVirtualWorld(playerid);
	
	SprunkData[id][sprunk_object] = CreateDynamicObject(1775, SprunkData[id][sprunk_x], SprunkData[id][sprunk_y], SprunkData[id][sprunk_z], 0.0, 0.0, SprunkData[id][sprunk_r], SprunkData[id][sprunk_world], SprunkData[id][sprunk_interior], -1, 100.0);
	SprunkData[id][sprunk_area] = CreateDynamicSphere(SprunkData[id][sprunk_x], SprunkData[id][sprunk_y], SprunkData[id][sprunk_z], 1.5, SprunkData[id][sprunk_world], SprunkData[id][sprunk_interior], -1, 0);

	format(query, sizeof(query), "INSERT INTO `SPRUNKS` (`ID`, `X`, `Y`, `Z`, `R`, `INTERIOR`, `WORLD`) VALUES ('%i', '%f', '%f', '%f', '%f', '%i', '%i')", id, SprunkData[id][sprunk_x], SprunkData[id][sprunk_y], SprunkData[id][sprunk_z], SprunkData[id][sprunk_r], SprunkData[id][sprunk_interior], SprunkData[id][sprunk_world]);
	sprunk_result = db_query(sprunk_database, query);
	db_free_result(sprunk_result);

	Iter_Add(Sprunks, id);

	pos[0] -= (1.5 * floatsin(-pos[3], degrees));
	pos[1] -= (1.5 * floatcos(-pos[3], degrees));

	SetPlayerPos(playerid, pos[0], pos[1], pos[2]);

	format(query, sizeof(query), "~g~Machine Created! (%i/%i Created)", Iter_Count(Sprunks), MAX_SPRUNKS);
	return GameTextForPlayer(playerid, query, 3000, 5);
}

YCMD:deletesprunk(playerid, params[], help)
{
	new query[64], interior = GetPlayerInterior(playerid), world = GetPlayerVirtualWorld(playerid);
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "SERVER: You must be logged in as RCON admin to use this command.");

	foreach(new i : Sprunks)
	{
		if(IsPlayerInRangeOfPoint(playerid, 2.0, SprunkData[i][sprunk_x], SprunkData[i][sprunk_y], SprunkData[i][sprunk_z]) && interior == SprunkData[i][sprunk_interior] && world == SprunkData[i][sprunk_world])
		{
			DestroyDynamicObject(SprunkData[i][sprunk_object]);
			DestroyDynamicArea(SprunkData[i][sprunk_area]);

			Iter_Remove(Sprunks, i);

			format(query, sizeof(query), "DELETE FROM `SPRUNKS` WHERE `ID` = %i", i);
		    sprunk_result = db_query(sprunk_database, query);
		 	db_free_result(sprunk_result);

			format(query, sizeof(query), "~r~Machine Deleted! (%i/%i Left)", Iter_Count(Sprunks), MAX_SPRUNKS);
			return GameTextForPlayer(playerid, query, 3000, 5);
		}
	}
	return SendClientMessage(playerid, -1, "SERVER: There are no sprunk machines nearby to delete.");
}
