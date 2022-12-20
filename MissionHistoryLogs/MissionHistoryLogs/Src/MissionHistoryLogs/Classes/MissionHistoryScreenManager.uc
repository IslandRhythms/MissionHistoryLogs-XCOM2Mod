// This is an Unreal Script

class MissionHistoryScreenManager extends Object


simulated static function WipeLogs() {
	default.CurrentEntries.Length = 0;
	StaticSaveConfig();
}
// TODO: function that adds an entry into the array
simulated static function AppendEntry(string rating) {
	local XComGameState_BattleData BattleData;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int CampaignIndex, MapIndex;
	local MissionHistoryLogsDetails ItemData;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local array<PlotDefinition> ValidPlots;
	local XComParcelManager ParcelManager;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionDetails;
	local XComGameState_ResistanceFaction Faction;
	local XComGameState_AdventChosen ChosenState;
	local ChosenInformation MiniBoss;
	local int Index;
	local string ChosenName;
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;
	local XComGameState_MissionHistoryLogs Logs;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	MissionDetails = XComGameState_MissionSite(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionSite', true));
	Logs = XComGameState_MissionHistoryLogs(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionHistoryLogs', true));
	// This will get the correct squad on a mission
	if(IsModActive('SquadManager')) {
		SquadMgr = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWSquadManager', true));
		// Squad = SquadMgr.GetSquadAfterMission(MissionDetails.ObjectID);
		Squad = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadMgr.LastMissionSquad.ObjectID));
		`log("what is squad name"@Squad.sSquadName);
		if (Squad.sSquadName != "") {
			ItemData.Squad = Squad.sSquadName;
		} else {
			`log("The squad name is empty for some reason");
			ItemData.Squad = "XCOM";
		}
	} else {
		// can also take approach of listing Unit nicknames that were on the mission.
		ItemData.Squad = "XCOM";
	}
	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
	`log("AlienHQ retrieved");
	Faction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(MissionDetails.ResistanceFaction.ObjectID));
	`log("Faction Retrieved");
	ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(AlienHQ.LastAttackingChosen.ObjectID));
	`log("Chosen retrieved");
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	`log("Mission Template Manager Retrieved");
	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	`log("History Retrieved");
	// we need to keep track of this because any variable that could help us do this is only valid in the tactical layer.
	// for some reason when it gets to strategy, any variable that could help us determine if the chosen was on the most recent mission gets wiped.
	if (ChosenState.FirstName == "") {
		`log("there wa no chosen");
		ItemData.Enemies = "Advent";
	}
	else if (ChosenState.numEncounters == 1) {
		`log("our first encounter with this chosen");
		MiniBoss.ChosenType = string(ChosenState.GetMyTemplateName());
		MiniBoss.ChosenType = Split(MiniBoss.ChosenType, "_", true);
		MiniBoss.ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
		MiniBoss.numEncounters = 1;
		MiniBoss.CampaignIndex = CampaignIndex;
		default.TheChosen.AddItem(MiniBoss);
		ItemData.ChosenName = MiniBoss.ChosenName;
		ItemData.Enemies = MiniBoss.ChosenType;
	} else if (ChosenState.numEncounters > 1) {
		`log("we've encountered them before");
		for (Index = 0; Index < default.TheChosen.Length; Index++) {
			ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
			if (default.TheChosen[Index].CampaignIndex == CampaignIndex && default.TheChosen[Index].ChosenName == ChosenName && default.TheChosen[Index].numEncounters != ChosenState.numEncounters) {
				default.TheChosen[Index].numEncounters = ChosenState.numEncounters;
				ItemData.ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
				ItemData.Enemies = default.TheChosen[Index].ChosenType;
				break;
			}
		}
	} else {
		`log("Some weird case we didn't cover");
		ItemData.Enemies = "Advent";
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`log("got battle data");
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleData.MapData.ActiveMission.MissionName);
	`log("Got mission template");
	ParcelManager = `PARCELMGR;
	ParcelManager.GetValidPlotsForMission(ValidPlots, BattleData.MapData.ActiveMission);

	for( MapIndex = 0; MapIndex < ValidPlots.Length; MapIndex++ )
	{
		if( ValidPlots[MapIndex].MapName == BattleData.MapData.PlotMapName )
		{
			ItemData.MapName = class'UITLE_SkirmishModeMenu'.static.GetLocalizedMapTypeName(ValidPlots[MapIndex].strType);
			ItemData.MapImagePath = `MAPS.SelectMapImage(ValidPlots[MapIndex].strType);
			continue;
		}
	}
	`log("got the parcel manager and map name and map image");
	ItemData.CampaignIndex = CampaignIndex;
	ItemData.EntryIndex = default.CurrentEntries.Length + 1;
	ItemData.Date = class 'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true);
	ItemData.MissionName = BattleData.m_strOpName;
	// Gatecrasher's objective is the same as the op name and thats lame.
	if (BattleData.m_strOpName == "Operation Gatecrasher") {
		ItemData.MissionObjective = "Send a Message";
	} else {
		ItemData.MissionObjective = MissionTemplate.DisplayName;
	}
	ItemData.MissionLocation = BattleData.m_strLocation;
	ItemData.MissionRating = rating;
	// run this function now so the math doesn't get messed up.
	// we do this now so if they save scum after the fact nothing gets messed up in the "db"
	CheckForDuplicates(ItemData);
	`log("duplicates were checked for");
	// win
	if (BattleData.AllStrategyObjectivesCompleted()) {
		`log("its a win");
		ItemData.wins = default.CurrentEntries[default.CurrentEntries.Length - 1].wins + 1.0;
		ItemData.SuccessRate = (ItemData.wins/ (default.CurrentEntries.Length + 1.0)) * 100 $ "%";
		`log("math has finished");
	} else {
	// loss
		`log("its a loss");
		ItemData.wins = default.CurrentEntries[default.CurrentEntries.Length - 1].wins;
		ItemData.SuccessRate = (default.CurrentEntries[default.CurrentEntries.Length - 1].wins / (default.CurrentEntries.Length + 1.0)) * 100 $ "%";
		`log("math has finished");
	}
	ItemData.QuestGiver = Faction.FactionName;
	`log("faction name assigned");
	default.CurrentEntries.AddItem(ItemData);
	`log("added into current campaign data");
	default.AllEntries.AddItem(ItemData);
	`log("added into db");
	// StaticSaveConfig();
	`log("everything was saved");
}

// TODO: function that updates the local array to match the DB

// TODO: function that updates both the local array and DB

static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}

static simulated function string GetMissionRating(int injured, int captured, int killed, int total)
{
	local int iKilled, iInjured, iPercentageKilled, iCaptured;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	iKilled = killed;
	iCaptured = captured;
	iPercentageKilled = ((iKilled + iCaptured) * 100) / total;
	iInjured = injured;
	if (!BattleData.AllStrategyObjectivesCompleted()) {
		return "Poor";
	}
	else if((iKilled + iCaptured) == 0 && iInjured == 0)
	{
		return "Flawless";
	}
	else if((iKilled + iCaptured) == 0)
	{
		return "Excellent";
	}
	else if(iPercentageKilled <= 34)
	{
		return "Good";
	}
	else if(iPercentageKilled <= 50)
	{
		return "Fair";
	}
	else
	{
		return "Poor";
	}
}

// use date and operation name and campaign index as the unique identifier
simulated static function CheckForDuplicates(MissionHistoryLogsDetails Item) {
	local int i;
	if (default.AllEntries.Length < 2) return;
	if (default.CurrentEntries.Length < 2) return;

	for (i = 0; i < default.AllEntries.Length; i++) {
		if (Item.CampaignIndex == default.AllEntries[i].CampaignIndex) {
			if (Item.Date == default.AllEntries[i].Date) {
				if (Item.MissionName == default.AllEntries[i].MissionName) {
					// we can confidently remove this entry.
					default.AllEntries.Remove(i, 1);
					// decrease i so we can go through all entries since we just shortened the array;
					i--;
				}
			}
		}
	}
	// we have to go through current entries for the math calculations
	for (i = 0; i < default.CurrentEntries.Length; i++) {
		if (Item.CampaignIndex == default.CurrentEntries[i].CampaignIndex) {
			if (Item.Date == default.CurrentEntries[i].Date) {
				if (Item.MissionName == default.CurrentEntries[i].MissionName) {
					// we can confidently remove this entry.
					default.CurrentEntries.Remove(i, 1);
					// decrease i so we can go through all entries since we just shortened the array;
					i--;
				}
			}
		}
	}
}

// Current Entries is wiped whenever the Screen is opened so that one doesn't need to be managed.
simulated static function ManageMemory() {
	 local int i, max, MostRecentCampaignIndex, OldestCampaignIndex;

	 max = 10;
	// sort by the chosen first since it will be most likely smaller
	default.TheChosen.Sort(SortByChosenCampaignIndex);
	// easier to read
	MostRecentCampaignIndex = default.TheChosen[default.TheChosen.Length - 1].CampaignIndex;
	OldestCampaignIndex = default.TheChosen[0].CampaignIndex;
	// start removing data
	if (MostRecentCampaignIndex - OldestCampaignIndex > max) { // could make max a config variable if for whatever reason someone makes a lot of campaigns and complains
		// sort since we're commiting to this.
		default.AllEntries.Sort(SortByCampaignIndex);
		
		for (i = 0; i < default.TheChosen.Length; i++) {
			if (MostRecentCampaignIndex - default.TheChosen[i].CampaignIndex > max) {
				default.TheChosen.Remove(i, 1);
				i--;
			}
		}
		MostRecentCampaignIndex = default.AllEntries[default.AllEntries.Length - 1].CampaignIndex;
		for (i = 0; i < default.AllEntries.Length; i++) {
			if (MostRecentCampaignIndex - default.AllEntries[i].CampaignIndex > max) {
				default.AllEntries.Remove(i, 1);
				i--;
			}
		}
	} else {
		// all good under the hood
		return;
	}


}

simulated static function int SortByCampaignIndex(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return A.CampaignIndex < B.CampaignIndex ? 1 : 0; 
}

simulated static function int SortByChosenCampaignIndex(ChosenInformation A, ChosenInformation B) {
	return A.CampaignIndex < B.CampaignIndex ? 1 : 0; 
}