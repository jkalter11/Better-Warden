/*
 * Better Warden - Catch
 * By: Hypr
 * https://github.com/condolent/BetterWarden/
 * 
 * Copyright (C) 2017 Jonathan Öhrström (Hypr/Condolent)
 *
 * This file is part of the BetterWarden SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <betterwarden>
#include <wardenmenu>
#include <colorvariables>
#include <smlib>
#include <BetterWarden/catch>

#pragma semicolon 1
#pragma newdecls required

bool IsCatchActive;

public Plugin myinfo = {
	name = "[BetterWarden] Catch",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("initCatch", Native_initCatch);
	RegPluginLibrary("catch"); // Register library so main plugin can check if this is loaded
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Catch.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig(true, "Catch", "BetterWarden");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(IsCatchActive == true) // If catch is still active for some reason
		IsCatchActive = false;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(IsCatchActive == true) { // If catch is active
		int aliveT = GetTeamAliveClientCount(CS_TEAM_T);
		
		if(aliveT == 1) // If we have a winner
			EndCatch();
	}
}

public Action OnClientTouch(int client, int other) {
	if(IsCatchActive == false) // Don't do anything if Catch ain't active
		return Plugin_Continue;
	if(!IsValidClient(client) || !IsValidClient(other)) // Make sure client !bot & alive
		return Plugin_Continue;
	
	if(GetClientTeam(client) != CS_TEAM_CT || GetClientTeam(other) != CS_TEAM_T) // No teamkilling and no CT's being killed
		return Plugin_Continue;
		
	ForcePlayerSuicide(other);
	CPrintToChatAll("%s %t", prefix, "Player Caught T", client, other);
	
	return Plugin_Handled;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(IsCatchActive == false) // Don't do anything if Catch ain't active
		return Plugin_Continue;
	
	if(!IsValidClient(inflictor) || !IsValidClient(victim))
		return Plugin_Continue;
	
	CPrintToChat(inflictor, "%s {red}%t", prefix, "No Shooting in Catch");
	return Plugin_Handled;
}

public void EndCatch() { // End the whole game and choose a winner
	if(IsCatchActive == true) {
		int winner;
		
		IsCatchActive = false;
		IsGameActive = false;
		
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			
			GivePlayerItem(i, "weapon_knife");
			
			if(GetClientTeam(i) == CS_TEAM_CT) {
				GivePlayerItem(i, "weapon_fiveseven");
				GivePlayerItem(i, "weapon_m4a1");
			}
			
			if(GetClientTeam(i) != CS_TEAM_T)
				continue;
			winner = i;
			break;
		}
		
		CPrintToChatAll("%s %t", prefix, "Catch Over", winner);
		
	}
}

public Action OnClientCommand(int client, int args) { // If a client starts a Last Request during catch, deny it!
	char cmd[64];
	GetCmdArg(0, cmd, sizeof(cmd));
	
	if(IsCatchActive == false)
		return Plugin_Continue;
	
	if((StrEqual(cmd, "sm_lr", false) != true) || (StrEqual(cmd, "sm_lastrequest", false) != true))
		return Plugin_Continue;
	
	CPrintToChat(client, "%s %t", prefix, "No LR During Catch");
	return Plugin_Handled;
}

/****************
*    NATIVES
****************/
public int Native_initCatch(Handle plugin, int numParams) { // Called to start the game
	if(IsCatchActive == true) {
		return false;
	}
	
	IsCatchActive = true;
	IsGameActive = true;
	CPrintToChatAll("%s %t", prefix, "Catch initiated");
	CPrintToChatTeam(CS_TEAM_CT, "%s %t", prefix, "Info CT");
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		Client_RemoveAllWeapons(i);
		SDKHook(i, SDKHook_Touch, OnClientTouch);
		SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	return true;
}