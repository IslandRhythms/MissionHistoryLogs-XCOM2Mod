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
	local int injured, captured, killed, total;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local string rating;

	`log("====================Begin Mission History Log=======================");
	injured = 0;
	captured = 0;
	killed = 0;
	total = 0;
	// Units can be both captured and injured as well as according to the game.
	// Units can be dead and injured according to the game (I think) if(arrUnits[i].kAppearance.bGhostPawn)?
	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit.WasInjuredOnMission()) {
			injured++;
		}
		if (Unit.bCaptured) {
			captured++;
		} else if (Unit.IsDead()) {
			killed++;
		}
		total++;

	}
	rating = class 'MissionHistoryScreenManager'.static.GetMissionRating(injured, captured, killed, total);
	class 'MissionHistoryScreenManager'.static.AppendEntry(rating);
}