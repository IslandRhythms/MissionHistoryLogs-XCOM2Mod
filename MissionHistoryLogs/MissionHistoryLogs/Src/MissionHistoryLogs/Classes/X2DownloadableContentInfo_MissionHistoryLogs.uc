//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_MissionHistoryLogs.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_MissionHistoryLogs extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

static event OnPostMission()
{
	local XComGameState_MissionHistoryLogs Log;
	local XComGameStateContext_ChangeContainer Container;
	local XComGameState UpdateState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	Container = class 'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Mission History Logs Update");
	UpdateState = History.CreateNewGameState(true, Container);
	Log = History.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true);
	Log.UpdateTableDate();

	`GAMERULES.SubmitGameState(UpdateState);
}