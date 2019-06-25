/*
	         PlayerUnknown's Battleground TDM
			        Version : Beta
		     Scripted: Oblivion and Ninja
		     Testers: Oblivion and Ninja
  Note: No support given to this script until the next version release! Enjoy <3

  Note:
  - if you found any bugs, please report it in the comment section. This script has lack of  optimizations.
  - This script is totally scripted as FilterScript, if you are going to implement this into your gamemode,
	your should remove return value under OnPlayerUpdate callback!
  - If there is any mistake or issues in code please reply in down in comments if possible also post the fix if you know!
  
Features :
  - Infinity Tdm Slots.
  - Only 4 players can be in both teams per sloth!
  - Team messages and Slot Messages function
  - Kills and Deaths  textdraw messages
  - Score Board Like Pubg
  - Player Statistics textdraws like pubg
  - Your team can't see opponent team player blip!
  - Inventry System (Weapons are near your spawn area) Thanks to CaioTJF!
*/

#include <a_samp> // Credits to SA-MP Team
#include <streamer> // Credits to Incognito
#include <sscanf2> // Credits to maddinat0r
#include <foreach> // Credits to Kar
#include <zcmd> // Credits to Zeex


//------- Team Defines and Gloabl Defines ---
#define MAX_OBJECTIVE       40 // Change this to your required objective
#define MAX_TDM_PLAYERS     1 // Don't change this!
#define MAX_SLOT_PLAYERS    8  // 4 players in both team!

#define TEAMNONE  			255
#define TEAMBLUE  			1
#define TEAMRED  			2

#define MAX_TDM_SLOTS 		6 // Change this to your required slots (Ingame it shows like 1-6)
#define START_COUNT         31 // (from 30 (31 -1s))
#define MAX_TIME 			600 // 10 mins
#define DIALOGID 			12

#define MAX_INVENTORY_SLOTS 15 // Don't Change this!
#define TIMER_ITEM_WORLD    60*10
#define MAX_ITEMS_SLOT      500 // Maxium items in slot! (Default: 500)

#define COLOR_WHITE 		0xFFFFFFFF
#define COLOR_GREEN 		0x3BBD44FF
#define COLOR_BLUE			0x004BFFFF
#define COLOR_RED 			0xFF0000FF

#define CWHITE  			"{F0F0F0}"
#define CBLUE 	 			"{56A4E4}"
#define CRED     			"{FF000F}"
#define CYELLOW  			"{F2F853}"

#define PUBGTDM1 			""CYELLOW"[PUBG TDM] "CWHITE""
#define PUBGTDM2 			""CYELLOW"[PUBG TDM SLOT] "CWHITE""
#define SendError(%1,%2) 	SendClientMessage(%1, -1, ""CRED"[INFO] "CRED""%2)

// ------- ENUM AND VARS -----------------------
enum tinfo
{
   Started, // Match started
   Active,  // Slot is ready, and able to join!
   Count,   // Countdowns (According to Slot)
   BlueTeamPlayers,
   RedTeamPlayers,
   BlueTeamKills,
   RedTeamKills,
   CountTimer, // Count Timer (According to Slot)
   TeamCount[2],
   EndTimer,
   EndCount
};

enum pinfo
{
	 InPTDM,
	 TeamID,
	 SlotID,
	 Combo,
	 Kills,
	 Assists,
	 pInvincibility,
	 pInvincibilityTimer,
	 TotalCombo,
	 bool:inInventory,
	 bool:MessageInventory,
	 MessageInventoryTimer,
	 bool:ShowingkillTD
};
enum enum_Items
{
	item_id,
 	item_type,
  	item_model,
 	item_name[24],
	item_limit,
	bool:item_canbedropped,
	Float:item_previewrot[4],
	item_description[200]
}

enum
{
	ITEM_TYPE_WEAPON,
	ITEM_TYPE_HELMET,
	ITEM_TYPE_NORMAL,
	ITEM_TYPE_BODY,
	ITEM_TYPE_AMMO,
	ITEM_TYPE_BACKPACK,
	ITEM_TYPE_MELEEWEAPON
}

enum enum_pInventory
{
	invSlot[MAX_INVENTORY_SLOTS],
	invSelectedSlot,
	invSlotAmount[MAX_INVENTORY_SLOTS],
	Float:invArmourStatus[MAX_INVENTORY_SLOTS]
}

enum enum_pCharacter
{
	charSlot[7],
	charSelectedSlot,
	Float:charArmourStatus
}
enum enum_TdmSlotItems
{
	bool:world_active,
	world_itemid,
	world_model,
	world_amount,
	world_object,
	world_timer,
	Text3D:world_3dtext,
	Float:world_armourstatus,
	Float:world_position[3],

}
new ItemsData[][enum_Items] =
{
	{0, 	ITEM_TYPE_NORMAL,		19382, 		"Nothing", 				0,			false,		{0.0,0.0,0.0,0.0}, 								"N/A"},
	{1, 	ITEM_TYPE_HELMET, 		18645, 		"Helmet", 			    1,			true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Protege contra headshots."},
	{2, 	ITEM_TYPE_WEAPON, 		348, 		"Deagle", 				20, 		true,		{0.000000, -30.00000, 0.000000, 1.200000}, 		"High-caliber gun. ~N~~n~~g~Headshot enabled."},
	{3, 	ITEM_TYPE_WEAPON, 		356, 		"M4", 					20, 		true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Long range rifle ~n~with medium accuracy"},
	{4, 	ITEM_TYPE_AMMO, 		2061, 		"Ammunition",           200, 		true,		{0.000000, 0.000000, 0.000000, 2.000000}, 		"Ammunition for firearms."},
	{5, 	ITEM_TYPE_WEAPON, 		344, 		"Molotov", 				5,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Homemade incendiary weapon."},
	{6, 	ITEM_TYPE_BODY, 		19142, 		"Armour", 				1,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Bulletproof vest."},
	{7, 	ITEM_TYPE_BACKPACK, 	3026, 		"Average Backpack",		1,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Backpack that increases your inventory."},
	{8, 	ITEM_TYPE_BACKPACK, 	3026, 		"Large Backpack",		1,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Backpack that increases your inventory."},
    {9, 	ITEM_TYPE_WEAPON, 		355, 		"AK-47", 				20, 		true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Long range rifle ~n~with medium accuracy."},
    {10, 	ITEM_TYPE_WEAPON, 		349, 		"Shotgun", 				20, 		true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Short range shotgun ~n~with a great firepower. ~N~~n~ Headshot enabled."},
    {11, 	ITEM_TYPE_MELEEWEAPON,	335, 		"Faca", 				1, 			true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Melee weapon"},
    {12, 	ITEM_TYPE_MELEEWEAPON,	334, 		"Hammock", 			    1, 			true,		{0.000000, -30.00000, 0.000000, 1.500000}, 		"Melee weapon."},
    {13, 	ITEM_TYPE_WEAPON, 		352, 		"Uzi", 					10, 		true,		{0.000000, -30.00000, 0.000000, 1.200000}, 		"Micro machine gun ~n~ two-handed.."},
    {14, 	ITEM_TYPE_WEAPON, 		347, 		"Usp", 					1, 			true,		{0.000000, -30.00000, 0.000000, 1.200000}, 		"Pistol with muffler. ~N~~n~~g~Headshot enabled."},
    {15, 	ITEM_TYPE_WEAPON, 		353, 		"MP5", 					20, 		true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Micro machine gun"},
    {16, 	ITEM_TYPE_WEAPON, 		358, 		"Sniper", 				5, 			true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Long-range rifle. ~N~~n~~g~Headshot enabled."},
    {17, 	ITEM_TYPE_WEAPON, 		342, 		"Granada", 				5,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"Explosive powerful."},
    {18, 	ITEM_TYPE_NORMAL, 		11738, 		"Medical kit", 			5,	 		true,		{0.000000, 0.000000, 0.000000, 1.000000}, 		"First aid kit ~n~that recovers your life."},
    {19, 	ITEM_TYPE_WEAPON, 		357, 		"Country rifle", 		20,	 		true,		{0.000000, -30.00000, 0.000000, 2.200000}, 		"Small range rifle ~n~with medium accuracy."}

};

new pInventory[MAX_PLAYERS][enum_pInventory];
new pCharacter[MAX_PLAYERS][enum_pCharacter];
new TdmSlotItems[MAX_ITEMS_SLOT][MAX_TDM_SLOTS][enum_TdmSlotItems];
new PlayerText:Inventory_index[MAX_PLAYERS][15];
new PlayerText:Inventory_skin[MAX_PLAYERS];
new PlayerText:Inventory_textos[MAX_PLAYERS][11];
new PlayerText:Inventory_description[MAX_PLAYERS][4];
new PlayerText:Inventory_personagemindex[MAX_PLAYERS][7];
new PlayerText:Inventory_mensagem[MAX_PLAYERS];
new Text:Inventory_usar;
new Text:Inventory_split[2];
new Text:Inventory_drop[2];
new Text:Inventory_close[2];
new Text:Inventory_backgrounds[5];
new Text:Inventory_remover;

new PubgTdm[MAX_TDM_SLOTS][tinfo], pInfo[MAX_PLAYERS][pinfo],
    String[500], PlayerText:KillTD[MAX_PLAYERS][2], GameTimer, LastItemID[MAX_TDM_SLOTS];
new PlayerText:KDSTATS[8][MAX_PLAYERS];
new Text:BlueBox[MAX_TDM_SLOTS];
new Text:RedBox[MAX_TDM_SLOTS];
new Text:OBJBOX[MAX_TDM_SLOTS];
new Text:TimeBOX[MAX_TDM_SLOTS];
new Text:BlueKills[MAX_TDM_SLOTS];
new Text:RedKills[MAX_TDM_SLOTS];
new Text:OBJTD[MAX_TDM_SLOTS];
new Text:TimeTD[MAX_TDM_SLOTS];
public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Pubg Tdm Loaded Version : Beta || Oblivion & Ninja");
	print("--------------------------------------\n");
	LoadDynamicObjects();
	CreateTextDraws();
	GameTimer = SetTimer("CalcScore", 1000, true);
	for(new i = 0; i < MAX_TDM_SLOTS; i++) LastItemID[i] = 0;
	return 1;
}


public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Pubg Tdm Unloaded Version : Beta || Oblivion & Ninja");
	print("--------------------------------------\n");

	KillTimer(GameTimer);

    for(new iq = 0; iq < MAX_TDM_SLOTS; iq++) DestroySlotAllItems(iq);

	return 1;
}

public OnPlayerConnect(playerid)
{
    CreateTextDrawPlayer(playerid);
	pInfo[playerid][InPTDM] = 0;
	pInfo[playerid][TeamID] = TEAMNONE;
	pInfo[playerid][Combo] = 0;
	pInfo[playerid][TotalCombo] = 0;
	pInfo[playerid][Kills] = 0;
    pInfo[playerid][Assists] = 0;
	pInfo[playerid][SlotID] = -1; // INVALID SLOT ID
	pInfo[playerid][ShowingkillTD] = false;

	ResetPlayerInventory(playerid);

    for(new i = 0; i < 10; i++)
	   	RemovePlayerAttachedObject(playerid, i);

    pInventory[playerid][invSelectedSlot] = -1;
    pCharacter[playerid][charSelectedSlot] = -1;
/*
    Testing of Radar (Since it needs SetPlayerColor) in Bare GM
    if you're using bare gm to test, uncoment this!
    switch(random(3))
    {
      case 0 : SetPlayerColor(playerid, 0xFFFF82FF);
      case 1 : SetPlayerColor(playerid, 0x5A00FFFF);
      case 2 : SetPlayerColor(playerid, 0x00FF00FF);
	}
	//
*/
	return 1;
}

//----------------- Command ----------------------
CMD:pubgtdm(playerid)
{
   if(pInfo[playerid][InPTDM] == 1) return SendError(playerid, "You are already in pubg tdm, /leave to exit the match");
   new line[900], line2[900];
   strcat(line2, "Slot\tType\tStatus\n");

   for(new i = 0; i < MAX_TDM_SLOTS; i++)
   {
		 if(PubgTdm[i][Active] == 1 && PubgTdm[i][Started] == 1)
		 {
		    format(line, sizeof(line), "#%i\tPUBG TDM\t{E65555}Match Ongoing\n", i+1);
		    strcat(line2, line);
		 }
		 else if(PubgTdm[i][Active] == 1 && PubgTdm[i][Started] == 0)
		 {
		 	format(line, sizeof(line), "#%i\tPUBG TDM\t{D2D2AB}Joinable\n", i+1);
		    strcat(line2, line);
		 }
		 else if(PubgTdm[i][Active] == 0 && PubgTdm[i][Started] == 0)
		 {
		    format(line, sizeof(line), "#%i\tPUBG TDM\t{3BBD44}Free\n", i+1);
		    strcat(line2, line);
		 }
   }
   ShowPlayerDialog(playerid, DIALOGID, DIALOG_STYLE_TABLIST_HEADERS, "PlayerUnknown's Battleground TDM", line2, "Play", "Cancel");
   return 1;
}
CMD:test(playerid)
{
  OnDialogResponse(playerid, 12, true, 0, " ");
  return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	 if(dialogid == DIALOGID)
	 {
			if(!response) return 1;
			if(listitem < 0 || listitem > MAX_TDM_SLOTS) return 1;
            // if this slot match is active and match is started, you can't join anymore
			if(PubgTdm[listitem][Active] == 1 && PubgTdm[listitem][Started] == 1)
								 return GameTextForPlayer(playerid, "~y~~h~Match Ongoing!", 3500, 3);
			if(_GetTdmPlayers(listitem) >= MAX_SLOT_PLAYERS) return GameTextForPlayer(playerid, "~y~~h~Slot is Full!", 3500, 3);

            SetPVarInt(playerid, "Color", GetPlayerColor(playerid)); // Storing Current Player Color
			pInfo[playerid][SlotID] = listitem;

			pInfo[playerid][InPTDM] = 1;
            ResetPlayerWeapons(playerid);
            // Just Reset
        	for(new s = 0, sj = MAX_INVENTORY_SLOTS; s < sj; s++)
			{
			   RemoveItemFromInventory(playerid, s);
			}
			for(new s1 = 0; s1 < 7; s1 ++)
			{
			   RemoveItemFromCharacter(playerid, s1);
			}
			HidePlayerInventory(playerid);
			SendClientMessage(playerid, -1, ""PUBGTDM1" Weapons are near your team area, Press F/Enter to pickup the weapon and 'Y' to open your inventories, Good luck Mate!");

			//
            // if this shot match is active for players to join and not yet started to reject player joins!
			if(PubgTdm[pInfo[playerid][SlotID]][Active] == 1 && PubgTdm[pInfo[playerid][SlotID]][Started] == 0) // Joinable
			{

	             if(PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers] <= PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers])
	             {
	                  PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers]++;
	                  pInfo[playerid][TeamID] = TEAMBLUE;
	                  SetPlayerTeam(playerid, pInfo[playerid][TeamID]);
	                  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
	                  SendClientMessage(playerid, -1,""PUBGTDM1" You have joined this round as "CBLUE"Blue "CWHITE"Team");
				 }
				 else if(PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers] <= PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers])
				 {
				      PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers]++;
	                  pInfo[playerid][TeamID] = TEAMRED;
	                  SetPlayerTeam(playerid, pInfo[playerid][TeamID]);
	                  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
	                  SendClientMessage(playerid, -1,""PUBGTDM1" You have joined this round as "CRED"RED "CWHITE"Team");
				 }
				 for(new i = 0; i < 8; i++) PlayerTextDrawShow(playerid, KDSTATS[i][playerid]);
				 TogglePlayerControllable(playerid, 0);
                 GlobalTextDraw(playerid, true, pInfo[playerid][SlotID]);
				 format(String, sizeof(String), ""PUBGTDM1" %s(%i) has joined pubg tdm as %s Team (Slot: %i)",_GetName(playerid), playerid, pInfo[playerid][TeamID] == 1 ? "Blue" : "Red", pInfo[playerid][SlotID]+1);
	             SendClientMessageToAll(-1, String);
				 return 1;
			}
			// if this slot is free and you can start a match on this slot
			if(PubgTdm[pInfo[playerid][SlotID]][Active] == 0 && PubgTdm[pInfo[playerid][SlotID]][Started] == 0) // Creating a new match
			{
		   		 if(PubgTdm[pInfo[playerid][SlotID]][Active] != 1)
		   		 {
					 format(String, sizeof(String), ""PUBGTDM1" Slot '%i' is now active, /pubgtdm to join the match", pInfo[playerid][SlotID]+1);
		             SendClientMessageToAll(-1, String);
				 }
				 PubgTdm[pInfo[playerid][SlotID]][Active] = 1;

	             if(PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers] <= PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers])
	             {
	                  PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers]++;
	                  pInfo[playerid][TeamID] = TEAMBLUE;
	                  SetPlayerTeam(playerid, pInfo[playerid][TeamID]);
	                  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
					  SendClientMessage(playerid,-1, ""PUBGTDM1" You have joined this round as "CBLUE"Blue "CWHITE"Team");
				 }
				 else if(PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers] <= PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers])
				 {
				      PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers]++;
	                  pInfo[playerid][TeamID] = TEAMRED;
	                  SetPlayerTeam(playerid, pInfo[playerid][TeamID]);
	                  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID] );
	                  SendClientMessage(playerid,-1, ""PUBGTDM1" You have joined this round as "CRED"RED "CWHITE"Team");
				 }
				 format(String, sizeof(String), ""PUBGTDM1" %s(%i) has joined pubg tdm as %s team (Slot: %i)",_GetName(playerid), playerid, pInfo[playerid][TeamID] == 1 ? "Blue" : "Red", pInfo[playerid][SlotID]+1);
	             SendClientMessageToAll(-1, String);
	             GlobalTextDraw(playerid, true, pInfo[playerid][SlotID]);
				 TogglePlayerControllable(playerid, 0);
				 for(new i = 0; i < 8; i++) PlayerTextDrawShow(playerid, KDSTATS[i][playerid]);
				 //
	             PubgTdm[pInfo[playerid][SlotID]][Count] = START_COUNT;
	             PubgTdm[pInfo[playerid][SlotID]][CountTimer] = SetTimerEx("StartMatch", 1000, true, "i", pInfo[playerid][SlotID]);
			     return 1;
			}
	 }
	 return false;
}

forward StartMatch(slotid);
public StartMatch(slotid)
{
        PubgTdm[slotid][Count] --;
		if(PubgTdm[slotid][Count] > 0)
		{
		      format(String, sizeof(String), "~w~Match Starts In ~g~~h~%i ~w~ Seconds",PubgTdm[slotid][Count]);
			  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid)
			  {
				   GameTextForPlayer(i, String, 5000, 4);
			  }
		}
		else if(PubgTdm[slotid][Count] <= 0)
		{
		       KillTimer(PubgTdm[slotid][CountTimer]);
			   if(_GetTdmPlayers(slotid) < MAX_TDM_PLAYERS)
			   {
	                  tdm_announce(""PUBGTDM2" This slot match is cancled!!", slotid);
	                  format(String, sizeof(String), ""PUBGTDM1"Pubg TDM Slot: '%i' match is cancled. No enough Players!", slotid+1);
					  SendClientMessageToAll(-1, String);
					  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid)
					  {
						   GameTextForPlayer(i, "~r~~h~Match Cancled", 3000, 3);
						   TogglePlayerControllable(i, 1);
                           ExitPlayerFromPubgTDM(i);
					  }
					  ResetSlotVariables(slotid);
			   }
			   else
			   {

					  format(String, sizeof(String), ""PUBGTDM1" Pubg TDM Slot: '%i' match is started! Good Luck Teams", slotid+1);
					  SendClientMessageToAll(-1, String);
					  PubgTdm[slotid][Started] = 1;
					  CreateTDMWeapons(slotid);
					  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid)
					  {
						   GameTextForPlayer(i, "~g~~h~Start Match", 3000, 3);
						   TogglePlayerControllable(i, 1);
						   SetCameraBehindPlayer(i);
					       PlayerPlaySound(i, 3200, 0, 0, 0);
					       SetPlayerHealth(i, 9999);
						   pInfo[i][pInvincibility] = 6;
			               pInfo[i][pInvincibilityTimer] = SetTimerEx("Invincibility", 1000, true, "i", i);

					  }
					  SetPlayerMarker(slotid);
					  tdm_announce(""PUBGTDM2" This sloth match is now started. Weapons are near your team base!", slotid);
					  PubgTdm[slotid][EndCount] = MAX_TIME;
		              PubgTdm[slotid][EndTimer] = SetTimerEx("EndMatch", 1000, true, "i", slotid);

			   }
		}
		return 1;
}

forward EndMatch(slotid);
public EndMatch(slotid)
{
  PubgTdm[slotid][EndCount]--;
  if(PubgTdm[slotid][EndCount] <= 0)
  {
	  tdm_announce(""PUBGTDM2" This slot match is ended! Time UP!", slotid);
	  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid)
	  {
		   GameTextForPlayer(i, "~r~~h~Match Cancled", 3000, 3);
           ExitPlayerFromPubgTDM(i);
	  }
	  ResetSlotVariables(slotid);
	  format(String, sizeof(String), ""PUBGTDM1" Pubg TDM Slot: '%i' match is ended. Time Up!", slotid+1);
	  SendClientMessageToAll(-1, String);
  }
  return 1;
}

CMD:leave(playerid)
{
   if(pInfo[playerid][InPTDM] == 0) return SendError(playerid, "You need to be pubg tdm to use this command");
   format(String, sizeof(String), ""PUBGTDM2" %s(%i) has left the match!", _GetName(playerid), playerid);
   tdm_announce(String, pInfo[playerid][SlotID]);
   if(pInfo[playerid][TeamID] == TEAMBLUE) PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers]--;
   else if(pInfo[playerid][TeamID] == TEAMRED) PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers]--;
   ExitPlayerFromPubgTDM(playerid);
   return 1;
}

ResetSlotVariables(slotid)
{
	  KillTimer(PubgTdm[slotid][EndTimer]);
      PubgTdm[slotid][EndTimer] = 0;
      PubgTdm[slotid][BlueTeamPlayers]=0;
      PubgTdm[slotid][RedTeamPlayers]=0;
      PubgTdm[slotid][Started] = 0;
      PubgTdm[slotid][Active] = 0;
      PubgTdm[slotid][RedTeamKills]=0;
      PubgTdm[slotid][BlueTeamKills]=0;
      DestroySlotAllItems(slotid);
}
ExitPlayerFromPubgTDM(playerid)
{
   GameTextForPlayer(playerid, " ", 1000,3); // hide
   ResetPlayerWeapons(playerid);
   for(new iz = 0; iz < 8; iz++) PlayerTextDrawHide(playerid, KDSTATS[iz][playerid]);
   for(new ii = 0; ii < 10; ii++) RemovePlayerAttachedObject(playerid, ii);
   GlobalTextDraw(playerid, false,  pInfo[playerid][SlotID]);
   for(new s = 0, sj = MAX_INVENTORY_SLOTS; s < sj; s++)
   {
	   RemoveItemFromInventory(playerid, s);
   }
   for(new s1 = 0; s1 < 7; s1 ++)
   {
	   RemoveItemFromCharacter(playerid, s1);
   }
   SetPlayerHealth(playerid, 100);
   KillTimer(pInfo[playerid][pInvincibilityTimer]);
   pInfo[playerid][InPTDM] = 0;
   SetPlayerTeam(playerid, 255);
   pInfo[playerid][TeamID] = TEAMNONE;
   pInfo[playerid][Kills] = 0;
   pInfo[playerid][SlotID] = -1; // INVALID SLOT ID
   pInfo[playerid][Assists] = 0;
   pInfo[playerid][Combo] = 0;
   pInfo[playerid][TotalCombo] = 0;
   SetPlayerVirtualWorld(playerid, 0);
   SetPlayerColor(playerid, GetPVarInt(playerid, "Color"));
   ResetPlayerInventory(playerid);
   HidePlayerInventory(playerid);
   foreach(new i : Player) if( i != playerid)
   {
      SetPlayerMarkerForPlayer(i, playerid, GetPlayerColor(playerid));
   }
   if(pInfo[playerid][MessageInventory])
	    KillTimer(pInfo[playerid][MessageInventoryTimer]);
   SpawnPlayer(playerid);

}

forward Float:GetPlayerArmourEx(playerid);
public Float:GetPlayerArmourEx(playerid)
{
	new Float:pColete;
	GetPlayerArmour(playerid, pColete);
	return Float:pColete;
}
public OnPlayerDisconnect(playerid, reason)
{
   if(pInfo[playerid][InPTDM] == 1)
   {
       format(String, sizeof(String), ""PUBGTDM2" %s(%i) has disconnected from the match!", _GetName(playerid), playerid);
	   tdm_announce(String, pInfo[playerid][SlotID]);
	   if(pInfo[playerid][TeamID] == TEAMBLUE) PubgTdm[pInfo[playerid][SlotID]][BlueTeamPlayers]--;
	   else if(pInfo[playerid][TeamID] == TEAMRED) PubgTdm[pInfo[playerid][SlotID]][RedTeamPlayers]--;
	   SetPlayerVirtualWorld(playerid, 0);
	   for(new iz = 0; iz < 8; iz++) PlayerTextDrawHide(playerid, KDSTATS[iz][playerid]);
	   for(new ii = 0; ii < 10; ii++) RemovePlayerAttachedObject(playerid, ii);
	   GlobalTextDraw(playerid, false,  pInfo[playerid][SlotID]);
	   SetPlayerTeam(playerid, 255);
	   pInfo[playerid][TeamID] = TEAMNONE;
	   GlobalTextDraw(playerid, false, pInfo[playerid][SlotID]);
	   pInfo[playerid][InPTDM] = 0;
	   pInfo[playerid][Kills] = 0;
	   pInfo[playerid][SlotID] = -1; // INVALID SLOT ID
	   pInfo[playerid][Assists] = 0;
	   pInfo[playerid][Combo] = 0;
       pInfo[playerid][TotalCombo] = 0;
       if(pInfo[playerid][MessageInventory])
	   KillTimer(pInfo[playerid][MessageInventoryTimer]);
   }
   return 1;
}


public OnPlayerSpawn(playerid)
{
    if(pInfo[playerid][InPTDM] == 1)
    {
		if(pInfo[playerid][TeamID] == TEAMBLUE)
		{
		  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
		}
		else if(pInfo[playerid][TeamID] == TEAMRED)
		{
		  SetPlayerTdmTeam(playerid, pInfo[playerid][SlotID], pInfo[playerid][TeamID] );
		}
		SetPlayerHealth(playerid, 9999);
		pInfo[playerid][pInvincibility] = 6;
		pInfo[playerid][pInvincibilityTimer] = SetTimerEx("Invincibility", 1000, true, "i", playerid);
		return 1;
    }
	return 1;
}


forward Invincibility(playerid);
public Invincibility(playerid)
{
  pInfo[playerid][pInvincibility]--;
  if(pInfo[playerid][pInvincibility] > 0)
  {
		  format(String, sizeof(String), "~y~~h~Invincibility Duration: ~g~~H~~h~%i",pInfo[playerid][pInvincibility]);
		  GameTextForPlayer(playerid, String, 5000, 3);
  }
  else
  {
    GameTextForPlayer(playerid, "~y~~h~Invincibility Duration Over", 1300, 3);
    SetPlayerHealth(playerid, 100);
	KillTimer(pInfo[playerid][pInvincibilityTimer]);
  }
  return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID)
	{
		  if(pInfo[killerid][InPTDM] == 1 && pInfo[playerid][InPTDM] == 1)
		  {
			   // Setting Killer
	           pInfo[killerid][Kills]++;

	           if(pInfo[killerid][TeamID] == TEAMRED) PubgTdm[pInfo[killerid][SlotID]][RedTeamKills]++;
	           else if(pInfo[killerid][TeamID] == TEAMBLUE) PubgTdm[pInfo[killerid][SlotID]][BlueTeamKills]++;
			   if(PubgTdm[pInfo[killerid][SlotID]][RedTeamKills] >= 1 && PubgTdm[pInfo[killerid][SlotID]][BlueTeamKills] == 0)
			   {
					 tdm_announce(""PUBGTDM2" Red team takes the first kill of the match", pInfo[killerid][SlotID]);
			   }
			   else if(PubgTdm[pInfo[killerid][SlotID]][RedTeamKills] == 0 && PubgTdm[pInfo[killerid][SlotID]][BlueTeamKills] >= 1)
			   {
			         tdm_announce(""PUBGTDM2" Blue team takes the first kill of the match", pInfo[killerid][SlotID]);
			   }

			   // --- KIllTD TextDraw For killer Team
			   new weapname[50], kstr[90], str1[300], str2[300], str3[300], str4[300];
			   GetWeaponName(GetPlayerWeapon(killerid), weapname, sizeof(weapname));
               if(!pInfo[killerid][ShowingkillTD])
               {
				   format(str1, sizeof(str1),"~w~You killed %s with %s", _GetName(killerid), _GetName(playerid), weapname);
				   format(kstr, sizeof(kstr),"~r~~h~%i Kills",pInfo[killerid][Kills]);
				   ShowPlayerKillTextDraw(killerid, str1, true, kstr);
			   }
			   foreach(new i : Player) if( pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == pInfo[killerid][SlotID] && pInfo[i][TeamID] ==  pInfo[killerid][TeamID] && i != killerid)
			   {
					  if(!pInfo[i][ShowingkillTD])
					  {
				          format(str2, sizeof(str2),"~w~Your teammate %s killed %s with %s", _GetName(killerid), _GetName(playerid), weapname);
				          ShowPlayerKillTextDraw(i, str2, false, "0");
					  }
			   }
			   // ===

			   // Combo System!
	           pInfo[killerid][Combo]++;
	           CheckPlayerCombo(killerid);
	           //==

	           // Setting Death Player ID
	           pInfo[playerid][Assists]++;
	           pInfo[playerid][Combo] = 0;
	           if(!pInfo[playerid][ShowingkillTD])
	           {
				   format(str3, sizeof(str3),"~w~     You were killed by %s with %s", _GetName(killerid), weapname);
				   ShowPlayerKillTextDraw(playerid, str3, false, "0");

			   }
			   foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == pInfo[playerid][SlotID] && pInfo[i][TeamID] ==  pInfo[playerid][TeamID] && i != playerid)
			   {
			          if(!pInfo[i][ShowingkillTD])
			          {
				          format(str4, sizeof(str4),"~w~Your teammate %s was killed by %s with %s", _GetName(playerid), _GetName(killerid), weapname);
				          ShowPlayerKillTextDraw(i, str4, false, "0");

					  }
			   }
			   // =====

	           // Setting Winner
	           if(PubgTdm[pInfo[killerid][SlotID]][RedTeamKills] >= MAX_OBJECTIVE)
	           {
                      format(String, sizeof(String), ""PUBGTDM1" Pubg TDM Slot: '%i', Red Team has won the match!", pInfo[killerid][SlotID]+1);
					  SendClientMessageToAll(-1, String);
                      tdm_teamannounce(""PUBGTDM2" Your team has won the match!", pInfo[killerid][SlotID], pInfo[killerid][TeamID]);
	                  new WMVP = GetHighestKill(pInfo[killerid][SlotID] , pInfo[killerid][TeamID]);
	                  new LMVP = GetHighestKill(pInfo[playerid][SlotID] , pInfo[playerid][TeamID]);

	                  format(String, sizeof(String),""PUBGTDM1" "CYELLOW"MOST VALUABLE PLAYER "CWHITE"'%s' with %i kills and %i combos from Red Team (Slot : %i | "CYELLOW"Winner)"
					  ,_GetName(WMVP),pInfo[WMVP][Kills],pInfo[WMVP][TotalCombo],pInfo[WMVP][SlotID]+1 );
					  SendClientMessageToAll(-1, String);

					  format(String, sizeof(String),""PUBGTDM1" {778899}MOST VALUABLE PLAYER "CWHITE"'%s' with %i kills and %i combos from Blue Team (Slot : %i | {778899}Lost)",
					  _GetName(LMVP),pInfo[LMVP][Kills],pInfo[LMVP][TotalCombo],pInfo[LMVP][SlotID]+1);
					  SendClientMessageToAll(-1, String);
					  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == pInfo[killerid][SlotID])
					  {
						   if(pInfo[i][TeamID] == TEAMRED)
						   {
								GivePlayerMoney(i, 10000);
								SetPlayerScore(i, GetPlayerScore(i)+10);
								GameTextForPlayer(i, "~g~~h~Won the Match", 4000, 3);
								ShowTeamResults(i, pInfo[killerid][SlotID], pInfo[killerid][TeamID]);
						   }
						   else if(pInfo[i][TeamID] == TEAMBLUE)
						   {
								GivePlayerMoney(i, 1600);
								SetPlayerScore(i, GetPlayerScore(i)+4);
		                        GameTextForPlayer(i, "~r~~h~Lost the Match", 4000, 3);
		                        ShowTeamResults(i,pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
						   }
						   ExitPlayerFromPubgTDM(i);
					  }
					  ResetSlotVariables(pInfo[killerid][SlotID]);
	           }
	           else if(PubgTdm[pInfo[killerid][SlotID]][BlueTeamKills] >= 40)
	           {
	                  format(String, sizeof(String), ""PUBGTDM1" Pubg TDM Slot: '%i', Blue Team has won the match!", pInfo[killerid][SlotID]+1);
					  SendClientMessageToAll(-1, String);
                      tdm_teamannounce(""PUBGTDM2" Your team has won the match!", pInfo[killerid][SlotID], pInfo[killerid][TeamID] );


	                  new WMVP = GetHighestKill(pInfo[killerid][SlotID] , pInfo[killerid][TeamID]);
	                  new LMVP = GetHighestKill(pInfo[playerid][SlotID] , pInfo[playerid][TeamID]);
	                  format(String, sizeof(String),""PUBGTDM1" "CYELLOW"MOST VALUABLE PLAYER "CWHITE"'%s' with %i kills and %i combos from Blue Team (Slot : %i | "CYELLOW"Winner)",
					  _GetName(WMVP),pInfo[WMVP][Kills],pInfo[WMVP][TotalCombo],pInfo[WMVP][SlotID]+1);
					  SendClientMessageToAll(-1, String);
					  format(String, sizeof(String),""PUBGTDM1" {778899}MOST VALUABLE PLAYER "CWHITE"'%s' with %i kills and %i combos from Red Team (Slot : %i | {778899}Lost))",
					  _GetName(LMVP),pInfo[LMVP][Kills],pInfo[LMVP][TotalCombo],pInfo[LMVP][SlotID]+1);
					  SendClientMessageToAll(-1, String);
					  foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == pInfo[killerid][SlotID])
					  {
						   if(pInfo[i][TeamID] == TEAMBLUE)
						   {
								GivePlayerMoney(i, 10000);
								SetPlayerScore(i, GetPlayerScore(i)+10);
								GameTextForPlayer(i, "~g~~h~Won the Match", 4000, 3);
								ShowTeamResults(i, pInfo[killerid][SlotID], pInfo[killerid][TeamID]);
						   }
						   else if(pInfo[i][TeamID] == TEAMRED)
						   {
								GivePlayerMoney(i, 1600);
								SetPlayerScore(i, GetPlayerScore(i)+4);
		                        GameTextForPlayer(i, "~r~~h~Lost the Match", 4000, 3);
		                        ShowTeamResults(i, pInfo[playerid][SlotID], pInfo[playerid][TeamID]);
						   }
						   ExitPlayerFromPubgTDM(i);
					  }
					  ResetSlotVariables(pInfo[killerid][SlotID]);
	           }

		  }
	}
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
    if(issuerid == INVALID_PLAYER_ID) return 1;

    if(pInfo[playerid][InPTDM] == 1)
    {
       if(bodypart == 9)
       {
         if(weaponid == 23 || weaponid == 24 || weaponid == 25 || weaponid == 34)
         {
  			if(pCharacter[playerid][charSlot][0] != 0) RemoveItemFromCharacter(playerid, 0);
			else SetPlayerHealth(playerid, 0.0);
		 }
	   }
    }
    return true;
}

public OnPlayerUpdate(playerid)
{
    if(pInfo[playerid][InPTDM] == 0) return 1;
    new weapons[13][2];
    new bool:have_fuzil = false;

    for(new s = 0; s <= 12; s++)
	    GetPlayerWeaponData(playerid, s, weapons[s][0], weapons[s][1]);

    for(new s = 3; s < 7; s ++)
    {
        if(weapons[8][0] == 18 && weapons[8][1] == 0)
        	if(pCharacter[playerid][charSlot][s] == 5)
		        RemoveItemFromCharacter(playerid, s);

    	if(weapons[8][0] == 16 && weapons[8][1] == 0)
			if(pCharacter[playerid][charSlot][s] == 17)
		        RemoveItemFromCharacter(playerid, s);

	    if(pCharacter[playerid][charSlot][s] == 3 || pCharacter[playerid][charSlot][s] == 9)
		{
		    new weaponid = GetWeaponIDFromModel(ItemsData[pCharacter[playerid][charSlot][s]][item_model]);

		    if(GetPlayerWeapon(playerid) != weaponid)
		        SetPlayerAttachedObject(playerid, 3, ItemsData[pCharacter[playerid][charSlot][s]][item_model], 1, 0.015999,-0.125999,-0.153000,0.000000,-22.700004,0.400000,1.000000,1.000000,1.000000);
		    else
		        RemovePlayerAttachedObject(playerid, 3);

			have_fuzil = true;
		}

		if(!have_fuzil && pCharacter[playerid][charSlot][s] == 16)
		{
	        new weaponid = GetWeaponIDFromModel(ItemsData[pCharacter[playerid][charSlot][s]][item_model]);

		    if(GetPlayerWeapon(playerid) != weaponid)
		        SetPlayerAttachedObject(playerid, 3, ItemsData[pCharacter[playerid][charSlot][s]][item_model], 1, 0.015999,-0.125999,-0.153000,0.000000,-22.700004,0.400000,1.000000,1.000000,1.000000);
		    else
		        RemovePlayerAttachedObject(playerid, 3);
		}

		if(pCharacter[playerid][charSlot][s] == 10)
		{
		    new weaponid = GetWeaponIDFromModel(ItemsData[pCharacter[playerid][charSlot][s]][item_model]);

		    if(GetPlayerWeapon(playerid) != weaponid)
		    	SetPlayerAttachedObject(playerid, 4, ItemsData[pCharacter[playerid][charSlot][s]][item_model],1,-0.032000,-0.127000,0.000999,20.600004,29.900007,-2.599998,1.000000,1.000000,1.000000);
		    else
		        RemovePlayerAttachedObject(playerid, 4);
		}

		if(pCharacter[playerid][charSlot][s] == 2)
		{
		    new weaponid = GetWeaponIDFromModel(ItemsData[pCharacter[playerid][charSlot][s]][item_model]);

		    if(GetPlayerWeapon(playerid) != weaponid)
				SetPlayerAttachedObject(playerid, 5, ItemsData[pCharacter[playerid][charSlot][s]][item_model],1,-0.053999,0.005999,-0.207000,67.899978,-177.600006,-0.400004,1.000000,1.000000,1.000000);
            else
		        RemovePlayerAttachedObject(playerid, 5);
		}

		new itemid = pCharacter[playerid][charSlot][s];
		if(ItemsData[itemid][item_type] == ITEM_TYPE_MELEEWEAPON)
		{
		    new weaponid = GetWeaponIDFromModel(ItemsData[pCharacter[playerid][charSlot][s]][item_model]);

		    if(GetPlayerWeapon(playerid) != weaponid)
                SetPlayerAttachedObject(playerid,6,ItemsData[pCharacter[playerid][charSlot][s]][item_model],1,-0.226999,-0.034999,0.211999,-97.999916,-88.000083,3.600018,1.000000,1.000000,1.000000);
			else
		        RemovePlayerAttachedObject(playerid, 6);
		}
	}

	return true;
}
public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == Text:INVALID_TEXT_DRAW)
	{
	    if(pInfo[playerid][inInventory])
	    	HidePlayerInventory(playerid);
	}
    else if(clickedid == Inventory_close[0]  && pInfo[playerid][InPTDM]== 1)
    {
        HidePlayerInventory(playerid);
    }
    else if(clickedid == Inventory_usar  && pInfo[playerid][InPTDM]== 1)
    {
        if(pInventory[playerid][invSelectedSlot] == -1)
            return 0;

		new slot = pInventory[playerid][invSelectedSlot];

		pInventory[playerid][invSelectedSlot] = -1;
        UseItem(playerid, slot, ItemsData[pInventory[playerid][invSlot][slot]][item_id]);
    }
    else if(clickedid == Inventory_split[0]  && pInfo[playerid][InPTDM]== 1)
    {
        if(pInventory[playerid][invSelectedSlot] == -1)
            return 0;

        if(IsInventoryFull(playerid))
			return ShowMessageInventory(playerid,"~r~ERROR: ~w~Your inventory is full.");

        new slot = pInventory[playerid][invSelectedSlot];

		if(pInventory[playerid][invSlotAmount][slot] == 1)
			return ShowMessageInventory(playerid, "~r~ERROR: ~w~You can't divide this item.");

        SplitItem(playerid, pInventory[playerid][invSelectedSlot]);
    }
    else if(clickedid == Inventory_drop[0]   && pInfo[playerid][InPTDM]== 1)
    {
        if(pInventory[playerid][invSelectedSlot] == -1)
            return 0;

        new slot = pInventory[playerid][invSelectedSlot];
        new itemid = pInventory[playerid][invSlot][slot];
        new amount = pInventory[playerid][invSlotAmount][slot];
        new Float:armourstatus = pInventory[playerid][invArmourStatus][slot];
		new Float:pos[3];

		if(!ItemsData[itemid][item_canbedropped])
		    return ShowMessageInventory(playerid, "~r~ERROR: ~w~You can't drop this item.");

		GetPlayerPos(playerid, pos[0], pos[1], pos[2]);

		if(itemid == 6)
			DropItem(pos[0], pos[1], pos[2], itemid, amount, armourstatus, pInfo[playerid][SlotID]);
		else
	    	DropItem(pos[0], pos[1], pos[2], itemid, amount,  0.0, pInfo[playerid][SlotID]);

		RemoveItemFromInventory(playerid, slot);

	   	for(new a = 0; a < 4; a++)
		   	PlayerTextDrawHide(playerid, Inventory_description[playerid][a]);

		TextDrawHideForPlayer(playerid, Inventory_backgrounds[4]);

		pInventory[playerid][invSelectedSlot] = -1;

    }
    else if(clickedid == Inventory_remover && pInfo[playerid][InPTDM]== 1)
    {
        if(pCharacter[playerid][charSelectedSlot] == -1)
            return 0;

  	    if(IsInventoryFull(playerid))
            return ShowMessageInventory(playerid, "~r~ERROR: ~w~Your inventory is full.");

        new selected = pCharacter[playerid][charSelectedSlot];

		if(selected == 2)
        	if(GetSlotsInUse(playerid) > 5)
        	    return ShowMessageInventory(playerid, "~r~ERROR: ~w~Clean your inventory.");

  		if(selected == 2)
        	if(GetSlotsInUse(playerid) >= 5)
        	    return ShowMessageInventory(playerid, "~r~ERROR: ~w~You don't have space in your inventory.");

        if(selected == 1)
            AddItem(playerid, pCharacter[playerid][charSlot][selected], 1, pCharacter[playerid][charArmourStatus]);
        else if(ItemsData[pCharacter[playerid][charSlot][selected]][item_id] == 5 || ItemsData[pCharacter[playerid][charSlot][selected]][item_id] == 17)
        {
	        new weapons[13][2];

	        for (new s = 0; s <= 12; s++)
			    GetPlayerWeaponData(playerid, s, weapons[s][0], weapons[s][1]);

            AddItem(playerid, pCharacter[playerid][charSlot][selected], weapons[8][1]);
		}
        else
        	AddItem(playerid, pCharacter[playerid][charSlot][selected], 1);

        RemoveItemFromCharacter(playerid, selected);

		pCharacter[playerid][charSelectedSlot] = -1;
    }

	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    	if(playertextid == Inventory_index[playerid][i] && pInfo[playerid][InPTDM]== 1)
    	{
    	    if(pInventory[playerid][invSlot][i] == 0)
    	        break;

    	    if(pInventory[playerid][invSelectedSlot] == i)
    	    {
    	        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][i], 96);
    	        pInventory[playerid][invSelectedSlot] = -1;
    	        PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);
				PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);

				for(new a = 0; a < 4; a++)
		    		PlayerTextDrawHide(playerid, Inventory_description[playerid][a]);

                TextDrawHideForPlayer(playerid, Inventory_backgrounds[4]);

               	TextDrawHideForPlayer(playerid, Inventory_usar);
				TextDrawHideForPlayer(playerid, Inventory_split[0]);
				TextDrawHideForPlayer(playerid, Inventory_split[1]);
				TextDrawHideForPlayer(playerid, Inventory_drop[0]);
				TextDrawHideForPlayer(playerid, Inventory_drop[1]);

				PlayerTextDrawHide(playerid, Inventory_textos[playerid][9]);

				break;
			}
			else if(pInventory[playerid][invSelectedSlot] != -1)
			{
    	        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][pInventory[playerid][invSelectedSlot]], 96);
    	        PlayerTextDrawHide(playerid, Inventory_index[playerid][pInventory[playerid][invSelectedSlot]]);
				PlayerTextDrawShow(playerid, Inventory_index[playerid][pInventory[playerid][invSelectedSlot]]);
			}

            PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][i], 0xFFFFFF50);

			PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);
			PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);

			// Descrição do Item

			PlayerTextDrawSetPreviewModel(playerid, Inventory_description[playerid][0], ItemsData[pInventory[playerid][invSlot][i]][item_model]);
            PlayerTextDrawSetPreviewRot(playerid, Inventory_description[playerid][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][3]);
            PlayerTextDrawShow(playerid, Inventory_description[playerid][0]);

			PlayerTextDrawSetString(playerid, Inventory_description[playerid][1], ConvertToGameText(ItemsData[pInventory[playerid][invSlot][i]][item_name]));
			PlayerTextDrawSetString(playerid, Inventory_description[playerid][2], ConvertToGameText(ItemsData[pInventory[playerid][invSlot][i]][item_description]));

			if(ItemsData[pInventory[playerid][invSlot][i]][item_type] == ITEM_TYPE_BODY)
			    format(String, sizeof(String), "Durability: %.1f", pInventory[playerid][invArmourStatus][i]);
			else if(pInventory[playerid][invSlotAmount][i] > 1)
				format(String, sizeof(String), "Amount: %d", pInventory[playerid][invSlotAmount][i]);
			else
				String = " ";

			PlayerTextDrawSetString(playerid, Inventory_description[playerid][3], String);

			if(pInventory[playerid][invSelectedSlot] == -1)
			{
	            TextDrawShowForPlayer(playerid, Inventory_usar);
			    TextDrawShowForPlayer(playerid, Inventory_split[0]);
			    TextDrawShowForPlayer(playerid, Inventory_split[1]);
			    TextDrawShowForPlayer(playerid, Inventory_drop[0]);
			    TextDrawShowForPlayer(playerid, Inventory_drop[1]);
			    PlayerTextDrawShow(playerid, Inventory_textos[playerid][9]);

			    for(new a = 0; a < 4; a++)
    				PlayerTextDrawShow(playerid, Inventory_description[playerid][a]);

                TextDrawShowForPlayer(playerid, Inventory_backgrounds[4]);
			}

		    pInventory[playerid][invSelectedSlot] = i;
			break;
    	}

    for(new i = 0; i < 7; i++)
    	if(playertextid == Inventory_personagemindex[playerid][i] && pInfo[playerid][InPTDM]== 1)
		{
		    if(pCharacter[playerid][charSlot][i] == 0)
    	        break;

		    if(pCharacter[playerid][charSelectedSlot] == i)
    	    {
    	        PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][i], 96);
    	        PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][i]);
				PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][i]);
    	        pCharacter[playerid][charSelectedSlot] = -1;

				PlayerTextDrawHide(playerid, Inventory_textos[playerid][10]);
				TextDrawHideForPlayer(playerid, Inventory_remover);
				break;
    	    }
    	    else if(pCharacter[playerid][charSelectedSlot] != -1)
    	    {
    	        new char_slot = pCharacter[playerid][charSelectedSlot];
    	        PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][char_slot], 96);
    	        PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][char_slot]);
				PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][char_slot]);
    	    }

		    PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][i], 0xFFFFFF50);
			PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][i]);
			PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][i]);

			if(pCharacter[playerid][charSelectedSlot] == -1)
			{
				PlayerTextDrawShow(playerid, Inventory_textos[playerid][10]);
				TextDrawShowForPlayer(playerid, Inventory_remover);
			}

			pCharacter[playerid][charSelectedSlot] = i;
			break;
		}

	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    if(pInfo[playerid][InPTDM] == 0) return 1;
	new bool:valid_shot = true;

    new ammu_slot = GetAmmunationSlot(playerid);

	if(ammu_slot == -1)
	{
	    for(new s = 3; s < 7; s ++)
    	    if(ItemsData[pCharacter[playerid][charSlot][s]][item_type] != ITEM_TYPE_MELEEWEAPON)
	    	    if(pCharacter[playerid][charSlot][s] != 0)
	    	    {
				    AddItem(playerid, pCharacter[playerid][charSlot][s], 1);
			    	RemoveItemFromCharacter(playerid, s);
				}

		return false;
	}

    pInventory[playerid][invSlotAmount][GetAmmunationSlot(playerid)] --;
	SetPlayerAmmo(playerid, weaponid, GetAmmunation(playerid));

	if(GetAmmunation(playerid) <= 0)
	    for(new s = 3; s < 7; s ++)
    	    if(ItemsData[pCharacter[playerid][charSlot][s]][item_type] != ITEM_TYPE_MELEEWEAPON)
	    	    if(pCharacter[playerid][charSlot][s] != 0)
	    	    {
				    AddItem(playerid, pCharacter[playerid][charSlot][s], 1);
			    	RemoveItemFromCharacter(playerid, s);
			    	valid_shot = false;
				}

	if(pInventory[playerid][invSlotAmount][ammu_slot] <= 0)
		RemoveItemFromInventory(playerid, ammu_slot);

	if(valid_shot == false)
		return false;

	return true;
}

public OnPlayerKeyStateChange(playerid,newkeys,oldkeys)
{
    if(newkeys == KEY_YES && pInfo[playerid][InPTDM] == 1 && !pInfo[playerid][inInventory]) ShowPlayerInventory(playerid);// Y to Open Inventry
    //
 	if(newkeys == KEY_SECONDARY_ATTACK && pInfo[playerid][InPTDM] == 1) //Alt to Take Weapon
    {
	   for(new its = 0; its < MAX_ITEMS_SLOT; its++)
	   {
            if(TdmSlotItems[its][pInfo[playerid][SlotID]][world_active])
            {

			       if(IsPlayerInRangeOfPoint(playerid, 2.0, TdmSlotItems[its][pInfo[playerid][SlotID]][world_position][0], TdmSlotItems[its][pInfo[playerid][SlotID]][world_position][1], TdmSlotItems[its][pInfo[playerid][SlotID]][world_position][2]))
		           {
				        new bool:sucess = false;

			            if(!IsInventoryFull(playerid))
			            {
			                AddItem(playerid, TdmSlotItems[its][pInfo[playerid][SlotID]][world_itemid], TdmSlotItems[its][pInfo[playerid][SlotID]][world_amount], TdmSlotItems[its][pInfo[playerid][SlotID]][world_armourstatus], true);
			                RemoveSlotItem(pInfo[playerid][SlotID], its);
			                sucess = true;
						}
						if(!sucess)
						{
			                for(new a = 0; a < GetSlotsInventory(playerid); a ++)
			                {
								if(pInventory[playerid][invSlot][a] == TdmSlotItems[its][pInfo[playerid][SlotID]][world_itemid])
								{
						            if(ItemsData[TdmSlotItems[its][pInfo[playerid][SlotID]][world_itemid]][item_limit] >= TdmSlotItems[its][pInfo[playerid][SlotID]][world_amount]+pInventory[playerid][invSlotAmount][a])
									{
									    AddItem(playerid, TdmSlotItems[its][pInfo[playerid][SlotID]][world_itemid], TdmSlotItems[its][pInfo[playerid][SlotID]][world_amount], TdmSlotItems[its][pInfo[playerid][SlotID]][world_armourstatus], true);
			               				RemoveSlotItem(pInfo[playerid][SlotID], its);
			               				sucess = true;
			                            break;
									}
							     }
							 }
						}
					    if(!sucess) ShowMessageInventory(playerid, "~r~ERROR: ~w~Your inventory is full.");
			            break;
				   }
			  }
	     }
    }
    return true;
}


forward CalcScore();
public CalcScore()
{
  new Bk[100], Rk[100], Time[100];
  new Pk[100], KDR[100], Assis[100];

  for(new iq = 0; iq < MAX_TDM_SLOTS; iq++) if(PubgTdm[iq][Started] == 1 && PubgTdm[iq][Active] == 1)
  {
		for(new its = 0; its < MAX_ITEMS_SLOT; its++)
		{
		  	    if(TdmSlotItems[its][iq][world_active])
		   		{
		     		TdmSlotItems[its][iq][world_timer]--;

		  			if(TdmSlotItems[its][iq][world_timer] == 0)
						RemoveSlotItem(iq, its);
				}
		}

		// Time
		format(Time, sizeof(Time), "~w~%s", TdmTimeConvert(PubgTdm[iq][EndCount]) );
		TextDrawSetString(TimeTD[iq], Time);

		 // Kills
	    format(Bk, sizeof(Bk),"~w~%i",PubgTdm[iq][BlueTeamKills]);
	    TextDrawSetString(BlueKills[iq], Bk);
	    format(Rk, sizeof(Rk), "~w~%i",PubgTdm[iq][RedTeamKills]);
	    TextDrawSetString(RedKills[iq], Rk);
  }
  foreach(new ii : Player) if(pInfo[ii][InPTDM] == 1)
  {
		format(Pk, sizeof(Pk), "%i", pInfo[ii][Kills]);
		PlayerTextDrawSetString(ii,KDSTATS[2][ii],Pk);

		format(Assis, sizeof(Assis), "%i", pInfo[ii][Assists]);
		PlayerTextDrawSetString(ii,KDSTATS[7][ii] ,Assis);

		if(pInfo[ii][Kills] != 0 && pInfo[ii][Assists] != 0) // If there is no kill or death by the player, it will maintain 0.0 variable!
		{
		    new Float:kdrt = Float:pInfo[ii][Kills]/Float:pInfo[ii][Assists];
			format(KDR, sizeof(KDR), "%0.1f", kdrt);
			PlayerTextDrawSetString(ii,KDSTATS[3][ii] ,KDR);
		}
		if(pCharacter[ii][charSlot][1] != 0)
		{
		    if(GetPlayerArmourEx(ii) > 0.0)
		         pCharacter[ii][charArmourStatus] = GetPlayerArmourEx(ii);
			else
			    RemoveItemFromCharacter(ii, 1);
		}
  }
  return 1;
}

//================== Functions ==============================


public OnPlayerStreamIn(playerid, forplayerid)
{
    if(pInfo[playerid][InPTDM] == 1  && pInfo[forplayerid][InPTDM] == 1)
    {
	    if(pInfo[forplayerid][SlotID] == pInfo[playerid][SlotID])
	    {
			if(pInfo[forplayerid][TeamID] != pInfo[playerid][TeamID])
			{
				SetPlayerMarkerForPlayer(forplayerid, playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
			}
		}
	}
    return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
    if(pInfo[playerid][InPTDM] == 1  && pInfo[forplayerid][InPTDM] == 1)
    {
	    if(pInfo[forplayerid][SlotID] == pInfo[playerid][SlotID])
	    {
			if(pInfo[forplayerid][TeamID] != pInfo[playerid][TeamID])
			{
				SetPlayerMarkerForPlayer(forplayerid,playerid, GetPlayerColor(playerid) & 0xFFFFFF00);
			}
		}
	}
	return 1;
}
stock SetPlayerMarker(slotid)
{
    foreach(new i : Player) // Blue Team
	{
		foreach(new x : Player) // Red Team
		{
		  if(pInfo[i][InPTDM] == 1 && pInfo[x][InPTDM] == 1 && pInfo[i][SlotID] == slotid && pInfo[x][SlotID] == slotid)
		  {
				if(pInfo[i][TeamID] != pInfo[x][TeamID])
				{
                    SetPlayerMarkerForPlayer(i, x , GetPlayerColor(x) & 0xFFFFFF00  );
				}
		   }
		}
	}
}

SetPlayerTdmTeam(playerid, slotid, team)
{
   switch(team)
   {
		  case TEAMBLUE:
		  {
				SetPlayerColor(playerid, COLOR_BLUE);
				SetPlayerVirtualWorld(playerid, slotid+2);
				switch(random(3))
				{
					case 0: SetPlayerPos(playerid,-1993.7507,1785.5057,1.8229+2);
					case 1: SetPlayerPos(playerid,-2010.9506,1800.7832,1.8651+2);
					case 2: SetPlayerPos(playerid,-2011.9891,1763.6718,1.8651+2);
				}
		  }
		  case TEAMRED:
		  {
		      SetPlayerColor(playerid, COLOR_RED);
		      SetPlayerVirtualWorld(playerid, slotid+2);
		      switch(random(3))
			  {
			  		case 0: SetPlayerPos(playerid,-2231.0483,1624.9036,1.7768+2);
					case 1: SetPlayerPos(playerid,-2226.0823,1619.0469,1.7768+2);
					case 2: SetPlayerPos(playerid,-2226.8953,1623.7335,1.7768+2);
			  }
		  }
   }
   return 1;
}

tdm_announce(const text[], slotid)
{
	foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid)
	{
	  SendClientMessage(i, -1, text);
	}
}

tdm_teamannounce(const text[], slotid, teamid)
{
	foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid && pInfo[i][TeamID] == teamid)
	{
	  SendClientMessage(i, -1, text);
	}
}

_GetName(playerid)
{
	new tmp[MAX_PLAYER_NAME + 1];
	GetPlayerName(playerid, tmp, sizeof(tmp));
	return tmp;
}

_GetTdmPlayers(slotid)
{
   new count = 0;
   foreach(new i : Player)
   {
     if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid) count++;
   }
   return count;
}
stock CheckPlayerCombo(playerid)
{
    if(pInfo[playerid][Combo] == 0) return 1;

	if(pInfo[playerid][Combo] > pInfo[playerid][TotalCombo] )
	{
		pInfo[playerid][TotalCombo] = pInfo[playerid][Combo];
	}
	switch(pInfo[playerid][Combo])
	{
		 case 3:
		 {
			 format(String, sizeof(String), ""PUBGTDM2" %s is legendary with %i combos",_GetName(playerid), pInfo[playerid][Combo]);
			 tdm_announce(String,pInfo[playerid][SlotID]);
			 GameTextForPlayer(playerid, "~y~~h~ You're Legendary", 3000, 3);
		 }
		 case 5:
		 {
			 format(String, sizeof(String), ""PUBGTDM2" %s is godlike with %i combos",_GetName(playerid), pInfo[playerid][Combo]);
			 tdm_announce(String,pInfo[playerid][SlotID]);
			 GameTextForPlayer(playerid, "~y~~h~ You're God", 3000, 3);
		 }
		 case 10:
		 {
		 	 format(String, sizeof(String), ""PUBGTDM2" %s is shitting on everyone with %i combos",_GetName(playerid), pInfo[playerid][Combo]);
			 tdm_announce(String,pInfo[playerid][SlotID]);
			 GameTextForPlayer(playerid, "~y~~h~ You're King", 3000, 3);

		 }
		 case 20:
		 {
		 	 format(String, sizeof(String), ""PUBGTDM2" %s is unstoppable with %i combos", _GetName(playerid), pInfo[playerid][Combo]);
			 tdm_announce(String,pInfo[playerid][SlotID]);
			 GameTextForPlayer(playerid, "~y~~h~ You're unstoppable", 3000, 3);

		 }
		 case 40:
		 {
		 	 format(String, sizeof(String), ""PUBGTDM1" %s landed the final blow! (Team : %s , Kills: %i, Combos: %i)",
			  _GetName(playerid), pInfo[playerid][TeamID] == 1 ? "BLUE" : "RED", pInfo[playerid][Kills],pInfo[playerid][TotalCombo]);
			 SendClientMessageToAll(-1,String);
			 format(String, sizeof(String),"~y~%s~w~ has landed the final blow!", _GetName(playerid));
			 foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == pInfo[playerid][SlotID]) GameTextForPlayer(i, String, 3000, 3);

		 }
    }
    return 1;
}
TdmTimeConvert(seconds)
{
	new etmp[16];
 	new minutes = floatround(seconds / 60);
  	seconds -= minutes * 60;
   	format(etmp, sizeof(etmp), "%i:%02i", minutes, seconds);
   	return etmp;
}
CreateTextDraws()
{
	for(new i = 0; i < MAX_TDM_SLOTS; i++)
	{
		BlueBox[i] = TextDrawCreate(275.600006, 18.673301, "usebox");
		TextDrawLetterSize(BlueBox[i], 0.000000, 4.355926);
		TextDrawTextSize(BlueBox[i], 209.999877, 0.000000);
		TextDrawAlignment(BlueBox[i], 1);
		TextDrawColor(BlueBox[i], 0);
		TextDrawUseBox(BlueBox[i], true);
		TextDrawBoxColor(BlueBox[i], 3666585);
		TextDrawSetShadow(BlueBox[i], 0);
		TextDrawSetOutline(BlueBox[i], 0);
		TextDrawBackgroundColor(BlueBox[i], 65332);
		TextDrawFont(BlueBox[i], 0);

		RedBox[i] = TextDrawCreate(402.799774, 18.673332, "usebox");
		TextDrawLetterSize(RedBox[i], 0.000000, 4.329257);
		TextDrawTextSize(RedBox[i], 337.999816, 0.000000);
		TextDrawAlignment(RedBox[i], 1);
		TextDrawColor(RedBox[i], 0);
		TextDrawUseBox(RedBox[i], true);
		TextDrawBoxColor(RedBox[i], 0xFF000050);
		TextDrawSetShadow(RedBox[i], 0);
		TextDrawSetOutline(RedBox[i], 0);
		TextDrawBackgroundColor(RedBox[i], -16777063);
		TextDrawFont(RedBox[i], 0);

		OBJBOX[i] = TextDrawCreate(344.399963, 18.673334, "usebox");
		TextDrawLetterSize(OBJBOX[i], 0.000000, 2.486294);
		TextDrawTextSize(OBJBOX[i], 269.199981, 0.000000);
		TextDrawAlignment(OBJBOX[i], 1);
		TextDrawColor(OBJBOX[i], 0);
		TextDrawUseBox(OBJBOX[i], true);
		TextDrawBoxColor(OBJBOX[i], -1448498825);
		TextDrawSetShadow(OBJBOX[i], 0);
		TextDrawSetOutline(OBJBOX[i], 0);
		TextDrawBackgroundColor(OBJBOX[i], -1448498859);
		TextDrawFont(OBJBOX[i], 0);

		TimeBOX[i] = TextDrawCreate(344.400085, 46.300029, "usebox");
		TextDrawLetterSize(TimeBOX[i], 0.000000, 1.304077);
		TextDrawTextSize(TimeBOX[i], 269.199981, 0.000000);
		TextDrawAlignment(TimeBOX[i], 1);
		TextDrawColor(TimeBOX[i], 0);
		TextDrawUseBox(TimeBOX[i], true);
		TextDrawBoxColor(TimeBOX[i], 102);
		TextDrawSetShadow(TimeBOX[i], 0);
		TextDrawSetOutline(TimeBOX[i], 0);
		TextDrawFont(TimeBOX[i], 0);

		BlueKills[i] = TextDrawCreate(226.399520, 24.640016, "0");
		TextDrawLetterSize(BlueKills[i], 0.773999, 3.227731);
		TextDrawAlignment(BlueKills[i], 1);
		TextDrawColor(BlueKills[i], -1);
		TextDrawSetShadow(BlueKills[i], 3);
		TextDrawSetOutline(BlueKills[i], 0);
		TextDrawBackgroundColor(BlueKills[i], 51);
		TextDrawFont(BlueKills[i], 1);
		TextDrawSetProportional(BlueKills[i], 1);

		RedKills[i] = TextDrawCreate(354.399993, 24.640016, "0");
		TextDrawLetterSize(RedKills[i], 0.773999, 3.227731);
		TextDrawAlignment(RedKills[i], 1);
		TextDrawColor(RedKills[i], -1);
		TextDrawSetShadow(RedKills[i], 3);
		TextDrawSetOutline(RedKills[i], 0);
		TextDrawBackgroundColor(RedKills[i], 51);
		TextDrawFont(RedKills[i], 1);
		TextDrawSetProportional(RedKills[i], 1);

		OBJTD[i] = TextDrawCreate(276.799957, 23.146675, "Objective: "#MAX_OBJECTIVE"");
		TextDrawLetterSize(OBJTD[i], 0.253998, 1.487998);
		TextDrawAlignment(OBJTD[i], 1);
		TextDrawColor(OBJTD[i], -1);
		TextDrawSetShadow(OBJTD[i], 0);
		TextDrawSetOutline(OBJTD[i], 1);
		TextDrawBackgroundColor(OBJTD[i], 51);
		TextDrawFont(OBJTD[i], 1);
		TextDrawSetProportional(OBJTD[i], 1);

		TimeTD[i] = TextDrawCreate(285.800018, 45.546653, "10:00");
		TextDrawLetterSize(TimeTD[i], 0.457998, 1.435733);
		TextDrawAlignment(TimeTD[i], 1);
		TextDrawColor(TimeTD[i], -1);
		TextDrawSetShadow(TimeTD[i], 0);
		TextDrawSetOutline(TimeTD[i], 1);
		TextDrawBackgroundColor(TimeTD[i], 51);
		TextDrawFont(TimeTD[i], 1);
		TextDrawSetProportional(TimeTD[i], 1);
    }
    Inventory_backgrounds[0] = TextDrawCreate(63.900207, 120.000030, "box");
	TextDrawLetterSize(Inventory_backgrounds[0], 0.000000, 28.450004);
	TextDrawTextSize(Inventory_backgrounds[0], 308.250335, 0.000000);
	TextDrawAlignment(Inventory_backgrounds[0], 1);
	TextDrawColor(Inventory_backgrounds[0], -1);
	TextDrawUseBox(Inventory_backgrounds[0], 1);
	TextDrawBoxColor(Inventory_backgrounds[0], 128);
	TextDrawSetShadow(Inventory_backgrounds[0], 0);
	TextDrawSetOutline(Inventory_backgrounds[0], 0);
	TextDrawBackgroundColor(Inventory_backgrounds[0], 255);
	TextDrawFont(Inventory_backgrounds[0], 2);
	TextDrawSetProportional(Inventory_backgrounds[0], 1);
	TextDrawSetShadow(Inventory_backgrounds[0], 0);

	Inventory_backgrounds[1] = TextDrawCreate(313.099792, 120.000030, "box");
	TextDrawLetterSize(Inventory_backgrounds[1], 0.000000, 28.450004);
	TextDrawTextSize(Inventory_backgrounds[1], 578.247741, 0.000000);
	TextDrawAlignment(Inventory_backgrounds[1], 1);
	TextDrawColor(Inventory_backgrounds[1], -1);
	TextDrawUseBox(Inventory_backgrounds[1], 1);
	TextDrawBoxColor(Inventory_backgrounds[1], 128);
	TextDrawSetShadow(Inventory_backgrounds[1], 0);
	TextDrawSetOutline(Inventory_backgrounds[1], 0);
	TextDrawBackgroundColor(Inventory_backgrounds[1], 255);
	TextDrawFont(Inventory_backgrounds[1], 1);
	TextDrawSetProportional(Inventory_backgrounds[1], 1);
	TextDrawSetShadow(Inventory_backgrounds[1], 0);

	Inventory_backgrounds[2] = TextDrawCreate(66.100158, 122.233367, "box");
	TextDrawLetterSize(Inventory_backgrounds[2], 0.000000, 1.200001);
	TextDrawTextSize(Inventory_backgrounds[2], 306.499542, 0.000000);
	TextDrawAlignment(Inventory_backgrounds[2], 1);
	TextDrawColor(Inventory_backgrounds[2], -1);
	TextDrawUseBox(Inventory_backgrounds[2], 1);
	TextDrawBoxColor(Inventory_backgrounds[2], 128);
	TextDrawSetShadow(Inventory_backgrounds[2], 0);
	TextDrawSetOutline(Inventory_backgrounds[2], 0);
	TextDrawBackgroundColor(Inventory_backgrounds[2], 255);
	TextDrawFont(Inventory_backgrounds[2], 1);
	TextDrawSetProportional(Inventory_backgrounds[2], 1);
	TextDrawSetShadow(Inventory_backgrounds[2], 0);

	Inventory_backgrounds[3] = TextDrawCreate(314.599426, 122.233375, "box");
	TextDrawLetterSize(Inventory_backgrounds[3], 0.000000, 1.200001);
	TextDrawTextSize(Inventory_backgrounds[3], 576.602294, 0.000000);
	TextDrawAlignment(Inventory_backgrounds[3], 1);
	TextDrawColor(Inventory_backgrounds[3], -1);
	TextDrawUseBox(Inventory_backgrounds[3], 1);
	TextDrawBoxColor(Inventory_backgrounds[3], 128);
	TextDrawSetShadow(Inventory_backgrounds[3], 0);
	TextDrawSetOutline(Inventory_backgrounds[3], 0);
	TextDrawBackgroundColor(Inventory_backgrounds[3], 255);
	TextDrawFont(Inventory_backgrounds[3], 1);
	TextDrawSetProportional(Inventory_backgrounds[3], 1);
	TextDrawSetShadow(Inventory_backgrounds[3], 0);

	Inventory_backgrounds[4] = TextDrawCreate(317.000000, 314.434112, "box");
	TextDrawLetterSize(Inventory_backgrounds[4], 0.000000, 6.285005);
	TextDrawTextSize(Inventory_backgrounds[4], 499.247772, 0.000000);
	TextDrawAlignment(Inventory_backgrounds[4], 1);
	TextDrawColor(Inventory_backgrounds[4], -1);
	TextDrawUseBox(Inventory_backgrounds[4], 1);
	TextDrawBoxColor(Inventory_backgrounds[4], 128);
	TextDrawSetShadow(Inventory_backgrounds[4], 0);
	TextDrawSetOutline(Inventory_backgrounds[4], 0);
	TextDrawBackgroundColor(Inventory_backgrounds[4], 255);
	TextDrawFont(Inventory_backgrounds[4], 1);
	TextDrawSetProportional(Inventory_backgrounds[4], 1);
	TextDrawSetShadow(Inventory_backgrounds[4], 0);

    Inventory_usar = TextDrawCreate(504.388427, 312.249938, "");
	TextDrawLetterSize(Inventory_usar, 0.000000, 0.000000);
	TextDrawTextSize(Inventory_usar, 71.019790, 18.579967);
	TextDrawAlignment(Inventory_usar, 1);
	TextDrawColor(Inventory_usar, -1);
	TextDrawSetShadow(Inventory_usar, 0);
	TextDrawSetOutline(Inventory_usar, 0);
	TextDrawBackgroundColor(Inventory_usar, 866792304);
	TextDrawFont(Inventory_usar, 5);
	TextDrawSetProportional(Inventory_usar, 0);
	TextDrawSetShadow(Inventory_usar, 0);
	TextDrawSetPreviewModel(Inventory_usar, 19382);
	TextDrawSetPreviewRot(Inventory_usar, 0.000000, 0.000000, 0.000000, 1.000000);
	TextDrawSetSelectable(Inventory_usar, true);

    Inventory_split[0] = TextDrawCreate(504.593688, 333.316314, "");
	TextDrawLetterSize(Inventory_split[0], 0.000000, 0.000000);
	TextDrawTextSize(Inventory_split[0], 71.019790, 18.579967);
	TextDrawAlignment(Inventory_split[0], 1);
	TextDrawColor(Inventory_split[0], -1);
	TextDrawSetShadow(Inventory_split[0], 0);
	TextDrawSetOutline(Inventory_split[0], 0);
	TextDrawBackgroundColor(Inventory_split[0], -65472);
	TextDrawFont(Inventory_split[0], 5);
	TextDrawSetProportional(Inventory_split[0], 0);
	TextDrawSetShadow(Inventory_split[0], 0);
	TextDrawSetSelectable(Inventory_split[0], true);
	TextDrawSetPreviewModel(Inventory_split[0], 19382);
	TextDrawSetPreviewRot(Inventory_split[0], 0.000000, 0.000000, 0.000000, 1.000000);

    Inventory_drop[0] = TextDrawCreate(504.793701, 354.617614, "");
	TextDrawLetterSize(Inventory_drop[0], 0.000000, 0.000000);
	TextDrawTextSize(Inventory_drop[0], 71.019790, 18.579967);
	TextDrawAlignment(Inventory_drop[0], 1);
	TextDrawColor(Inventory_drop[0], -1);
	TextDrawSetShadow(Inventory_drop[0], 0);
	TextDrawSetOutline(Inventory_drop[0], 0);
	TextDrawBackgroundColor(Inventory_drop[0], 0xAA333370);
	TextDrawFont(Inventory_drop[0], 5);
	TextDrawSetProportional(Inventory_drop[0], 0);
	TextDrawSetShadow(Inventory_drop[0], 0);
	TextDrawSetSelectable(Inventory_drop[0], true);
	TextDrawSetPreviewModel(Inventory_drop[0], 19382);
	TextDrawSetPreviewRot(Inventory_drop[0], 0.000000, 0.000000, 0.000000, 1.000000);

	Inventory_remover = TextDrawCreate(149.847900, 344.867553, "");
	TextDrawLetterSize(Inventory_remover, 0.000000, 0.000000);
	TextDrawTextSize(Inventory_remover, 76.040008, 19.899997);
	TextDrawAlignment(Inventory_remover, 1);
	TextDrawColor(Inventory_remover, -1);
	TextDrawSetShadow(Inventory_remover, 0);
	TextDrawSetOutline(Inventory_remover, 0);
	TextDrawBackgroundColor(Inventory_remover, 0xAA333370);
	TextDrawFont(Inventory_remover, 5);
	TextDrawSetProportional(Inventory_remover, 0);
	TextDrawSetShadow(Inventory_remover, 0);
	TextDrawSetSelectable(Inventory_remover, true);
	TextDrawSetPreviewModel(Inventory_remover, 19382);
	TextDrawSetPreviewRot(Inventory_remover, 0.000000, 0.000000, 0.000000, 1.000000);

	Inventory_split[1] = TextDrawCreate(540.294372, 334.449981, "split");
	TextDrawLetterSize(Inventory_split[1], 0.400000, 1.600000);
	TextDrawAlignment(Inventory_split[1], 2);
	TextDrawColor(Inventory_split[1], -1);
	TextDrawSetShadow(Inventory_split[1], 0);
	TextDrawSetOutline(Inventory_split[1], 0);
	TextDrawBackgroundColor(Inventory_split[1], 255);
	TextDrawFont(Inventory_split[1], 2);
	TextDrawSetProportional(Inventory_split[1], 1);
	TextDrawSetShadow(Inventory_split[1], 0);
	TextDrawSetSelectable(Inventory_split[1], false);

	Inventory_drop[1] = TextDrawCreate(540.762878, 355.451263, "drop");
	TextDrawLetterSize(Inventory_drop[1], 0.400000, 1.600000);
	TextDrawAlignment(Inventory_drop[1], 2);
	TextDrawColor(Inventory_drop[1], -1);
	TextDrawSetShadow(Inventory_drop[1], 0);
	TextDrawSetOutline(Inventory_drop[1], 0);
	TextDrawBackgroundColor(Inventory_drop[1], 255);
	TextDrawFont(Inventory_drop[1], 2);
	TextDrawSetProportional(Inventory_drop[1], 1);
	TextDrawSetShadow(Inventory_drop[1], 0);
	TextDrawSetSelectable(Inventory_drop[1], false);

	Inventory_close[1] = TextDrawCreate(565.100341, 119.433311, "X");
	TextDrawTextSize(Inventory_close[1], 574.999511, 0.000000);
	TextDrawLetterSize(Inventory_close[1], 0.400000, 1.600000);
	TextDrawAlignment(Inventory_close[1], 1);
	TextDrawColor(Inventory_close[1], -1);
	TextDrawSetShadow(Inventory_close[1], 0);
	TextDrawSetOutline(Inventory_close[1], 0);
	TextDrawBackgroundColor(Inventory_close[1], 255);
	TextDrawFont(Inventory_close[1], 2);
	TextDrawSetProportional(Inventory_close[1], 1);
	TextDrawSetShadow(Inventory_close[1], 0);
	TextDrawSetSelectable(Inventory_close[1], true);

	Inventory_close[0] = TextDrawCreate(564.079284, 120.583320, "");
	TextDrawLetterSize(Inventory_close[0], 0.000000, 0.000000);
	TextDrawTextSize(Inventory_close[0], 14.000000, 14.000000);
	TextDrawAlignment(Inventory_close[0], 1);
	TextDrawColor(Inventory_close[0], -1);
	TextDrawSetShadow(Inventory_close[0], 0);
	TextDrawSetOutline(Inventory_close[0], 0);
	TextDrawBackgroundColor(Inventory_close[0], 80);
	TextDrawFont(Inventory_close[0], 5);
	TextDrawSetProportional(Inventory_close[0], 0);
	TextDrawSetShadow(Inventory_close[0], 0);
	TextDrawSetSelectable(Inventory_close[0], true);
	TextDrawSetPreviewModel(Inventory_close[0], 19382);
	TextDrawSetPreviewRot(Inventory_close[0], 0.000000, 0.000000, 0.000000, 1.000000);
}
stock ShowTeamResults(playerid, slotid, teamid)
{
	  new showr[700], count[MAX_TDM_SLOTS] = 0;
	  SendClientMessage(playerid, -1, ""PUBGTDM1" Showing results of your team performance:");
	  foreach(new  ii : Player) if(pInfo[ii][InPTDM] == 1 && pInfo[ii][SlotID] == slotid && pInfo[ii][TeamID] == teamid)
	  {
		    format(showr, sizeof(showr), ""CYELLOW"%d. "CWHITE"%s - Kills: %i | K/D: %0.1f | Assists: %i | Combos: %i "CYELLOW"%s \n",count[slotid]+1,_GetName(ii),
		    pInfo[ii][Kills], Float:pInfo[ii][Kills]/Float:pInfo[ii][Assists], pInfo[ii][Assists],pInfo[ii][TotalCombo], GetHighestKill(slotid, teamid) == ii ? "(MVP)" : " ");
			count[slotid]++;
  	        SendClientMessage(playerid, -1, showr);
	  }
}

CreateTextDrawPlayer(playerid)
{

		KillTD[playerid][0] = CreatePlayerTextDraw(playerid, 201.200012, 290.800048, "-");
		PlayerTextDrawLetterSize(playerid, KillTD[playerid][0], 0.255199, 1.428266);
		PlayerTextDrawTextSize(playerid, KillTD[playerid][0], 468.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KillTD[playerid][0], 1);
		PlayerTextDrawColor(playerid, KillTD[playerid][0], -1);
		PlayerTextDrawUseBox(playerid, KillTD[playerid][0], 1);
		PlayerTextDrawBoxColor(playerid, KillTD[playerid][0], 86);
		PlayerTextDrawSetShadow(playerid, KillTD[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, KillTD[playerid][0], 1);
		PlayerTextDrawBackgroundColor(playerid, KillTD[playerid][0], 255);
		PlayerTextDrawFont(playerid, KillTD[playerid][0], 1);
		PlayerTextDrawSetProportional(playerid, KillTD[playerid][0], 1);
		PlayerTextDrawSetShadow(playerid, KillTD[playerid][0], 0);

		KillTD[playerid][1] = CreatePlayerTextDraw(playerid, 296.399993, 319.920104, "1 kills");
		PlayerTextDrawLetterSize(playerid, KillTD[playerid][1], 0.462399, 2.324266);
		PlayerTextDrawAlignment(playerid, KillTD[playerid][1], 1);
		PlayerTextDrawColor(playerid, KillTD[playerid][1], -1);
		PlayerTextDrawSetShadow(playerid, KillTD[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, KillTD[playerid][1], 0);
		PlayerTextDrawBackgroundColor(playerid, KillTD[playerid][1], 255);
		PlayerTextDrawFont(playerid, KillTD[playerid][1], 1);
		PlayerTextDrawSetProportional(playerid, KillTD[playerid][1], 1);
		PlayerTextDrawSetShadow(playerid, KillTD[playerid][1], 0);

		KDSTATS[0][playerid] = CreatePlayerTextDraw(playerid, 447.400024, -10.760006, "");
		PlayerTextDrawLetterSize(playerid, KDSTATS[0][playerid], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, KDSTATS[0][playerid], 49.000000, 55.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[0][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[0][playerid], -1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[0][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[0][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[0][playerid], -16777216);
		PlayerTextDrawFont(playerid, KDSTATS[0][playerid], 5);
		PlayerTextDrawSetProportional(playerid, KDSTATS[0][playerid], 0);
		PlayerTextDrawSetShadow(playerid, KDSTATS[0][playerid], 0);
		PlayerTextDrawSetPreviewModel(playerid, KDSTATS[0][playerid], 346);
		PlayerTextDrawSetPreviewRot(playerid, KDSTATS[0][playerid], 0.000000, 0.000000, 200.000000, 1.000000);

		KDSTATS[1][playerid] = CreatePlayerTextDraw(playerid,469.200012, 7.813347, "box");
		PlayerTextDrawLetterSize(playerid, KDSTATS[1][playerid], 0.000000, 1.279999);
		PlayerTextDrawTextSize(playerid, KDSTATS[1][playerid], 486.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[1][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[1][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[1][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[1][playerid], 102);
		PlayerTextDrawSetShadow(playerid, KDSTATS[1][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[1][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[1][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[1][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[1][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[1][playerid], 0);

		KDSTATS[2][playerid] = CreatePlayerTextDraw(playerid,492.400054, 7.813323, "0");
		PlayerTextDrawLetterSize(playerid, KDSTATS[2][playerid], 0.398400, 1.263999);
		PlayerTextDrawTextSize(playerid, KDSTATS[2][playerid], 510.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[2][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[2][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[2][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[2][playerid], 255);
		PlayerTextDrawSetShadow(playerid, KDSTATS[2][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[2][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[2][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[2][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[2][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[2][playerid], 0);

		KDSTATS[3][playerid] = CreatePlayerTextDraw(playerid,553.199584, 7.813323, "0.0");
		PlayerTextDrawLetterSize(playerid, KDSTATS[3][playerid], 0.398400, 1.263999);
		PlayerTextDrawTextSize(playerid, KDSTATS[3][playerid], 573.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[3][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[3][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[3][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[3][playerid], 255);
		PlayerTextDrawSetShadow(playerid, KDSTATS[3][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[3][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[3][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[3][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[3][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[3][playerid], 0);

		KDSTATS[4][playerid] = CreatePlayerTextDraw(playerid,525.199707, 7.813323, "K/D");
		PlayerTextDrawLetterSize(playerid, KDSTATS[4][playerid], 0.398400, 1.263999);
		PlayerTextDrawTextSize(playerid, KDSTATS[4][playerid], 548.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[4][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[4][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[4][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[4][playerid], 102);
		PlayerTextDrawSetShadow(playerid, KDSTATS[4][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[4][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[4][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[4][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[4][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[4][playerid], 0);

		KDSTATS[5][playerid] = CreatePlayerTextDraw(playerid,559.798156, -12.533342, "");
		PlayerTextDrawLetterSize(playerid, KDSTATS[5][playerid], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, KDSTATS[5][playerid], 49.000000, 55.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[5][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[5][playerid], -1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[5][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[5][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[5][playerid], -16777216);
		PlayerTextDrawFont(playerid, KDSTATS[5][playerid], 5);
		PlayerTextDrawSetProportional(playerid, KDSTATS[5][playerid], 0);
		PlayerTextDrawSetShadow(playerid, KDSTATS[5][playerid], 0);
		PlayerTextDrawSetPreviewModel(playerid, KDSTATS[5][playerid], 331);
		PlayerTextDrawSetPreviewRot(playerid, KDSTATS[5][playerid], 0.000000, 0.000000, 200.000000, 1.000000);

		KDSTATS[6][playerid] = CreatePlayerTextDraw(playerid,585.200012, 8.560013, "box");
		PlayerTextDrawLetterSize(playerid, KDSTATS[6][playerid], 0.000000, 1.279999);
		PlayerTextDrawTextSize(playerid, KDSTATS[6][playerid], 600.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[6][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[6][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[6][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[6][playerid], 102);
		PlayerTextDrawSetShadow(playerid, KDSTATS[6][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[6][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[6][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[6][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[6][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[6][playerid], 0);

		KDSTATS[7][playerid] = CreatePlayerTextDraw(playerid,605.199401, 8.559988, "0");
		PlayerTextDrawLetterSize(playerid, KDSTATS[7][playerid], 0.398400, 1.263999);
		PlayerTextDrawTextSize(playerid, KDSTATS[7][playerid], 624.000000, 0.000000);
		PlayerTextDrawAlignment(playerid, KDSTATS[7][playerid], 1);
		PlayerTextDrawColor(playerid, KDSTATS[7][playerid], -1);
		PlayerTextDrawUseBox(playerid, KDSTATS[7][playerid], 1);
		PlayerTextDrawBoxColor(playerid, KDSTATS[7][playerid], 255);
		PlayerTextDrawSetShadow(playerid, KDSTATS[7][playerid], 0);
		PlayerTextDrawSetOutline(playerid, KDSTATS[7][playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, KDSTATS[7][playerid], 255);
		PlayerTextDrawFont(playerid, KDSTATS[7][playerid], 1);
		PlayerTextDrawSetProportional(playerid, KDSTATS[7][playerid], 1);
		PlayerTextDrawSetShadow(playerid, KDSTATS[7][playerid], 0);

		Inventory_index[playerid][0] = CreatePlayerTextDraw(playerid, 315.500152, 150.692352, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][0], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][0], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][0], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][0], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][0], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][0], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][0], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][0], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][0], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][0], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][0], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][0], 0.000000, -30, 0.000000, 2.2);

		Inventory_index[playerid][1] = CreatePlayerTextDraw(playerid, 368.803405, 150.692352, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][1], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][1], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][1], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][1], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][1], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][1], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][1], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][1], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][1], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][1], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][1], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][1], 0.000000, -30, 0.000000, 2.2);

	    Inventory_index[playerid][10] = CreatePlayerTextDraw(playerid, 315.500152, 253.698638, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][10], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][10], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][10], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][10], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][10], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][10], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][10], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][10], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][10], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][10], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][10], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][10], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][10], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][5] = CreatePlayerTextDraw(playerid, 315.500152, 201.795471, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][5], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][5], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][5], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][5], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][5], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][5], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][5], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][5], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][5], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][5], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][5], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][5], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][5], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][2] = CreatePlayerTextDraw(playerid, 422.506683, 150.692352, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][2], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][2], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][2], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][2], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][2], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][2], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][2], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][2], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][2], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][2], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][2], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][2], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][2], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][3] = CreatePlayerTextDraw(playerid, 475.509918, 150.692352, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][3], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][3], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][3], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][3], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][3], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][3], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][3], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][3], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][3], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][3], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][3], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][3], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][3], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][4] = CreatePlayerTextDraw(playerid, 528.508117, 150.692352, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][4], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][4], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][4], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][4], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][4], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][4], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][4], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][4], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][4], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][4], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][4], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][4], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][4], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][6] = CreatePlayerTextDraw(playerid, 368.903411, 201.795471, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][6], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][6], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][6], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][6], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][6], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][6], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][6], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][6], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][6], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][6], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][6], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][6], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][6], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][7] = CreatePlayerTextDraw(playerid, 422.406677, 201.795471, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][7], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][7], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][7], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][7], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][7], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][7], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][7], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][7], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][7], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][7], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][7], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][7], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][7], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][8] = CreatePlayerTextDraw(playerid, 476.009948, 201.795471, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][8], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][8], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][8], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][8], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][8], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][8], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][8], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][8], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][8], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][8], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][8], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][8], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][8], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][9] = CreatePlayerTextDraw(playerid, 528.908020, 201.795471, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][9], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][9], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][9], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][9], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][9], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][9], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][9], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][9], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][9], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][9], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][9], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][9], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][9], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][11] = CreatePlayerTextDraw(playerid, 369.203430, 253.698638, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][11], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][11], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][11], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][11], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][11], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][11], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][11], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][11], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][11], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][11], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][11], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][11], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][11], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][12] = CreatePlayerTextDraw(playerid, 422.806701, 253.698638, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][12] , 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][12] , 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][12] , 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][12] , -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][12] , 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][12] , 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][12], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][12], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][12], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][12], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][12], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][12], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][12], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][13] = CreatePlayerTextDraw(playerid, 476.209960, 253.698638, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][13], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][13], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][13], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][13], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][13], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][13], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][13], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][13], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][13], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][13], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][13], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][13], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][13], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_index[playerid][14] = CreatePlayerTextDraw(playerid, 529.507873, 253.698638, "");
		PlayerTextDrawLetterSize(playerid, Inventory_index[playerid][14], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_index[playerid][14], 46.000000, 45.000000);
		PlayerTextDrawAlignment(playerid, Inventory_index[playerid][14], 1);
		PlayerTextDrawColor(playerid, Inventory_index[playerid][14], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_index[playerid][14], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_index[playerid][14], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][14], 96);
		PlayerTextDrawFont(playerid, Inventory_index[playerid][14], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_index[playerid][14], 0);
		PlayerTextDrawSetShadow(playerid,Inventory_index[playerid][14], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_index[playerid][14], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][14], 19382);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][14], 0.000000, 0.000000, 0.000000, 1.000000);

	    Inventory_skin[playerid] = CreatePlayerTextDraw(playerid, 73.300109, 138.366668, "");
		PlayerTextDrawLetterSize(playerid, Inventory_skin[playerid], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_skin[playerid], 227.000000, 202.000000);
		PlayerTextDrawAlignment(playerid, Inventory_skin[playerid], 1);
		PlayerTextDrawColor(playerid, Inventory_skin[playerid], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_skin[playerid], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_skin[playerid], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_skin[playerid], 43520);
		PlayerTextDrawFont(playerid, Inventory_skin[playerid], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_skin[playerid], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_skin[playerid], 0);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_skin[playerid], 0);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_skin[playerid], 0.000000, 0.000000, 0.000000, 1.000000);

	    Inventory_textos[playerid][0] = CreatePlayerTextDraw(playerid, 68.199996, 120.716636, "personagem");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][0], 0.326999, 1.284999);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][0], 1);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][0], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][0], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][0], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][0], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][0], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][0], 0);

		Inventory_textos[playerid][1] = CreatePlayerTextDraw(playerid, 315.710540, 120.716636, ConvertToGameText("Seu inventário"));
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][1], 0.326999, 1.284999);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][1], 1);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][1], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][1], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][1], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][1], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][1], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][1], 0);

		Inventory_textos[playerid][2] = CreatePlayerTextDraw(playerid, 248.200164, 144.800033, ConvertToGameText("Cabeça"));
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][2], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][2], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][2], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][2], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][2], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][2], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][2], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][2], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][2], 0);

		Inventory_textos[playerid][3] = CreatePlayerTextDraw(playerid, 247.399932, 189.833389, "mochila");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][3], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][3], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][3], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][3], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][3], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][3], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][3], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][3], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][3], 0);

		Inventory_textos[playerid][4] = CreatePlayerTextDraw(playerid, 128.199707, 180.250152, "corpo");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][4], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][4], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][4], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][4], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][4], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][4], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][4], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][4], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][4], 0);

		Inventory_textos[playerid][5] = CreatePlayerTextDraw(playerid, 127.499824, 232.683532, "arma");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][5], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][5], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][5], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][5], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][5], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][5], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][5], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][5], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][5], 0);

		Inventory_textos[playerid][6] = CreatePlayerTextDraw(playerid, 247.099945, 236.100448, "arma");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][6], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][6], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][6], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][6], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][6], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][6], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][6], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][6], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][6], 0);

		Inventory_textos[playerid][7] = CreatePlayerTextDraw(playerid, 246.600036, 285.667083, "arma");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][7], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][7], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][7], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][7], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][7], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][7], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][7], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][7], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][7], 0);

		Inventory_textos[playerid][8] = CreatePlayerTextDraw(playerid, 127.800155, 284.950317, "arma");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][8], 0.172995, 0.870832);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][8], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][8], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][8], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][8], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][8], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][8], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][8], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][8], 0);

		Inventory_description[playerid][0] = CreatePlayerTextDraw(playerid, 317.699981, 314.833312, "");
		PlayerTextDrawLetterSize(playerid, Inventory_description[playerid][0], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_description[playerid][0], 65.000000, 56.000000);
		PlayerTextDrawAlignment(playerid, Inventory_description[playerid][0], 1);
		PlayerTextDrawColor(playerid, Inventory_description[playerid][0], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_description[playerid][0], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_description[playerid][0], -208);
		PlayerTextDrawFont(playerid, Inventory_description[playerid][0], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_description[playerid][0], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][0], 0);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_description[playerid][0], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_description[playerid][0], 0.000000, 0.000000, 0.000000, 1.000000);
	    PlayerTextDrawSetSelectable(playerid, Inventory_description[playerid][0], true);

		Inventory_description[playerid][1] = CreatePlayerTextDraw(playerid, 388.099884, 314.099884, "CAPACETE");
		PlayerTextDrawLetterSize(playerid, Inventory_description[playerid][1], 0.290499, 1.226665);
		PlayerTextDrawAlignment(playerid, Inventory_description[playerid][1], 1);
		PlayerTextDrawColor(playerid, Inventory_description[playerid][1], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_description[playerid][1], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_description[playerid][1], 255);
		PlayerTextDrawFont(playerid, Inventory_description[playerid][1], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_description[playerid][1], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][1], 0);

		Inventory_description[playerid][2] = CreatePlayerTextDraw(playerid, 388.699920, 330.400878, "PROTEGE_CONTRA_HEADSHOTS");
		PlayerTextDrawLetterSize(playerid, Inventory_description[playerid][2], 0.157499, 0.882498);
		PlayerTextDrawAlignment(playerid, Inventory_description[playerid][2], 1);
		PlayerTextDrawColor(playerid, Inventory_description[playerid][2], -168430192);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][2], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_description[playerid][2], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_description[playerid][2], 255);
		PlayerTextDrawFont(playerid, Inventory_description[playerid][2], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_description[playerid][2], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][2], 0);

		Inventory_description[playerid][3] = CreatePlayerTextDraw(playerid, 499.401489, 363.984985, "QUANTIDADE:_1");
		PlayerTextDrawLetterSize(playerid, Inventory_description[playerid][3], 0.157499, 0.882498);
		PlayerTextDrawAlignment(playerid, Inventory_description[playerid][3], 3);
		PlayerTextDrawColor(playerid, Inventory_description[playerid][3], -168430208);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][3], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_description[playerid][3], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_description[playerid][3], 255);
		PlayerTextDrawFont(playerid, Inventory_description[playerid][3], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_description[playerid][3], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_description[playerid][3], 0);

		Inventory_textos[playerid][9] = CreatePlayerTextDraw(playerid, 540.294372, 313.548706, "usar");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][9], 0.400000, 1.600000);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][9], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][9], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][9], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][9], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][9], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][9], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][9], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][9], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_textos[playerid][9], false);

	    Inventory_personagemindex[playerid][0] = CreatePlayerTextDraw(playerid, 231.000305, 153.250015, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][0], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][0], 33.000000, 32.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][0], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][0], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][0], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][0], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][0], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][0], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][0], 0);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][0], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][0], 0.000000, 0.000000, 0.000000, 1.000000);
	    PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][0], true);

		Inventory_personagemindex[playerid][1] = CreatePlayerTextDraw(playerid, 110.600074, 189.283264, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][1], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][1], 33.000000, 32.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][1], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][1], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][1], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][1], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][1], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][1], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][1], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][1], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][1], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][1], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_personagemindex[playerid][2] = CreatePlayerTextDraw(playerid, 230.500000, 198.749984, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][2], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][2], 33.000000, 36.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][2], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][2], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][2], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][2], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][2], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][2], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][2], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][2], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][2], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][2], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][2], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_personagemindex[playerid][3] = CreatePlayerTextDraw(playerid, 110.400032, 242.366851, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][3], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][3], 33.000000, 36.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][3], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][3], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][3], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][3], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][3], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][3], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][3], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][3], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][3], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][3], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][3], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_personagemindex[playerid][4] = CreatePlayerTextDraw(playerid, 230.405273, 244.750305, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][4], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][4], 33.000000, 36.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][4], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][4], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][4], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][4], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][4], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][4], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][4], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][4], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][4], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][4], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][4], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_personagemindex[playerid][5] = CreatePlayerTextDraw(playerid, 230.505279, 294.150360, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][5], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][5], 33.000000, 36.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][5], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][5], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][5], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][5], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][5], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][5], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][5], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][5], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][5], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][5], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][5], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_personagemindex[playerid][6] = CreatePlayerTextDraw(playerid, 110.400032, 294.070007, "");
		PlayerTextDrawLetterSize(playerid, Inventory_personagemindex[playerid][6], 0.000000, 0.000000);
		PlayerTextDrawTextSize(playerid, Inventory_personagemindex[playerid][6], 33.000000, 36.000000);
		PlayerTextDrawAlignment(playerid, Inventory_personagemindex[playerid][6], 1);
		PlayerTextDrawColor(playerid, Inventory_personagemindex[playerid][6], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][6], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_personagemindex[playerid][6], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][6], 112);
		PlayerTextDrawFont(playerid, Inventory_personagemindex[playerid][6], 5);
		PlayerTextDrawSetProportional(playerid, Inventory_personagemindex[playerid][6], 0);
		PlayerTextDrawSetShadow(playerid, Inventory_personagemindex[playerid][6], 0);
		PlayerTextDrawSetSelectable(playerid, Inventory_personagemindex[playerid][6], true);
		PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][6], 18645);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][6], 0.000000, 0.000000, 0.000000, 1.000000);

		Inventory_textos[playerid][10] = CreatePlayerTextDraw(playerid, 187.721237, 347.616729, "remover");
		PlayerTextDrawLetterSize(playerid, Inventory_textos[playerid][10], 0.325504, 1.407498);
		PlayerTextDrawAlignment(playerid, Inventory_textos[playerid][10], 2);
		PlayerTextDrawColor(playerid, Inventory_textos[playerid][10], -1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][10], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_textos[playerid][10], 0);
		PlayerTextDrawBackgroundColor(playerid, Inventory_textos[playerid][10], 255);
		PlayerTextDrawFont(playerid, Inventory_textos[playerid][10], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_textos[playerid][10], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_textos[playerid][10], 0);

		Inventory_mensagem[playerid] = CreatePlayerTextDraw(playerid, 321.224029, 381.983398, "error_msg");
		PlayerTextDrawLetterSize(playerid, Inventory_mensagem[playerid], 0.400000, 1.600000);
		PlayerTextDrawAlignment(playerid, Inventory_mensagem[playerid], 2);
		PlayerTextDrawColor(playerid, Inventory_mensagem[playerid], -2147483393);
		PlayerTextDrawSetShadow(playerid, Inventory_mensagem[playerid], 0);
		PlayerTextDrawSetOutline(playerid, Inventory_mensagem[playerid], 1);
		PlayerTextDrawBackgroundColor(playerid, Inventory_mensagem[playerid], 255);
		PlayerTextDrawFont(playerid, Inventory_mensagem[playerid], 2);
		PlayerTextDrawSetProportional(playerid, Inventory_mensagem[playerid], 1);
		PlayerTextDrawSetShadow(playerid, Inventory_mensagem[playerid], 0);
}


stock ShowPlayerKillTextDraw(playerid, text[], bool:kills=false, ktext[])
{


  PlayerTextDrawShow(playerid, KillTD[playerid][0]);
  PlayerTextDrawSetString(playerid, KillTD[playerid][0], text);
  if(kills)
  {
    PlayerTextDrawShow(playerid, KillTD[playerid][1]);
    PlayerTextDrawSetString(playerid, KillTD[playerid][1], ktext);
  }
  pInfo[playerid][ShowingkillTD] = true;
  SetTimerEx("HideKillTD", 3500, false, "i", playerid);
}

CMD:seth(playerid, params[])
{
  new id, h;
  if(sscanf(params, "ii", id, h)) return 1;
  SetPlayerHealth(id, h);
  return 1;
}


GlobalTextDraw(playerid, bool:show=false, slotid)
{
   if(show)
   {
	  TextDrawShowForPlayer(playerid, BlueBox[slotid]);
	  TextDrawShowForPlayer(playerid, RedBox[slotid]);
	  TextDrawShowForPlayer(playerid, OBJBOX[slotid]);
	  TextDrawShowForPlayer(playerid, TimeBOX[slotid]);
	  TextDrawShowForPlayer(playerid, BlueKills[slotid]);
	  TextDrawShowForPlayer(playerid, RedKills[slotid]);
	  TextDrawShowForPlayer(playerid, OBJTD[slotid]);
	  TextDrawShowForPlayer(playerid, TimeTD[slotid]);
   }
   else if(!show)
   {
   	  TextDrawHideForPlayer(playerid, BlueBox[slotid]);
	  TextDrawHideForPlayer(playerid, RedBox[slotid]);
	  TextDrawHideForPlayer(playerid, OBJBOX[slotid]);
	  TextDrawHideForPlayer(playerid, TimeBOX[slotid]);
	  TextDrawHideForPlayer(playerid, BlueKills[slotid]);
	  TextDrawHideForPlayer(playerid, RedKills[slotid]);
	  TextDrawHideForPlayer(playerid, OBJTD[slotid]);
	  TextDrawHideForPlayer(playerid, TimeTD[slotid]);
   }
}
forward HideKillTD(playerid);
public HideKillTD(playerid)
{
   return PlayerTextDrawHide(playerid, KillTD[playerid][0]), PlayerTextDrawHide(playerid, KillTD[playerid][1]), pInfo[playerid][ShowingkillTD]=false;
}

stock GetHighestKill(slotid, teamid)
{
    new bestkills = 0;
    new id = INVALID_PLAYER_ID;
    foreach(new i : Player) if(pInfo[i][InPTDM] == 1 && pInfo[i][SlotID] == slotid && pInfo[i][TeamID] == teamid)
    {
        if(pInfo[i][Kills] > bestkills)
		{
            bestkills = pInfo[i][Kills];
            id = i;
        }
    }
    return id;
}

LoadDynamicObjects()
{
	CreateDynamicObject(12814, -2135.38525, 1865.83716, 0.98790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2158.45557, 1882.18262, -0.19748,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2223.71802, 1799.05920, 0.90930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2125.69873, 1863.18359, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2174.19824, 1891.22852, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2136.89966, 1874.16895, -0.16690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2127.93677, 1868.78137, -0.16968,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2148.20581, 1783.93799, 0.89660,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2130.35229, 1872.77100, -0.10719,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -3153.02295, 2446.17505, -0.62096,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2188.71509, 1783.90930, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2224.50732, 1711.73157, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.17236, 1876.66650, -0.12500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.31592, 1844.71094, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.31592, 1844.71094, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9255, -2258.03345, 1718.60266, 0.83857,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2356.63428, 1768.31592, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6066, -2208.59106, 1699.41895, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2158.88184, 1743.25818, 2.70500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19495, -2224.64014, 1700.50928, 6.01420,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -2128.96362, 33333.78906, 86.69690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2194.05908, 1820.46570, 1.04560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2251.15259, 1911.04761, -0.07668,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9087, -2067.95288, 1802.44055, 0.30700,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(12814, -2194.16211, 1865.48096, 0.99130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2164.78198, 1865.61035, 0.98790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2158.45557, 1882.18262, -0.19748,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2219.92920, 1750.42627, 0.86930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2125.69922, 1863.22363, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2174.35840, 1887.87976, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2136.89966, 1874.16895, -0.16690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2127.93677, 1868.78137, -0.16968,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2136.45728, 1888.88513, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2147.67285, 1744.38135, 0.90500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2130.37183, 1872.76636, -0.10719,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -3153.02295, 2446.17505, -0.62096,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2185.19434, 1744.41211, 0.90500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2224.36963, 1711.82422, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.15747, 1876.56787, -0.12500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.34155, 1844.65662, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2166.08569, 1845.72485, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9255, -2257.91406, 1628.04114, 0.29860,   0.00000, 0.00000, 76.00000);
	CreateDynamicObject(12814, -2357.87524, 1768.66125, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6066, -2252.71973, 1667.64160, 3.10080,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2114.67163, 1795.08228, 2.70500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19495, -2229.92505, 1621.73267, 6.01420,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -2128.96362, 33333.78906, 86.69690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2221.48901, 1848.80176, 0.91130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2147.77173, 1822.60193, 1.00560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2244.41479, 1908.64099, -0.07668,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9087, -2069.37280, 1765.17749, 0.77670,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2148.06885, 1815.76990, 0.95130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2189.75562, 1671.58655, 0.77680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2154.89600, 1684.55237, -0.06157,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2176.13452, 1646.95947, -0.04593,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2065.00684, 1787.30505, 0.86510,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.03735, 1651.67505, 0.74890,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.28369, 1709.02429, 0.78890,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.96118, 1683.19092, 0.74234,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2119.66699, 1654.62524, -0.04920,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.82007, 1623.45203, 0.63200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19532, -2114.55469, 1874.05347, 0.98820,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2104.28394, 2214.59375, -0.08205,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2104.28394, 2214.59375, -0.08205,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2218.70825, 1632.84143, 1.39470,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10770, -2209.62671, 1632.25342, 3.98180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7326, -2125.90918, 1790.95679, 1.11000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7326, -2146.85083, 1747.06421, 1.11000,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(17576, -2106.91528, 1871.48608, 5.10550,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3844, -2183.83545, 1884.62097, 5.84230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18239, -2229.49438, 1869.78186, 0.74760,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(16327, -2187.51782, 1870.30933, 1.02400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16326, -2213.59937, 1865.90161, 1.73500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3845, -2202.61011, 1800.89978, 6.03050,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3821, -2201.96851, 1814.99866, 6.89320,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12951, -2201.13232, 1827.99072, 0.89380,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(14738, -2204.69263, 1870.72205, 3.89950,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3640, -2228.33447, 1850.00916, 4.80250,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3843, -2230.49194, 1834.86145, 8.01980,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(3759, -2232.50049, 1817.96570, 4.79940,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3820, -2230.20093, 1797.31873, 7.39050,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5520, -2230.09473, 1780.54041, 5.87700,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(9310, -2228.70972, 1755.51953, 6.20540,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3653, -2227.25439, 1730.46826, 6.34510,   0.00000, 0.00000, 185.00000);
	CreateDynamicObject(3762, -2191.43115, 1712.42712, 4.46390,   0.00000, 0.00000, -4.00000);
	CreateDynamicObject(10439, -2199.40186, 1778.69287, 4.12370,   -0.02000, 0.00000, 0.00000);
	CreateDynamicObject(3385, -2135.10181, 1768.18054, 1.91230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18657, -2205.66260, 1881.27014, 1.47128,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2088.36890, 1850.10156, 3.10620,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2164.60425, 1854.81262, 2.49700,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -1974.58118, 1767.01990, 29.24700,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(9090, -2028.07690, 1869.24329, -25.04430,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19588, -1973.36731, 1751.47717, 5.20740,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19588, -2258.92969, 1688.70435, 1.04380,   0.00000, 0.00000, 193.00000);
	CreateDynamicObject(19531, -1998.65906, 1784.89307, 0.67172,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2000.84717, 1664.25464, 0.49466,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2124.30273, 1663.54688, 0.74090,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(714, -2025.17566, 1865.45093, 2.48230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2114.65063, 1672.30359, 20.82830,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2117.20654, 1691.46436, 10.76570,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(818, -2122.61597, 1720.43408, 5.59340,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5773, -2185.15649, 1636.80444, -1.88010,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2745, -2136.01050, 1772.41406, 1.44980,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(4563, -1974.73425, 1640.55811, 86.55250,   0.00000, 0.00000, -84.00000);
	CreateDynamicObject(19076, -2135.71631, 1769.51880, 0.78740,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8131, -2134.96313, 1732.85278, 11.52110,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11674, -2164.71729, 1885.25024, 1.18270,   0.00000, 0.00000, 40.00000);
	CreateDynamicObject(9272, -2140.74121, 1884.94165, 7.33810,   0.00000, 0.00000, -91.00000);
	CreateDynamicObject(9324, -2093.08472, 1712.31055, 5.88720,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(18261, -12777.28809, 1518.91675, 484.55606,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18261, -2086.38672, 1684.74805, 1.51160,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(8675, -2093.52295, 1621.88477, 9.64010,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7617, -2100.00781, 1655.63733, 1.71800,   0.00000, 0.00000, -91.00000);
	CreateDynamicObject(3676, -2132.36597, 1619.20447, 6.24590,   0.00000, 0.00000, 84.00000);
	CreateDynamicObject(6257, -2139.82227, 1817.87561, 8.13896,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3684, -2173.64941, 1828.52283, 3.89410,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(16781, -2167.15283, 1801.85303, 0.99920,   0.00000, 0.00000, 87.00000);
	CreateDynamicObject(10999, -2169.31177, 1775.29419, 1.25020,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(6088, -2146.08936, 1685.83838, 3.96380,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4825, -1992.51416, 1784.93213, -1.66930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2186.77783, 1680.73120, 2.43730,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2218.19702, 1663.82117, 2.51100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2239.93164, 1695.27173, 2.63820,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6285, -2048.08521, 1678.17810, 6.48300,   0.00000, 0.00000, 182.00000);
	CreateDynamicObject(8068, -2072.42627, 1867.64453, 8.33480,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3488, -1991.43359, 1869.99573, 9.19830,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11674, -2091.11914, 1832.49939, 1.68740,   0.00000, 0.00000, 36.00000);
	CreateDynamicObject(16781, -2061.20313, 1823.91357, 0.99990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2087.25684, 1807.24255, 1.25360,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2096.74023, 1773.74695, 1.76880,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2165.54907, 1837.15088, 0.97831,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2120.07837, 1791.25269, 10.47780,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2161.04932, 1739.89758, 10.35850,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2193.24365, 1673.39758, 0.65479,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18648, -2066.34961, 1824.42505, 6.61642,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18648, -2092.12646, 1797.86633, 0.83639,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19128, -2072.94507, 1784.77893, 0.83639,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3385, -2218.59912, 1682.06689, 0.85193,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16006, -2102.46265, 1763.24072, 0.21700,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(7929, -2195.70752, 1741.29333, 7.52560,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3385, -2148.59131, 1711.10059, 0.82823,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3385, -2219.70532, 1661.42712, 1.72000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2158.23462, 1736.19141, 1.63130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2112.12695, 1788.42627, 1.72310,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2266.53027, 1686.68262, 1.23150,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2135.92285, 1859.86145, 1.57970,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2226.95190, 1691.51770, 0.69995,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2084.58350, 1768.21899, 1.19790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2167.35742, 1857.49487, 1.24210,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2170.74780, 1855.36499, 0.97753,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2170.74780, 1855.36499, 0.97753,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2214.95459, 1741.36292, 1.97680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2196.09619, 1854.04724, 0.97680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2217.54883, 1777.14551, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2086.51489, 1803.47021, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2219.64258, 1819.48877, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2215.19800, 1845.66431, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2004.02271, 1797.03760, 1.78190,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2002.72717, 1773.63635, 1.57560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19187, -2193.54028, 1769.38013, 4.67020,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19187, -2193.54028, 1769.38013, 4.35016,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2253, -2193.54028, 1769.38013, 4.35016,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1395, -2100.12793, 1851.14709, 31.23210,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8981, -2053992.00000, 1957.44067, 120.09140,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6257, -2054.06055, 1712.68921, 7.67490,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2135.38525, 1865.83716, 0.98790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2158.45557, 1882.18262, -0.19748,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2223.71802, 1799.05920, 0.90930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2125.69873, 1863.18359, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2174.19824, 1891.22852, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2136.89966, 1874.16895, -0.16690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2127.93677, 1868.78137, -0.16968,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2148.20581, 1783.93799, 0.89660,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2130.35229, 1872.77100, -0.10719,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -3153.02295, 2446.17505, -0.62096,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2188.71509, 1783.90930, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2224.50732, 1711.73157, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.17236, 1876.66650, -0.12500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.31592, 1844.71094, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.31592, 1844.71094, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9255, -2258.03345, 1718.60266, 0.83857,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2356.63428, 1768.31592, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6066, -2208.59106, 1699.41895, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2025.39771, 1716.13867, 2.58500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19495, -2224.64014, 1700.50928, 6.01420,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -2128.96362, 33333.78906, 86.69690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2194.05908, 1820.46570, 1.04560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2251.15259, 1911.04761, -0.07668,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9087, -2067.96411, 1802.42395, 0.76700,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(12814, -2194.16211, 1865.48096, 0.99130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2164.78198, 1865.61035, 0.98790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2158.45557, 1882.18262, -0.19748,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2219.92920, 1750.42627, 0.86930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2125.69922, 1863.22363, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2174.35840, 1887.87976, -0.16872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2136.89966, 1874.16895, -0.16690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2127.93677, 1868.78137, -0.16968,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2138.14673, 1886.18835, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2136.45728, 1888.88513, -0.17541,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2147.67285, 1744.38135, 0.90500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2130.37183, 1872.76636, -0.10719,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -3153.02295, 2446.17505, -0.62096,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2185.19434, 1744.41211, 0.90500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2224.36963, 1711.82422, 0.76499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.15747, 1876.56787, -0.12500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2167.34155, 1844.65662, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2166.08569, 1845.72485, -0.11990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2357.87524, 1768.66125, -0.12083,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6066, -2252.71973, 1667.64160, 3.10080,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2114.73413, 1930.32983, 2.70500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19495, -2229.92505, 1621.73267, 6.01420,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -2128.96362, 33333.78906, 86.69690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2221.48901, 1848.80176, 0.91130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2147.77173, 1822.60193, 1.00560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, -2244.41479, 1908.64099, -0.07668,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9087, -2069.37671, 1765.20557, 0.69670,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2148.06885, 1815.76990, 0.95130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2189.75562, 1671.58655, 0.77680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2154.89600, 1684.55237, -0.06157,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2176.13452, 1646.95947, -0.04593,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2066.01440, 1788.04138, 0.86510,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.03735, 1651.67505, 0.74890,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.28369, 1709.02429, 0.78890,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.96118, 1683.19092, 0.74234,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2119.66699, 1654.62524, -0.04920,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19549, -2128.82007, 1623.45203, 0.63200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19532, -2114.82764, 1875.20740, 0.98820,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2104.28394, 2214.59375, -0.08205,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2104.28394, 2214.59375, -0.08205,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2641, -2218.70825, 1632.84143, 1.39470,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10770, -2209.62671, 1632.25342, 3.98180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7326, -2125.88062, 1790.89075, 1.11000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7326, -2146.83447, 1747.05286, 1.11000,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(17576, -2106.91528, 1871.48608, 5.10550,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3844, -2183.83545, 1884.62097, 5.84230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18239, -2229.49438, 1869.78186, 0.74760,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(16327, -2187.51782, 1870.30933, 1.02400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16326, -2213.59937, 1865.90161, 1.73500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3845, -2202.61011, 1800.89978, 6.03050,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3821, -2201.96851, 1814.99866, 6.89320,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12951, -2201.13232, 1827.99072, 0.89380,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(14738, -2204.69263, 1870.72205, 3.89950,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3843, -2230.49194, 1834.86145, 8.01980,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(3759, -2232.50049, 1817.96570, 4.79940,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3820, -2230.20093, 1797.31873, 7.39050,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5520, -2230.09473, 1780.54041, 5.87700,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3762, -2165.97485, 1709.10938, 4.56390,   0.00000, 0.00000, -4.00000);
	CreateDynamicObject(3385, -2135.10181, 1768.18054, 1.91230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2088.36890, 1850.10156, 3.10620,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2164.60425, 1854.81262, 2.49700,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10398, -1974.58118, 1767.01990, 29.24700,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(9090, -2028.07690, 1869.24329, -25.04430,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19588, -1973.36731, 1751.47717, 5.20740,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19588, -2258.92969, 1688.70435, 1.04380,   0.00000, 0.00000, 193.00000);
	CreateDynamicObject(19531, -1998.65906, 1784.89307, 0.67172,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2000.84717, 1664.25464, 0.49466,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19531, -2124.30273, 1663.54688, 0.74090,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(714, -2025.17566, 1865.45093, 2.48230,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2067.66479, 1772.90454, 10.82830,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(818, -2122.61597, 1720.43408, 5.59340,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5773, -2185.15649, 1636.80444, -1.88010,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2745, -2136.01050, 1772.41406, 1.44980,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(4550, -2041.70337, 1625.36816, 81.03460,   0.00000, 0.00000, 47.00000);
	CreateDynamicObject(19076, -2135.71631, 1769.51880, 0.78740,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8131, -2044.40869, 1747.03076, 11.38110,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11674, -2164.71729, 1885.25024, 1.18270,   0.00000, 0.00000, 40.00000);
	CreateDynamicObject(9272, -2140.74121, 1884.94165, 7.33810,   0.00000, 0.00000, -91.00000);
	CreateDynamicObject(9324, -2093.08472, 1712.31055, 5.88720,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(18261, -12777.28809, 1518.91675, 484.55606,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18261, -2086.38672, 1684.74805, 1.51160,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(8675, -2093.52295, 1621.88477, 9.64010,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7617, -2100.00781, 1655.63733, 1.71800,   0.00000, 0.00000, -91.00000);
	CreateDynamicObject(3676, -2132.36597, 1619.20447, 6.24590,   0.00000, 0.00000, 84.00000);
	CreateDynamicObject(6257, -2139.82227, 1817.87561, 8.13896,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3684, -2173.64941, 1828.52283, 3.89410,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(16781, -2167.15283, 1801.85303, 0.99920,   0.00000, 0.00000, 87.00000);
	CreateDynamicObject(10999, -2169.31177, 1775.29419, 1.25020,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(6088, -2146.08936, 1685.83838, 3.96380,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4825, -1992.51416, 1784.93213, -1.66930,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(14537, -2218.19702, 1663.82117, 2.51100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6285, -2048.08521, 1678.17810, 6.48300,   0.00000, 0.00000, 182.00000);
	CreateDynamicObject(8068, -2072.42627, 1867.64453, 8.33480,   0.00000, 0.00000, 91.00000);
	CreateDynamicObject(3488, -1991.43359, 1869.99573, 9.19830,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11674, -2091.11914, 1832.49939, 1.68740,   0.00000, 0.00000, 36.00000);
	CreateDynamicObject(16781, -2061.20313, 1823.91357, 0.99990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2087.25684, 1807.24255, 1.25360,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2096.74023, 1773.74695, 1.76880,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2165.54907, 1837.15088, 0.97831,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2120.07837, 1791.25269, 10.47780,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19152, -2161.04932, 1739.89758, 10.35850,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19530, -2193.24365, 1673.39758, 0.65479,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18648, -2066.34961, 1824.42505, 6.61642,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18648, -2092.12646, 1797.86633, 0.83639,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19128, -2072.94507, 1784.77893, 0.83639,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3385, -2218.59912, 1682.06689, 0.85193,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16006, -2102.46265, 1763.24072, 0.21700,   0.00000, 0.00000, 178.00000);
	CreateDynamicObject(7929, -2095.20215, 1739.84534, 7.66560,   0.00000, 0.00000, -91.00000);
	CreateDynamicObject(3385, -2148.59131, 1711.10059, 0.82823,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3385, -2219.70532, 1661.42712, 1.72000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2158.23462, 1736.19141, 1.63130,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2112.12695, 1788.42627, 1.72310,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2266.53027, 1686.68262, 1.23150,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2135.92285, 1859.86145, 1.57970,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2226.95190, 1691.51770, 0.69995,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2084.58350, 1768.21899, 1.19790,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2167.35742, 1857.49487, 1.24210,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2170.74780, 1855.36499, 0.97753,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, -2170.74780, 1855.36499, 0.97753,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2214.95459, 1741.36292, 1.97680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2196.09619, 1854.04724, 0.97680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2217.54883, 1777.14551, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2086.51489, 1803.47021, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2219.64258, 1819.48877, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2215.19800, 1845.66431, 1.98170,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2004.02271, 1797.03760, 1.78190,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1232, -2002.72717, 1773.63635, 1.57560,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19187, -2193.54028, 1769.38013, 4.67020,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19187, -2193.54028, 1769.38013, 4.35016,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2253, -2193.54028, 1769.38013, 4.35016,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1395, -2100.12793, 1851.14709, 31.23210,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8981, -2053992.00000, 1957.44067, 120.09140,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6257, -2054.06055, 1712.68921, 7.67490,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2068.57837, 1756.08215, 3.50262,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2185.79126, 1684.28589, 3.50262,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2227.58008, 1668.59900, 8.77522,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18271, -2178.85449, 1856.74451, 16.83640,   -4.00000, 0.00000, 113.00000);
	CreateDynamicObject(18271, -2148.00635, 1868.20422, 15.51220,   -4.00000, 0.00000, -244.00000);
	CreateDynamicObject(3437, -2132.04956, 1875.28772, 27.58647,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3437, -2132.04956, 1875.28772, 28.18650,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3440, -2128.86816, 2064.62622, 55.82951,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9683, -2262.60034, 1534.08252, -19.78620,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9683, -2262.61572, 1418.19348, -19.78620,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9587, -2262.97632, 1595.50574, 1.27969,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(9587, -2261.01709, 1596.18628, 9.50960,   0.00000, 0.00000, 0.00000);
}

//----------------------------------------------------------

stock AddItem(playerid, itemid, amount, Float:armorstatus = 100.0, bool:showtext=false)
{

    if(showtext)
    {
	   format(String, sizeof(String), "~y~~h~Picked up %s", ItemsData[itemid][item_name]);
	   GameTextForPlayer(playerid, String, 3000, 3);
	}

	new bool:sucess = false;

	for(new i = 0; i < MAX_INVENTORY_SLOTS; i ++)
    {
		if(pInventory[playerid][invSlot][i] == itemid && ItemsData[pInventory[playerid][invSlot][i]][item_limit] > 1 && pInventory[playerid][invSlotAmount][i] != ItemsData[pInventory[playerid][invSlot][i]][item_limit])
        {
            new check = amount + pInventory[playerid][invSlotAmount][i];

			if(check > ItemsData[pInventory[playerid][invSlot][i]][item_limit])
			{
                pInventory[playerid][invSlotAmount][i] = ItemsData[itemid][item_limit];

                for(new a = 0; a < MAX_INVENTORY_SLOTS; a ++)
                {
                	if(pInventory[playerid][invSlot][a] == 0)
                	{
                    	pInventory[playerid][invSlot][a] = itemid;
						new resto = ItemsData[itemid][item_limit] - check;
                    	pInventory[playerid][invSlotAmount][a] = resto*-1;

                    	if(pInfo[playerid][inInventory])
						{
	                    	PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][a], ItemsData[itemid][item_model]);
	 						PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][a], ItemsData[itemid][item_previewrot][0], ItemsData[itemid][item_previewrot][1], ItemsData[itemid][item_previewrot][2], ItemsData[itemid][item_previewrot][3]);

							PlayerTextDrawHide(playerid, Inventory_index[playerid][a]);
	            			PlayerTextDrawShow(playerid, Inventory_index[playerid][a]);
						}
						break;
					}
				}
			}
			else
			{
            	pInventory[playerid][invSlotAmount][i] += amount;

            	if(pInfo[playerid][inInventory])
				{
				    if(pInventory[playerid][invSelectedSlot] == i)
					{
						if(pInventory[playerid][invSlotAmount][i] > 1)
							format(String, sizeof(String), "Amount: %d", pInventory[playerid][invSlotAmount][i]);
						else
							String = " ";

						PlayerTextDrawSetString(playerid, Inventory_description[playerid][3], String);

					    PlayerTextDrawHide(playerid, Inventory_description[playerid][3]);
					    PlayerTextDrawShow(playerid, Inventory_description[playerid][3]);
					}
				}
			}

			sucess = true;
         	break;
		}
	}

	if(sucess)
	    return true;

	for(new i = 0; i < MAX_INVENTORY_SLOTS; i ++)
 	{
		if(pInventory[playerid][invSlot][i] == 0)
	    {
		    pInventory[playerid][invSlot][i] = itemid;
	        pInventory[playerid][invSlotAmount][i] = amount;

	        if(itemid == 6)
	        	pInventory[playerid][invArmourStatus][i] = armorstatus;

	        if(pInfo[playerid][inInventory])
			{
			    PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][i], ItemsData[itemid][item_model]);
				PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][i], ItemsData[itemid][item_previewrot][0], ItemsData[itemid][item_previewrot][1], ItemsData[itemid][item_previewrot][2], ItemsData[itemid][item_previewrot][3]);

	            PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);
	            PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);
			}

			break;
		}
	}

	return true;
}

//----------------------------------------------------------

stock SplitItem(playerid, slot)
{
    new result = pInventory[playerid][invSlotAmount][slot]/2;

	for(new i = 0; i < MAX_INVENTORY_SLOTS; i ++)
        if(pInventory[playerid][invSlot][i] == 0)
        {
            pInventory[playerid][invSlotAmount][slot] = pInventory[playerid][invSlotAmount][slot]/2;

            pInventory[playerid][invSlot][i] = pInventory[playerid][invSlot][slot];
            pInventory[playerid][invSlotAmount][i] = result;

    		PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);
    		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_model]);
 			PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][3]);
       		PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);

			if(pInventory[playerid][invSlotAmount][slot] > 1)
				format(String, sizeof(String), "Amount: %d", pInventory[playerid][invSlotAmount][slot]);
			else
				String = " ";

			PlayerTextDrawSetString(playerid, Inventory_description[playerid][3], String);

       		PlayerTextDrawHide(playerid, Inventory_description[playerid][3]);
       		PlayerTextDrawShow(playerid, Inventory_description[playerid][3]);
    		break;
        }
}

stock UseItem(playerid, slot, item)
{
	if(ItemsData[item][item_type] == ITEM_TYPE_HELMET)
	{
		if(pCharacter[playerid][charSlot][0] == 0)
		{
		    AddItemCharacter(playerid, 0, item);
		    RemoveItemFromInventory(playerid, slot);
		}
		else
		{
		    RemoveItemFromInventory(playerid, slot);
		    AddItem(playerid, pCharacter[playerid][charSlot][0], 1);
		    RemoveItemFromCharacter(playerid, 0);
		    AddItemCharacter(playerid, 0, item);
		}
	}
	else if(ItemsData[item][item_type] == ITEM_TYPE_WEAPON || ItemsData[item][item_type] == ITEM_TYPE_MELEEWEAPON)
	{
	    if(GetAmmunation(playerid) <= 0 && ItemsData[item][item_type] == ITEM_TYPE_WEAPON)
	    {
	        if(item != 4 && item != 17)
	        {
		        pInventory[playerid][invSelectedSlot] = slot;
		        return ShowMessageInventory(playerid, "~r~ERROR: ~w~You don't have ammunation.");
			}
	    }

	    new weapons[13][2];

		for (new i = 0; i <= 12; i++)
		    GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);

		new weaponid = GetWeaponIDFromModel(ItemsData[item][item_model]);
		new weaponslot = GetWeaponSlot(weaponid);

		if(weapons[weaponslot][0] != 0 && weapons[weaponslot][1] > 0)
		{
		    pInventory[playerid][invSelectedSlot] = slot;
			return ShowMessageInventory(playerid, "~r~ERROR: ~w~It's not possible to equip two weapons of the same kind.");
		}

	    new bool:have_slot;

	    for(new i = 3; i < 7; i ++)
	    {
	        if(pCharacter[playerid][charSlot][i] == item)
			{
			    pInventory[playerid][invSelectedSlot] = slot;
                ShowMessageInventory(playerid, "~r~ERROR: ~w~It's not possible to equip two identical weapons.");
			    have_slot = true;
			    break;
			}

	    	if(pCharacter[playerid][charSlot][i] == 0)
			{
			    AddItemCharacter(playerid, i, item, pInventory[playerid][invSlotAmount][slot]);
			    RemoveItemFromInventory(playerid, slot);
		    	have_slot = true;
                break;
			}
		}

		if(!have_slot)
		{
		    pInventory[playerid][invSelectedSlot] = slot;
		    ShowMessageInventory(playerid, "~r~ERROR: ~w~It's not possible to equip more weapons.");
		    return true;
		}
	}
	else if(ItemsData[item][item_type] == ITEM_TYPE_BODY)
	{
	    if(pCharacter[playerid][charSlot][1] == 0)
		{
	    	AddItemCharacter(playerid, 1, item, 0, pInventory[playerid][invArmourStatus][slot]);
			RemoveItemFromInventory(playerid, slot);
		}
		else
		{
		    RemoveItemFromInventory(playerid, slot);
		    AddItem(playerid, pCharacter[playerid][charSlot][1], 1);
		    RemoveItemFromCharacter(playerid, 1);
		    AddItemCharacter(playerid, 1, item);
		}
	}
	else if(ItemsData[item][item_type] == ITEM_TYPE_BACKPACK)
	{
	    if(pCharacter[playerid][charSlot][2] == 0)
		{
		    AddItemCharacter(playerid, 2, item);
			RemoveItemFromInventory(playerid, slot);
		}
		else
		{
		    RemoveItemFromInventory(playerid, slot);
		    AddItem(playerid, pCharacter[playerid][charSlot][2], 1);
		    RemoveItemFromCharacter(playerid, 2);
		    AddItemCharacter(playerid, 2, item);
		}

		OrganizeInventory(playerid);

		for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
	    	PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);

        for(new i = 0; i < GetSlotsInventory(playerid); i++)
		{
			PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_model]);
	 		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][3]);
	        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][i], 96);

			PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);
		}
	}
	else if(ItemsData[item][item_type] == ITEM_TYPE_AMMO)
	{
        pInventory[playerid][invSelectedSlot] = slot;
        return true;
	}
	else if(ItemsData[item][item_type] == ITEM_TYPE_NORMAL)
	{
	    if(item == 18) // Medic Kit
	    {
	        SetPlayerHealth(playerid, 100.0);
	        RemoveItemFromInventory(playerid, slot, 1);
	    }
	}

	if(pInfo[playerid][inInventory])
	{
	   	for(new a = 0; a < 4; a++)
		   	PlayerTextDrawHide(playerid, Inventory_description[playerid][a]);

		TextDrawHideForPlayer(playerid, Inventory_backgrounds[4]);

		TextDrawHideForPlayer(playerid, Inventory_usar);
		TextDrawHideForPlayer(playerid, Inventory_split[0]);
		TextDrawHideForPlayer(playerid, Inventory_split[1]);
		TextDrawHideForPlayer(playerid, Inventory_drop[0]);
		TextDrawHideForPlayer(playerid, Inventory_drop[1]);
		PlayerTextDrawHide(playerid, Inventory_textos[playerid][9]);
	}

	return true;
}

//----------------------------------------------------------

stock AddItemCharacter(playerid, slot, itemid, quantidade = 0, Float:armourstatus = 0.0)
{
	if(itemid == 1)
	{
	    switch(GetPlayerSkin(playerid))
		{
		    #define HelmetAttach{%0,%1,%2,%3,%4,%5} SetPlayerAttachedObject(playerid, 0, 18645, 2, (%0), (%1), (%2), (%3), (%4), (%5));
			case 0, 65, 74, 149, 208, 273:  HelmetAttach{0.070000, 0.000000, 0.000000, 88.000000, 75.000000, 0.000000}
			case 1..6, 8, 14, 16, 22, 27, 29, 33, 41..49, 82..84, 86, 87, 119, 289: HelmetAttach{0.070000, 0.000000, 0.000000, 88.000000, 77.000000, 0.000000}
			case 7, 10: HelmetAttach{0.090000, 0.019999, 0.000000, 88.000000, 90.000000, 0.000000}
			case 9: HelmetAttach{0.059999, 0.019999, 0.000000, 88.000000, 90.000000, 0.000000}
			case 11..13: HelmetAttach{0.070000, 0.019999, 0.000000, 88.000000, 90.000000, 0.000000}
			case 15: HelmetAttach{0.059999, 0.000000, 0.000000, 88.000000, 82.000000, 0.000000}
			case 17..21: HelmetAttach{0.059999, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 23..26, 28, 30..32, 34..39, 57, 58, 98, 99, 104..118, 120..131: HelmetAttach{0.079999, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 40: HelmetAttach{0.050000, 0.009999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 50, 100..103, 148, 150..189, 222: HelmetAttach{0.070000, 0.009999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 51..54: HelmetAttach{0.100000, 0.009999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 55, 56, 63, 64, 66..73, 75, 76, 78..81, 133..143, 147, 190..207, 209..219, 221, 247..272, 274..288, 290..293: HelmetAttach{0.070000, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 59..62: HelmetAttach{0.079999, 0.029999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 77: HelmetAttach{0.059999, 0.019999, 0.000000, 87.000000, 82.000000, 0.000000}
			case 85, 88, 89: HelmetAttach{0.070000, 0.039999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 90..97: HelmetAttach{0.050000, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 132: HelmetAttach{0.000000, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 144..146: HelmetAttach{0.090000, 0.000000, 0.000000, 88.000000, 82.000000, 0.000000}
			case 220: HelmetAttach{0.029999, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 223, 246: HelmetAttach{0.070000, 0.050000, 0.000000, 88.000000, 82.000000, 0.000000}
			case 224..245: HelmetAttach{0.070000, 0.029999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 294: HelmetAttach{0.070000, 0.019999, 0.000000, 91.000000, 84.000000, 0.000000}
			case 295: HelmetAttach{0.050000, 0.019998, 0.000000, 86.000000, 82.000000, 0.000000}
			case 296..298: HelmetAttach{0.064999, 0.009999, 0.000000, 88.000000, 82.000000, 0.000000}
			case 299..306: HelmetAttach{0.064998, 0.019999, 0.000000, 88.000000, 82.000000, 0.000000}
		}
	}
	else if(ItemsData[itemid][item_type] == ITEM_TYPE_WEAPON || ItemsData[itemid][item_type] == ITEM_TYPE_MELEEWEAPON)
	{
	    new modelid = ItemsData[itemid][item_model];

	    if(itemid == 5 || itemid == 17)
	        GivePlayerWeapon(playerid, GetWeaponIDFromModel(modelid), quantidade);
	    else
		    GivePlayerWeapon(playerid, GetWeaponIDFromModel(modelid), GetAmmunation(playerid));
	}
	else if(itemid == 6)
	{
	    SetPlayerArmour(playerid, armourstatus);
	    pCharacter[playerid][charArmourStatus] = armourstatus;
		SetPlayerAttachedObject(playerid, 1, 19142, 1, 0.103999,0.034999,0.001000,0.000000,0.000000,0.000000,1.000000,1.000000,1.000000);

  /*      switch(GetPlayerSkin(playerid))
		{
		    case 292:
				SetPlayerAttachedObject(playerid, 1, 19142, 1, 0.103999,0.034999,0.001000,0.000000,0.000000,0.000000,1.000000,1.000000,1.000000);
		}*/
	}
	else if(ItemsData[itemid][item_type] == ITEM_TYPE_BACKPACK)
	{
		SetPlayerAttachedObject(playerid, 2, 3026,1,-0.129000,-0.078999,-0.003999,0.000000,0.000000,0.000000,1.000000,1.000000,1.000000);

	   /* switch(GetPlayerSkin(playerid))
		{
		    case 292:
		        SetPlayerAttachedObject(playerid, 2, 3026,1,-0.129000,-0.078999,-0.003999,0.000000,0.000000,0.000000,1.000000,1.000000,1.000000);
		}*/
	}

	pCharacter[playerid][charSlot][slot] = itemid;

	PlayerPlaySound(playerid,1052,0.0,0.0,0.0);

    if(pInfo[playerid][inInventory])
	{
	    PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][slot], ItemsData[itemid][item_model]);
		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][slot], ItemsData[itemid][item_previewrot][0], ItemsData[itemid][item_previewrot][1], ItemsData[itemid][item_previewrot][2], ItemsData[itemid][item_previewrot][3]);

	    PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][slot]);
	   	PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][slot]);
	}
}

stock RemoveItemFromInventory(playerid, slot, amount = 0)
{

    if(amount == 0)
    {
        pInventory[playerid][invSlot][slot] = 0;
		pInventory[playerid][invSlotAmount][slot] = 0;
	}
	else
	{
	    pInventory[playerid][invSlotAmount][slot] -= amount;

	    if(pInventory[playerid][invSlotAmount][slot] == 0)
	        pInventory[playerid][invSlot][slot] = 0;

	}

	if(pInfo[playerid][inInventory])
	{
	    PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][slot], ItemsData[pInventory[playerid][invSlot][slot]][item_model]);
 		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][slot], ItemsData[pInventory[playerid][invSlot][slot]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][slot]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][slot]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][slot]][item_previewrot][3]);
        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][slot], 96);

		PlayerTextDrawHide(playerid, Inventory_index[playerid][slot]);
		PlayerTextDrawShow(playerid, Inventory_index[playerid][slot]);
	}
}

stock RemoveItemFromCharacter(playerid, slot)
{
	if(ItemsData[pCharacter[playerid][charSlot][slot]][item_type] == ITEM_TYPE_WEAPON)
	{
	    new modelid = ItemsData[pCharacter[playerid][charSlot][slot]][item_model];
	    SetPlayerAmmo(playerid, GetWeaponIDFromModel(modelid), 0);

        new itemid = ItemsData[pCharacter[playerid][charSlot][slot]][item_id];

        pCharacter[playerid][charSlot][slot] = 0;

	    if(itemid == 3 || itemid == 9)
	    	if(IsPlayerAttachedObjectSlotUsed(playerid, 3))
     			RemovePlayerAttachedObject(playerid, 3);

        if(itemid == 10)
	    	if(IsPlayerAttachedObjectSlotUsed(playerid, 4))
      			RemovePlayerAttachedObject(playerid, 4);

      	if(itemid == 2)
	    	if(IsPlayerAttachedObjectSlotUsed(playerid, 5))
      			RemovePlayerAttachedObject(playerid, 5);

	}
	else if(ItemsData[pCharacter[playerid][charSlot][slot]][item_type] == ITEM_TYPE_MELEEWEAPON)
	{
	    new modelid = ItemsData[pCharacter[playerid][charSlot][slot]][item_model];
	    RemovePlayerWeapon(playerid, GetWeaponIDFromModel(modelid));

	    if(IsPlayerAttachedObjectSlotUsed(playerid, 6))
      		RemovePlayerAttachedObject(playerid, 6);
	}

	if(slot == 0) // Helmet
	{
	    RemovePlayerAttachedObject(playerid, 0);
	}
	else if(slot == 1) // Armour
	{
	    RemovePlayerAttachedObject(playerid, 1);
	    SetPlayerArmour(playerid, 0);
	    pCharacter[playerid][charArmourStatus] = 0.0;
	}
	else if(slot == 2) // Backpack
	{
	    RemovePlayerAttachedObject(playerid, 2);
	    pCharacter[playerid][charSlot][slot] = 0;

	    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
	    	PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);

        for(new i = 0; i < GetSlotsInventory(playerid); i++)
		{
			PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_model]);
	 		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][3]);
	        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][i], 96);

			PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);
		}
	}

    pCharacter[playerid][charSlot][slot] = 0;
    PlayerPlaySound(playerid,1053,0.0,0.0,0.0);

    if(pInfo[playerid][inInventory])
	{
	    PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][slot], ItemsData[0][item_model]);
	 	PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][slot], ItemsData[0][item_previewrot][0], ItemsData[0][item_previewrot][1], ItemsData[0][item_previewrot][2], ItemsData[0][item_previewrot][3]);
		PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][slot], 96);

	    PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][slot]);
	   	PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][slot]);

	   	PlayerTextDrawHide(playerid, Inventory_textos[playerid][10]);
		TextDrawHideForPlayer(playerid, Inventory_remover);
	}
}
//----------------------------------------------------------

stock DropItem(Float:x, Float:y, Float:z, itemid, amount, Float:armourstatus = 0.0, slotid)
{
    TdmSlotItems[LastItemID[slotid]][slotid][world_timer] = TIMER_ITEM_WORLD;
	TdmSlotItems[LastItemID[slotid]][slotid][world_itemid] = itemid;
	TdmSlotItems[LastItemID[slotid]][slotid][world_model] = ItemsData[itemid][item_model];
	TdmSlotItems[LastItemID[slotid]][slotid][world_amount] = amount;
	TdmSlotItems[LastItemID[slotid]][slotid][world_position][0] = x;
	TdmSlotItems[LastItemID[slotid]][slotid][world_position][1] = y;
	TdmSlotItems[LastItemID[slotid]][slotid][world_position][2] = z;

	if(itemid == 6)
	    TdmSlotItems[LastItemID[slotid]][slotid][world_armourstatus] = armourstatus;

    TdmSlotItems[LastItemID[slotid]][slotid][world_object] = CreateDynamicObject(TdmSlotItems[LastItemID[slotid]][slotid][world_model], x, y, z-0.90, -90,0,0 , slotid+2);

	if(amount > 1)
		format(String, sizeof(String), "%s (%d)", ItemsData[itemid][item_name], amount);
	else
		format(String, sizeof(String), "%s", ItemsData[itemid][item_name]);

	TdmSlotItems[LastItemID[slotid]][slotid][world_3dtext] = CreateDynamic3DTextLabel(String, -1, x, y, z-0.90, 5.0,INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, slotid+2);
	TdmSlotItems[LastItemID[slotid]][slotid][world_active] = true;
	if(LastItemID[slotid] == MAX_ITEMS_SLOT-1)
	LastItemID[slotid] = 0;
	else LastItemID[slotid]++;
}

// Command used to create your own weapons! (Ammostatus if for armour, it is 100.0, if not use 0.0)
CMD:createitem(playerid, params[])
{
   if(!IsPlayerAdmin(playerid)) return SendError(playerid, "You need to admin");

   new itemidx, ammo, Float:POS[3], ammostatus;
   if(sscanf(params, "iii(0.0)", itemidx, ammo,ammostatus)) return SendError(playerid, "/additem <itemid> <ammo> <ammostatus (optional 100)>");
   GetPlayerPos(playerid, POS[0], POS[1], POS[2]);

   format(String, sizeof(String), "You have created Iteam: %i with %i ammo", itemidx, ammo);
   SendClientMessage(playerid, -1, String);

   DropItem(POS[0], POS[1], POS[2], itemidx, ammostatus, 0.0, 0);
   printf("DropItem(%f, %f, %f, %i, %i, %i, slotid);",POS[0], POS[1], POS[2], itemidx, ammo, ammostatus); // Debug
   return 1;
}
//

stock RemoveSlotItem(slotid, itemid)
{
    TdmSlotItems[itemid][slotid][world_active] = false;
    DestroyObject(TdmSlotItems[itemid][slotid][world_object]);
    Delete3DTextLabel(TdmSlotItems[itemid][slotid][world_3dtext]);
}
stock DestroySlotAllItems(slotid)
{
	 for(new i = 0; i < MAX_ITEMS_SLOT; i++)
	 {
	    TdmSlotItems[i][slotid][world_active] = false;
	    DestroyObject(TdmSlotItems[i][slotid][world_object]);
	    Delete3DTextLabel(TdmSlotItems[i][slotid][world_3dtext]);
	 }
}

stock IsItemInInventory(playerid, itemid, amount)
{
	new bool:sucess = false;

    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
         if(pInventory[playerid][invSlot][i] == itemid)
            if(pInventory[playerid][invSlotAmount][i] >= amount)
                sucess = true;

	if(!sucess)
	    return false;
	else
	    return true;
}
stock GetSlotsFree(playerid)
{
	new count = 0;

    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
        if(pInventory[playerid][invSlot][i] == 0)
            count++;

	return count;
}

stock GetSlotsInUse(playerid)
{
    new count = 0;

    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
        if(pInventory[playerid][invSlot][i] != 0)
            count++;

	return count;
}

stock IsInventoryFull(playerid)
{
    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
        if(pInventory[playerid][invSlot][i] == 0)
            return false;

	return true;
}

stock GetSlotsInventory(playerid)
{
    new slots;

	if(pCharacter[playerid][charSlot][2] == 0)
	    slots = 5;
	else if(pCharacter[playerid][charSlot][2] == 7)
	    slots = 10;
    else if(pCharacter[playerid][charSlot][2] == 8)
	    slots = 15;

	return slots;
}



//----------------------------------------------------------

stock GetAmmunation(playerid)
{
	new total;

    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
        if(pInventory[playerid][invSlot][i] == 4)
			total += pInventory[playerid][invSlotAmount][i];

	return total;
}

stock GetAmmunationSlot(playerid)
{
	new slot = -1;

    for(new i = 0; i < GetSlotsInventory(playerid); i ++)
        if(pInventory[playerid][invSlot][i] == 4)
        {
            slot = i;
            break;
		}

	return slot;
}

stock OrganizeInventory(playerid)
{
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
	    if(pInventory[playerid][invSlot][i] != 0)
		    for(new a = 0; a < MAX_INVENTORY_SLOTS; a++)
		        if(pInventory[playerid][invSlot][a] == 0)
		        {
			        pInventory[playerid][invSlot][a] = pInventory[playerid][invSlot][i];
			        pInventory[playerid][invSlotAmount][a] = pInventory[playerid][invSlotAmount][i];
                    pInventory[playerid][invArmourStatus][a] = pInventory[playerid][invArmourStatus][i];
			        pInventory[playerid][invSlot][i] = 0;
			        pInventory[playerid][invSlotAmount][i] = 0;
			        pInventory[playerid][invArmourStatus][i] = 0;
				}
}

stock GetWeaponSlot(weaponid)
{
	new slot;

	switch(weaponid)
	{
		case 0,1: slot = 0;
		case 2 .. 9: slot = 1;
		case 10 .. 15: slot = 10;
		case 16 .. 18, 39: slot = 8;
		case 22 .. 24: slot =2;
		case 25 .. 27: slot = 3;
		case 28, 29, 32: slot = 4;
		case 30, 31: slot = 5;
		case 33, 34: slot = 6;
		case 35 .. 38: slot = 7;
		case 40: slot = 12;
		case 41 .. 43: slot = 9;
		case 44 .. 46: slot = 11;
	}

	return slot;
}

stock ShowPlayerInventory(playerid)
{
    pInfo[playerid][inInventory] = true;
    SelectTextDraw(playerid, 0xFFFFFFFF);

    // Globais

    TextDrawShowForPlayer(playerid, Inventory_close[0]);
	TextDrawShowForPlayer(playerid, Inventory_close[1]);

	for(new i = 0; i < 5; i++)
	    if(i != 4)
	    	TextDrawShowForPlayer(playerid, Inventory_backgrounds[i]);

	// Player

	for(new i = 0; i < GetSlotsInventory(playerid); i++)
	{
		PlayerTextDrawSetPreviewModel(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_model]);
 		PlayerTextDrawSetPreviewRot(playerid, Inventory_index[playerid][i], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][0], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][1], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][2], ItemsData[pInventory[playerid][invSlot][i]][item_previewrot][3]);
        PlayerTextDrawBackgroundColor(playerid, Inventory_index[playerid][i], 96);

		PlayerTextDrawShow(playerid, Inventory_index[playerid][i]);
	}

	PlayerTextDrawSetString(playerid, Inventory_textos[playerid][0], "Character");
	PlayerTextDrawSetString(playerid, Inventory_textos[playerid][1], "Your Inventory");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][2],  "Head");
	PlayerTextDrawSetString(playerid, Inventory_textos[playerid][3], "Backpack");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][4], "Body");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][5], "Weapon");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][6], "Weapon");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][7], "Weapon");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][8], "Weapon");
    PlayerTextDrawSetString(playerid, Inventory_textos[playerid][9], "Use");

	for(new i = 0; i < 11; i++)
	    if(i != 10 && i != 9)
	    	PlayerTextDrawShow(playerid, Inventory_textos[playerid][i]);

	for(new i = 0; i < 7; i++)
	{
	    new char_slot = pCharacter[playerid][charSlot][i];

	    PlayerTextDrawSetPreviewModel(playerid, Inventory_personagemindex[playerid][i], ItemsData[char_slot][item_model]);
 		PlayerTextDrawSetPreviewRot(playerid, Inventory_personagemindex[playerid][i], ItemsData[char_slot][item_previewrot][0], ItemsData[char_slot][item_previewrot][1], ItemsData[char_slot][item_previewrot][2], ItemsData[char_slot][item_previewrot][3]);
        PlayerTextDrawBackgroundColor(playerid, Inventory_personagemindex[playerid][i], 96);

	    PlayerTextDrawShow(playerid, Inventory_personagemindex[playerid][i]);
	}

	PlayerTextDrawSetPreviewModel(playerid, Inventory_skin[playerid], GetPlayerSkin(playerid));
	PlayerTextDrawShow(playerid, Inventory_skin[playerid]);
}


stock HidePlayerInventory(playerid)
{
	TextDrawHideForPlayer(playerid, Inventory_usar);
	TextDrawHideForPlayer(playerid, Inventory_split[0]);
	TextDrawHideForPlayer(playerid, Inventory_split[1]);
	TextDrawHideForPlayer(playerid, Inventory_drop[0]);
	TextDrawHideForPlayer(playerid, Inventory_drop[1]);
	TextDrawHideForPlayer(playerid, Inventory_close[0]);
	TextDrawHideForPlayer(playerid, Inventory_close[1]);

	for(new i = 0; i < 5; i++)
	    if(i != 4)
	    	TextDrawHideForPlayer(playerid, Inventory_backgrounds[i]);

    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
	    PlayerTextDrawHide(playerid, Inventory_index[playerid][i]);

    for(new i = 0; i < 11; i++)
	    PlayerTextDrawHide(playerid, Inventory_textos[playerid][i]);

	for(new i = 0; i < 7; i++)
	    PlayerTextDrawHide(playerid, Inventory_personagemindex[playerid][i]);

	PlayerTextDrawHide(playerid, Inventory_skin[playerid]);
	TextDrawHideForPlayer(playerid, Inventory_remover);

	TextDrawHideForPlayer(playerid, Inventory_backgrounds[4]);

	for(new a = 0; a < 4; a++)
    	PlayerTextDrawHide(playerid, Inventory_description[playerid][a]);

    pInventory[playerid][invSelectedSlot] = -1;
    pCharacter[playerid][charSelectedSlot] = -1;
    pInfo[playerid][inInventory] = false;
    CancelSelectTextDraw(playerid);
}

stock GetWeaponIDFromModel(modelid)
{
    new idweapon;

    switch(modelid)
	{
       	case 331: idweapon = 1; // Brass Knuckles
       	case 333: idweapon = 2; // Golf Club
       	case 334: idweapon = 3; // Nightstick
      	case 335: idweapon = 4; // Knife
       	case 336: idweapon = 5; // Baseball Bat
       	case 337: idweapon = 6; // Shovel
       	case 338: idweapon = 7; // Pool Cue
       	case 339: idweapon = 8; // Katana
       	case 341: idweapon = 9; // Chainsaw
       	case 321: idweapon = 10; // Double-ended Dildo
       	case 325: idweapon = 14; // Flowers
       	case 326: idweapon = 15; // Cane
       	case 342: idweapon = 16; // Grenade
       	case 343: idweapon = 17; // Tear Gas
       	case 344: idweapon = 18; // Molotov Cocktail
       	case 346: idweapon = 22; // 9mm
       	case 347: idweapon = 23; // Silenced 9mm
       	case 348: idweapon = 24; // Desert Eagle
       	case 349: idweapon = 25; // Shotgun
       	case 350: idweapon = 26; // Sawnoff
       	case 351: idweapon = 27; // Combat Shotgun
       	case 352: idweapon = 28; // Micro SMG/Uzi
       	case 353: idweapon = 29; // MP5
       	case 355: idweapon = 30; // AK-47
       	case 356: idweapon = 31; // M4
       	case 372: idweapon = 32; // Tec-9
       	case 357: idweapon = 33; // Country Rifle
       	case 358: idweapon = 34; // Sniper Rifle
       	case 359: idweapon = 35; // RPG
       	case 360: idweapon = 36; // HS Rocket
       	case 361: idweapon = 37; // Flamethrower
       	case 362: idweapon = 38; // Minigun
       	case 363: idweapon = 39;// Satchel Charge + Detonator
       	case 365: idweapon = 41; // Spraycan
       	case 366: idweapon = 42; // Fire Extinguisher
	}

	return idweapon;
}
stock RemovePlayerWeapon(playerid, weaponid)
{
	new plyWeapons[12];
	new plyAmmo[12];

	for(new slot = 0; slot != 12; slot++)
	{
		new wep, ammo;
		GetPlayerWeaponData(playerid, slot, wep, ammo);

		if(wep != weaponid)
		{
			GetPlayerWeaponData(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
		}
	}

	ResetPlayerWeapons(playerid);
	for(new slot = 0; slot != 12; slot++)
	{
		GivePlayerWeapon(playerid, plyWeapons[slot], plyAmmo[slot]);
	}
}

stock ShowMessageInventory(playerid, string[], time = 5000)
{
	if (pInfo[playerid][MessageInventory])
	{
	    PlayerTextDrawHide(playerid, Inventory_mensagem[playerid]);
	    KillTimer(pInfo[playerid][MessageInventoryTimer]);
	}

	PlayerTextDrawSetString(playerid, Inventory_mensagem[playerid], ConvertToGameText(string));
	PlayerTextDrawShow(playerid, Inventory_mensagem[playerid]);

	pInfo[playerid][MessageInventory] = true;
	pInfo[playerid][MessageInventoryTimer] = SetTimerEx("HideMessageInventory", time, false, "d", playerid);
	return true;
}

forward HideMessageInventory(playerid);
public HideMessageInventory(playerid)
{
	if (!pInfo[playerid][MessageInventory])
	    return 0;

	pInfo[playerid][MessageInventory] = false;
	return PlayerTextDrawHide(playerid, Inventory_mensagem[playerid]);
}

//----------------------------------------------------------

stock ConvertToGameText(in[])
{
    new string[256];
    for(new i = 0; in[i]; ++i)
    {
        string[i] = in[i];
        switch(string[i])
        {
            case 0xC0 .. 0xC3: string[i] -= 0x40;
            case 0xC7 .. 0xC9: string[i] -= 0x42;
            case 0xD2 .. 0xD5: string[i] -= 0x44;
            case 0xD9 .. 0xDC: string[i] -= 0x47;
            case 0xE0 .. 0xE3: string[i] -= 0x49;
            case 0xE7 .. 0xEF: string[i] -= 0x4B;
            case 0xF2 .. 0xF5: string[i] -= 0x4D;
            case 0xF9 .. 0xFC: string[i] -= 0x50;
            case 0xC4, 0xE4: string[i] = 0x83;
            case 0xC6, 0xE6: string[i] = 0x84;
            case 0xD6, 0xF6: string[i] = 0x91;
            case 0xD1, 0xF1: string[i] = 0xEC;
            case 0xDF: string[i] = 0x96;
            case 0xBF: string[i] = 0xAF;
        }
    }
    return string;
}

stock CreateTDMWeapons(slotid)
{
 // Blue team
 DropItem(-1998.6827,1758.4679,1.8157, 6, 1, 100.0, slotid);
 DropItem(-1995.8171,1758.1068,1.8229, 6, 1, 100.0, slotid);
 DropItem(-1992.0349,1758.8475,1.8229, 6, 1, 100.0, slotid);
 DropItem(-1990.2214,1749.7703,1.8229, 6, 1, 100.0, slotid);
 DropItem(-2011.9891,1763.6718,1.8651, 2, 1, 0.0, slotid);
 DropItem(-1999.706176, 1831.736938, 1.671720, 2, 1, 0.0, slotid);
 DropItem(-1996.971069, 1831.094238, 1.671720, 2, 1, 0.0, slotid);
 DropItem(-1991.942382, 1832.984375, 1.671720, 2, 1, 0.0, slotid);
 DropItem(-1989.738891, 1829.899047, 1.671720, 2, 1, 0.0, slotid);
 DropItem(-1993.893920, 1824.735107, 1.822887, 2, 1, 0.0, slotid);
 DropItem(-1991.107910, 1805.985717, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1993.872192, 1807.144042, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1995.114624, 1810.834716, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1990.791503, 1801.993286, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1992.581909, 1797.410766, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1994.436279, 1793.355102, 1.815681, 4, 100, 0.0, slotid);
 DropItem(-1990.601806, 1792.662719, 1.815681, 4, 100, 0.0, slotid);
 DropItem(-1997.248168, 1796.543090, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1997.150024, 1793.768310, 1.822887, 4, 100, 0.0, slotid);
 DropItem(-1991.584960, 1811.135009, 1.822887, 4, 120, 0.0, slotid);
 DropItem(-1997.740600, 1808.707153, 1.822887, 1, 1, 0.0, slotid);
 DropItem(-1997.775756, 1805.838623, 1.822887, 1, 1, 0.0, slotid);
 DropItem(-1997.819213, 1802.326904, 1.822887, 1, 1, 0.0, slotid);
 DropItem(-1997.856323, 1799.296386, 1.822887, 1, 1, 0.0, slotid);
 DropItem(-2000.736572, 1813.071777, 1.822887, 7, 1, 0.0, slotid);
 DropItem(-2000.556762, 1811.356567, 1.822887, 7, 1, 0.0, slotid);
 DropItem(-1997.497680, 1817.091674, 1.822887, 7, 1, 0.0, slotid);
 DropItem(-1994.315551, 1817.274169, 1.822887, 7, 1, 0.0, slotid);
 DropItem(-1998.873779, 1816.772583, 1.822887, 8, 1, 0.0, slotid);
 DropItem(-1989.505004, 1816.733032, 1.822887, 8, 1, 0.0, slotid);
 DropItem(-1991.293212, 1820.660522, 1.822887, 3, 60, 0.0, slotid);
 DropItem(-1991.605834, 1823.260986, 1.822887, 3, 60, 0.0, slotid);
 DropItem(-1991.505615, 1826.595336, 1.822887, 3, 60, 0.0, slotid);
 DropItem(-1992.552856, 1829.109985, 1.671720, 3, 60, 0.0, slotid);
 DropItem(-1997.222900, 1821.271606, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1999.789672, 1821.166381, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1999.895507, 1823.575805, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1999.891845, 1825.792358, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1997.826660, 1824.532104, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1999.753784, 1828.124877, 1.822887, 9, 60, 0.0, slotid);
 DropItem(-1990.234741, 1775.629028, 1.815681, 10, 60, 0.0, slotid);
 DropItem(-1990.024780, 1773.934814, 1.815681, 10, 60, 0.0, slotid);
 DropItem(-1990.033569, 1771.023681, 1.815681, 10, 60, 0.0, slotid);
 DropItem(-1989.720947, 1768.504516, 1.815681, 10, 60, 0.0, slotid);
 DropItem(-1991.617919, 1768.158447, 1.815681, 10, 60, 0.0, slotid);
 DropItem(-1994.140136, 1767.845458, 1.815681, 13, 60, 0.0, slotid);
 DropItem(-1996.745117, 1767.522216, 1.815681, 13, 60, 0.0, slotid);
 DropItem(-1998.786132, 1767.269042, 1.815681, 13, 60, 0.0, slotid);
 DropItem(-1999.201782, 1769.723266, 1.815681, 13, 60, 0.0, slotid);
 DropItem(-1997.691894, 1772.124145, 1.815681, 13, 60, 0.0, slotid);
 DropItem(-2013.908569, 1797.636352, 1.865100, 17, 1, 0.0, slotid);
 DropItem(-2014.018310, 1799.447509, 1.865100, 17, 1, 0.0, slotid);
 DropItem(-2013.996459, 1802.411376, 1.865100, 17, 1, 0.0, slotid);
 DropItem(-2014.119750, 1804.449340, 1.865100, 17, 1, 0.0, slotid);
 DropItem(-2013.964721, 1812.372436, 1.865100, 18, 80, 0.0, slotid);
 DropItem(-2013.097167, 1773.533813, 1.865100, 18, 80, 0.0, slotid);
 DropItem(-2012.703002, 1770.878906, 1.865100, 18, 80, 0.0, slotid);
 DropItem(-2012.298095, 1765.812744, 1.865100, 18, 80, 0.0, slotid);
 DropItem(-2011.929809, 1760.793579, 1.865100, 18, 80, 0.0, slotid);
 DropItem(-1991.877319, 1747.010620, 1.822887, 19, 80, 0.0, slotid);
 DropItem(-1993.702880, 1747.770874, 1.822887, 19, 80, 0.0, slotid);
 DropItem(-1996.290771, 1749.073608, 1.822887, 19, 80, 0.0, slotid);
 DropItem(-1996.603149, 1746.387329, 1.822887, 19, 80, 0.0, slotid);
 DropItem(-1995.795043, 1744.549682, 1.822887, 19, 80, 0.0, slotid);
 DropItem(-1999.518432, 1753.706909, 1.822887, 2, 55, 0.0, slotid);
 DropItem(-1996.573242, 1752.962158, 1.822887, 2, 55, 0.0, slotid);
 DropItem(-1994.125732, 1752.939697, 1.822887, 2, 55, 0.0, slotid);
 DropItem(-1991.097778, 1752.911987, 1.822887, 2, 55, 0.0, slotid);
 DropItem(-2010.983520, 1779.642578, 2.674248, 5, 6, 0.0, slotid);
 DropItem(-2008.593994, 1778.117309, 1.865100, 5, 5, 0.0, slotid);
 DropItem(-2011.242065, 1789.961425, 2.701166, 5, 2, 0.0, slotid);
 DropItem(-2008.585571, 1792.002929, 1.865100, 5, 10, 0.0, slotid);

// Red Team
 DropItem(-2242.998046, 1614.893554, 1.776799, 1, 1, 0.0, slotid);
 DropItem(-2239.952148, 1614.859497, 1.776799, 1, 1, 0.0, slotid);
 DropItem(-2236.445556, 1614.945190, 1.776799, 1, 1, 0.0, slotid);
 DropItem(-2233.517089, 1614.966796, 1.776799, 1, 1, 0.0, slotid);
 DropItem(-2241.486328, 1623.973999, 1.776799, 6, 1, 100.0, slotid);
 DropItem(-2241.770019, 1628.431274, 1.776799, 6, 1, 100.0, slotid);
 DropItem(-2242.236328, 1621.897460, 1.776799, 6, 1, 100.0, slotid);
 DropItem(-2243.423828, 1618.944335, 1.776799, 6, 1, 100.0, slotid);
 DropItem(-2236.161376, 1623.805419, 1.776799, 7, 1, 100.0, slotid);
 DropItem(-2235.969970, 1620.915771, 1.776799, 8, 1, 100.0, slotid);
 DropItem(-2233.691650, 1627.590820, 1.776799, 7, 1, 100.0, slotid);
 DropItem(-2231.213867, 1627.548095, 1.776799, 8, 1, 100.0, slotid);
 DropItem(-2217.464355, 1619.800292, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2219.481201, 1617.406738, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2217.288330, 1615.825073, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2221.757568, 1615.219970, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2223.037353, 1617.973510, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2217.037109, 1627.360717, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2217.168457, 1630.538452, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2219.488037, 1630.843750, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2222.198974, 1629.168823, 1.776799, 4, 100, 0.0, slotid);
 DropItem(-2248.230468, 1629.378051, 2.368912, 4, 100, 0.0, slotid);
 DropItem(-2251.389160, 1623.464477, 2.964392, 4, 100, 0.0, slotid);
 DropItem(-2260.721923, 1618.626953, 2.418757, 4, 100, 0.0, slotid);
 DropItem(-2270.808105, 1615.562622, 2.331974, 4, 100, 0.0, slotid);
 DropItem(-2269.414794, 1631.971679, 2.368912, 4, 100, 0.0, slotid);
 DropItem(-2270.394287, 1630.008422, 2.362927, 4, 100, 0.0, slotid);
 DropItem(-2272.052734, 1627.843627, 2.325138, 4, 100, 0.0, slotid);
 DropItem(-2273.139892, 1629.833251, 2.349138, 4, 100, 0.0, slotid);
 DropItem(-2262.241943, 1626.209350, 2.352157, 2, 100, 0.0, slotid);
 DropItem(-2262.402099, 1629.146606, 2.368912, 2, 100, 0.0, slotid);
 DropItem(-2262.385498, 1631.930664, 2.368912, 2, 100, 0.0, slotid);
 DropItem(-2266.689453, 1631.440063, 2.368912, 3, 100, 0.0, slotid);
 DropItem(-2267.185791, 1628.599975, 2.356253, 3, 100, 0.0, slotid);
 DropItem(-2267.596435, 1626.253051, 2.339574, 3, 100, 0.0, slotid);
 DropItem(-2275.116210, 1618.916748, 2.454986, 3, 100, 0.0, slotid);
 DropItem(-2275.317138, 1615.433715, 2.483531, 3, 100, 0.0, slotid);
 DropItem(-2273.258544, 1620.042480, 2.444821, 2, 100, 0.0, slotid);
 DropItem(-2271.839843, 1636.150146, 2.517349, 2, 100, 0.0, slotid);
 DropItem(-2270.276123, 1640.082763, 2.517349, 3, 100, 0.0, slotid);
 DropItem(-2269.797119, 1643.320434, 2.517349, 3, 100, 0.0, slotid);
 DropItem(-2267.884033, 1645.721557, 2.517349, 2, 100, 0.0, slotid);
 DropItem(-2248.462890, 1646.422729, 1.776799, 9, 100, 0.0, slotid);
 DropItem(-2251.325195, 1646.786621, 1.776799, 9, 100, 0.0, slotid);
 DropItem(-2250.037597, 1649.822265, 1.776799, 9, 100, 0.0, slotid);
 DropItem(-2252.800292, 1651.649658, 1.654789, 9, 100, 0.0, slotid);
 DropItem(-2254.016601, 1654.687988, 1.654789, 9, 100, 0.0, slotid);
 DropItem(-2249.747558, 1655.699951, 1.776799, 9, 100, 0.0, slotid);
 DropItem(-2221.152832, 1657.896972, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2218.635009, 1657.159790, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2214.815917, 1657.633544, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2222.548339, 1657.945312, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2222.351318, 1655.903564, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2219.572021, 1655.857543, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2216.628173, 1655.808593, 1.776799, 10, 100, 0.0, slotid);
 DropItem(-2247.949462, 1664.239868, 1.776799, 15, 100, 0.0, slotid);
 DropItem(-2248.392333, 1667.400634, 1.776799, 15, 100, 0.0, slotid);
 DropItem(-2248.290771, 1671.605102, 1.776799, 15, 100, 0.0, slotid);
 DropItem(-2245.395263, 1669.255981, 1.776799, 15, 100, 0.0, slotid);
 DropItem(-2224.926513, 1667.573730, 1.776799, 18, 1, 0.0, slotid);
 DropItem(-2222.438964, 1669.345825, 1.776799, 18, 1, 0.0, slotid);
 DropItem(-2218.827880, 1670.250488, 1.776799, 18, 1, 0.0, slotid);
 DropItem(-2215.251220, 1669.769165, 1.776799, 18, 1, 0.0, slotid);
 DropItem(-2230.560058, 1660.036499, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2234.126464, 1660.362548, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2234.004394, 1662.923095, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2233.688964, 1666.357177, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2231.129882, 1664.792480, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2233.339843, 1667.250488, 1.776799, 16, 100, 0.0, slotid);
 DropItem(-2237.121337, 1669.042846, 1.776799, 17, 100, 0.0, slotid);
 DropItem(-2241.277099, 1671.868041, 1.776799, 17, 100, 0.0, slotid);
 DropItem(-2237.636230, 1672.833496, 1.776799, 17, 100, 0.0, slotid);
 DropItem(-2233.741943, 1672.179809, 1.776799, 17, 100, 0.0, slotid);
 DropItem(-2236.172363, 1674.619995, 1.776799, 17, 100, 0.0, slotid);
 DropItem(-2245.069335, 1675.434326, 1.776799, 19, 100, 0.0, slotid);
 DropItem(-2251.303955, 1675.490112, 1.776799, 19, 100, 0.0, slotid);
 DropItem(-2250.892822, 1679.376831, 1.776799, 19, 100, 0.0, slotid);
 DropItem(-2247.826416, 1679.755493, 1.776799, 19, 100, 0.0, slotid);
 DropItem(-2248.672363, 1682.457641, 1.776799, 19, 100, 0.0, slotid);
 DropItem(-2254.428955, 1689.688476, 2.284772, 5, 5, 0.0, slotid);
 DropItem(-2257.185791, 1689.258300, 2.876073, 5, 5, 0.0, slotid);
 DropItem(-2261.387695, 1688.292114, 2.771282, 5, 5, 0.0, slotid);
 DropItem(-2264.424804, 1687.481323, 1.949516, 5, 5, 0.0, slotid);
 DropItem(-2241.724365, 1691.948486, 1.776799, 5, 5, 0.0, slotid);
 DropItem(-2238.254638, 1692.256347, 1.776799, 4, 200, 0.0, slotid);
 DropItem(-2236.690917, 1694.067138, 1.776799, 4, 200, 0.0, slotid);
 DropItem(-2238.183105, 1698.086914, 1.776799, 4, 200, 0.0, slotid);
 DropItem(-2241.283203, 1698.629272, 1.776799, 4, 200, 0.0, slotid);

}
stock ResetPlayerInventory(playerid)
{
    // Inventory

    for(new i = 0; i < MAX_INVENTORY_SLOTS; i ++)
    {
        pInventory[playerid][invSlot][i] = 0;
        pInventory[playerid][invSlotAmount][i] = 0;
        pInventory[playerid][invArmourStatus][i] = 0;
	}

	// Character
	for(new i = 0; i < 7; i ++)
        pCharacter[playerid][charSlot][i] = 0;

	pCharacter[playerid][charArmourStatus] = 0;
	pCharacter[playerid][charSelectedSlot] = 0;

    pInfo[playerid][inInventory] = false;
    pInfo[playerid][MessageInventory] = false;
    pInfo[playerid][MessageInventoryTimer] = -1;
}

// ======================= End =======================
