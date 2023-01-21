// This is an Unreal Script
/*
	Author: Beat
	Had to create a XComGameState because StaticSaveConfig() was causing a crash.
*/
class XComGameState_MissionHistoryLogs extends XComGameState_BaseObject;

// 5 of these are on the top. MissionImagePath is non-negotiable
// Another 5 on the bottom
// 10 will be used, the rest go into the detailed view
struct MissionHistoryLogsDetails {
	var int CampaignIndex;
	var int EntryIndex; // This is to keep track of where the entry was added into the CurrentEntries array;
	var int NumSoldiersDeployed;
	var int NumSoldiersKilled; 
	var int NumSoldiersMIA;
	var int NumSoldiersInjured;
	var int ForceLevel;
	var int NumChosenEncounters;
	var float WinPercentageAgainstChosen;
	var float Wins;
	var string SuccessRate;
	var string Date;
	var string MissionName;
	var string MissionObjective;
	var string MapName;
	var string MapImagePath;
	var string ObjectiveImagePath;
	var string SoldierMVP; // Calculated by function
	var string SquadName;
	var string Enemies;
	var string ChosenName;
	var string QuestGiver; // Reapers, Skirmishers, Templars, The Council
	var string MissionRating; // Poor, Good, Fair, Excellent, Flawless.
	var string MissionLocation; // city and country of the mission
	var bool bIsVIPMission;
	var string VIP;
	var string SoldierVIPOne;
	var string SoldierVIPTwo;
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var int NumEncounters; // XComGameState_AdventChosen.NumEncounters
	var int NumDefeats; // How many times has XCOM defeated this chosen
	var int CampaignIndex;
};

struct SquadInformation {
	var string SquadName;
	var string SoldierNames; // This may not be the same as the soldiers that were on the mission, and thats fine.
	var float numMissions; // declare as float for easier math later
	var float numWins;
};


var array<MissionHistoryLogsDetails> TableData;
// fireaxis why
var array<ChosenInformation> TheChosen;

var array<SquadInformation> SquadData;


function UpdateTableData() {
	local int injured, captured, killed, total, Index, CampaignIndex, MapIndex;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local string rating, ChosenName;
	local XComGameState_BattleData BattleData;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_HeadquartersAlien AlienHQ;
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
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;

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
	rating = GetMissionRating(injured, captured, killed, total);

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	MissionDetails = XComGameState_MissionSite(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionSite', true));
	// This will get the correct squad on a mission
	if(IsModActive('SquadManager')) {
		SquadMgr = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LWSquadManager', true));
		// Squad = SquadMgr.GetSquadAfterMission(MissionDetails.ObjectID);
		Squad = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadMgr.LastMissionSquad.ObjectID));
		`log("what is squad name"@Squad.sSquadName);
		if (Squad.sSquadName != "") {
			ItemData.SquadName = Squad.sSquadName;
		} else {
			`log("The squad name is empty for some reason");
			ItemData.SquadName = "XCOM";
		}
	} else {
		// can also take approach of listing Unit nicknames that were on the mission.
		// we'll do this for now.
		ItemData.SquadName = "XCOM";
	}
	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
	Faction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(MissionDetails.ResistanceFaction.ObjectID));
	ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(AlienHQ.LastAttackingChosen.ObjectID));
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ItemData.bIsVIPMission = MissionDetails.IsVIPMission();
	if (ItemData.bIsVIPMission) {
	// need to check if everyone was rescued before assigning.
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BattleData.RewardUnits[0].ObjectID));
		if (!Unit.IsDead()) {
			ItemData.VIP = Unit.GetFullName();
		} 
		// Soldier A and Soldier B
		if (BattleData.RewardUnits.Length > 2) {
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BattleData.RewardUnits[1].ObjectID));
			if (!Unit.IsDead()) {
				ItemData.SoldierVIPOne = Unit.GetFullName();
			}
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BattleData.RewardUnits[2].ObjectID));
			if (!Unit.IsDead()) {
				ItemData.SoldierVIPTwo = Unit.GetFullName();
			}
		} else if (BattleData.RewardUnits.Length > 1) { // Only Soldier A
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BattleData.RewardUnits[1].ObjectID));
			if (!Unit.IsDead()) {
				ItemData.SoldierVIPOne = Unit.GetFullName();
			}
		}
	}
	// we need to keep track of when the chosen is encountered because any variable that could help us do this is only valid in the tactical layer.
	// for some reason when it gets to strategy, any variable that could help us determine if the chosen was on the most recent mission gets wiped.
	`log("This is how we'll know if the chosen was on the mission hopefully"@BattleData.ChosenRef.ObjectID);
	if (BattleData.ChosenRef.ObjectID == 0) {
		ItemData.Enemies = "Advent";
	} else {
		ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
		ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
		// if we are checking that they weren't on the last mission, then this number should increase correctly.
		if (ChosenState.NumEncounters == 1) {
			`log("our first encounter with this chosen");
			MiniBoss.ChosenType = string(ChosenState.GetMyTemplateName());
			MiniBoss.ChosenType = Split(MiniBoss.ChosenType, "_", true);
			MiniBoss.ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
			MiniBoss.NumEncounters = 1;
			MiniBoss.CampaignIndex = CampaignIndex;
			if (BattleData.bChosenLost) {
				MiniBoss.NumDefeats += 1;
			}
			TheChosen.AddItem(MiniBoss);
			ItemData.ChosenName = MiniBoss.ChosenName;
			ItemData.Enemies = MiniBoss.ChosenType;
			ItemData.NumChosenEncounters = ChosenState.NumEncounters;
			ItemData.WinPercentageAgainstChosen = float(MiniBoss.NumDefeats / MiniBoss.NumEncounters);
			`log("Win Percentage is"@ItemData.WinPercentageAgainstChosen);
		} else {
			`log("we've encountered them before");
			for (Index = 0; Index < TheChosen.Length; Index++) {
				ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
				if (TheChosen[Index].ChosenName == ChosenName && TheChosen[Index].NumEncounters != ChosenState.NumEncounters) {
					TheChosen[Index].NumEncounters = ChosenState.NumEncounters;
					if(BattleData.bChosenLost) {
						`log("the chosen was defeated this mission");
						TheChosen[Index].NumDefeats += 1;
					}
					ItemData.ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
					ItemData.Enemies = TheChosen[Index].ChosenType;
					ItemData.NumChosenEncounters = TheChosen[Index].NumEncounters;
					`log("what is the number of encounters"@ChosenState.NumEncounters);
					`log("what is the number of defeats"@ChosenState.NumDefeats);
					ItemData.WinPercentageAgainstChosen = float(TheChosen[Index].NumDefeats / TheChosen[Index].NumEncounters);
					break;
				}
			}
		}
	}

	ItemData.ForceLevel = BattleData.GetForceLevel();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleData.MapData.ActiveMission.MissionName);
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
	ItemData.CampaignIndex = CampaignIndex;
	ItemData.EntryIndex = TableData.Length + 1;
	ItemData.Date = class 'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true);
	ItemData.MissionName = BattleData.m_strOpName;
	// Gatecrasher's objective is the same as the op name and thats lame.
	// Gatecrasher seems to be a special case
	if (BattleData.m_strOpName == "Operation Gatecrasher") {
		ItemData.MissionObjective = "Send a Message";
		ItemData.ObjectiveImagePath = "uilibrary_strategyimages.X2StrategyMap.Alert_Resistance_Ops_Appear";
	} else {
		ItemData.MissionObjective = MissionTemplate.DisplayName;
		ItemData.ObjectiveImagePath = GetObjectiveImagePath(MissionTemplate.DisplayName);
	}
	ItemData.MissionLocation = BattleData.m_strLocation;
	ItemData.MissionRating = rating;
	ItemData.NumSoldiersDeployed = total;
	ItemData.NumSoldiersKilled = killed;
	ItemData.NumSoldiersMIA = captured;
	ItemData.NumSoldiersInjured = injured;
	ItemData.SoldierMVP = CalculateMissionMVP();
	if (TableData.Length > 1) {
		TableData.Sort(sortByEntryIndex);
	}
	// keep this check the same as the UI to avoid headaches
	if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted) {
		ItemData.Wins = TableData[TableData.Length - 1].Wins + 1.0;
		ItemData.SuccessRate = (ItemData.Wins/ (TableData.Length + 1.0)) * 100 $ "%";
	} else {
		ItemData.Wins = TableData[TableData.Length - 1].Wins;
		ItemData.SuccessRate = (TableData[TableData.Length - 1].Wins / (TableData.Length + 1.0)) * 100 $ "%";
	}
	if (Faction.FactionName == "") {
		ItemData.QuestGiver = "The Council";
	} else {
		ItemData.QuestGiver = Faction.FactionName;
	}
	TableData.AddItem(ItemData);
}

function int sortByWins(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return sortNumerically(A.Wins, B.Wins);
}

function int sortByEntryIndex(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return sortNumerically(A.EntryIndex, B.EntryIndex);
}
// we want the entry with the greatest number to be the last entry.
function int sortNumerically(float A, float B) {
	if (A < B) {
		return 1;
	} else if (A > B) {
		return -1;
	} else {
		return 0;
	}
}


function bool IsModActive(name ModName)
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

function string GetMissionRating(int injured, int captured, int killed, int total)
{
	local int iKilled, iInjured, iPercentageKilled, iCaptured;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (!BattleData.bLocalPlayerWon) {
		return "Poor";
	}
	iKilled = killed;
	iCaptured = captured;
	iPercentageKilled = ((iKilled + iCaptured) * 100) / total;
	iInjured = injured;
	
	if((iKilled + iCaptured) == 0 && iInjured == 0)
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

/*
* The reason this function exists is that for some reason, once we've exited the tactical layer,
* any data that we would need to get an accurate number is wiped.
* As a result, the only way to get a somewhat accurate number is the below function.
* The function gets the Unit's kill stat for the mission and we simply add them all together.
* The flaw of this function is that it does not count cases where XCOM did not directly kill the enemy unit.
* For example: If XCOM throws a grenade at an enemy that does not kill them, but the floor collapses and they die from the fall damage,
* no unit is credited with the kill.
*/
function GetTotalEnemiesKilled(out int NumEnemiesKilled) {
	local StateObjectReference UnitRef;
	local XComGameState_Analytics Analytics;
	local float kills;
	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	foreach `XCOMHQ.Squad(UnitRef) {
		kills = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_KILLS"));
		NumEnemiesKilled += kills;
	}
}
/*
* Calculates the MVP of the mission
* attacks survived, kills, shots hit, hit %, attacks made, damage
* rank of stats are from highest to lowest reading from left to right
*/
function string CalculateMissionMVP() {
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local XComGameState_Analytics Analytics;
	local String MVP, Challenger;
	local float ShotsMade;
	local float MVPHitPercentage, MVPAttacksMade, MVPDamageDealt, MVPAttacksSurvived, MVPShotsHit, MVPKills;
	local float ChallengerHitPercentage, ChallengerAttacksMade, ChallengerDamageDealt, ChallengerAttacksSurvived, ChallengerShotsHit, ChallengerKills;
	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	// a dead/captured soldier can be the mvp. If they died/got captured but did better than the other units they should get it.
	foreach `XCOMHQ.Squad(UnitRef)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
			if (MVP == "") {
				// Assign MVP to be the first name + nickname + lastname
				MVP = Unit.GetName(eNameType_FullNick);
				ShotsMade = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SHOTS_TAKEN"));
				MVPShotsHit = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SUCCESS_SHOTS"));
				MVPHitPercentage = MVPShotsHit/ShotsMade;
				MVPKills = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_KILLS"));
				MVPAttacksMade = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SUCCESSFUL_ATTACKS"));
				MVPDamageDealt = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_DEALT_DAMAGE"));
				MVPAttacksSurvived = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_ABILITIES_RECEIVED"));
			} else {
				// Compare MVP against next soldier in the squad
				Challenger = Unit.GetName(eNameType_FullNick);
				ChallengerAttacksSurvived = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_ABILITIES_RECEIVED"));
				if(MVPAttacksSurvived < ChallengerAttacksSurvived) {
					MVP = Challenger;
					continue;
				}
				ChallengerKills = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_KILLS"));
				if (MVPKills < ChallengerKills) {
					MVP = Challenger;
					continue;
				}
				ChallengerShotsHit = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SUCCESS_SHOTS"));
				if (MVPShotsHit < ChallengerShotsHit) {
					MVP = Challenger;
					continue;
				}
				ShotsMade = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SHOTS_TAKEN"));
				ChallengerHitPercentage = ChallengerShotsHit/ShotsMade;
				if (MVPHitPercentage < ChallengerHitPercentage) {
					MVP = Challenger;
					continue;
				}
				ChallengerAttacksMade = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_SUCCESSFUL_ATTACKS"));
				if (MVPAttacksMade < ChallengerAttacksMade) {
					MVP = Challenger;
					continue;
				}
				ChallengerDamageDealt = Analytics.GetTacticalFloatValue(BuildUnitMetric(UnitRef.ObjectID, "ACC_UNIT_DEALT_DAMAGE"));
				if (MVPDamageDealt < ChallengerDamageDealt) {
					MVP = Challenger;
					continue;
				}
			}
		}
		return MVP;
}

// this is what analytics does
simulated function string BuildUnitMetric(int UnitID, string Metric) {
	return "UNIT_"$UnitID$"_"$Metric;
}

// These objective names can be found in XComGame.int (the localization folder) and search for DisplayName
function string GetObjectiveImagePath(string obj) {
	if (obj == "Defeat Chosen Warlock") {
		return "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Warlock";
	} else if (obj == "Defeat Chosen Assassin") {
		return "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Assasin";
	} else if (obj == "Defeat Chosen Hunter") {
		return "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Hunter";
	} else if (obj == "Rescue Stranded Resistance Agents" || InStr(obj, "Gather Survivors") > -1) {
		return "img:///UILibrary_DLC2Images.Alert_Downed_Skyranger";
	} else if (obj == "Stop the ADVENT Retaliation" || obj == "Haven Assault") {
		return "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Retaliation";
	} else if (obj == "Protect the Device") {
		return "img:///UILibrary_XPACK_StrategyImages.CovertOp_Gain_Resistance_Contact";
	} else if (obj == "Recover the ADVENT Power Converter") {
		return "uilibrary_strategyimages.X2StrategyMap.Alert_Sky_Tower"; //
	} else if (obj == "Secure the Disabled UFO") {
		return "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_UFO_Landed";
	} else if (obj == "Destroy the Alien Relay") {
		return "img:///uilibrary_strategyimages.X2StrategyMap.Alert_Flight_Device";
	} else if (obj == "Defend the Avenger" || obj == "Repel the Chosen Assault") {
		return "img:///UILibrary_XPACK_StrategyImages.Alert_Avenger_Assault";
	} else if (obj == "Escape Covert Action") {
		return "img:///UILibrary_XPACK_StrategyImages.Mission_ChosenAmbush";
	} else if (InStr(obj, "Raid") > -1 || obj == "Extract ADVENT Supplies") {
		return "img:///UILibrary_StrategyImages.X2StrategyMap.POI_DeadAdvent";
	}  else if (InStr(obj, "Hack") > -1) {
		return "img:///UILibrary_XPACK_StrategyImages.CovertOp_Recover_X_Intel";
	} else if (InStr(obj, "Extract VIP") > -1 || obj == "Recover Resistance Operative") {
		return "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Traitor";
	} else if (InStr(obj, "Rescue VIP") > -1 || obj == "Rescue Operative from ADVENT Compound") {
		return "img:///UILibrary_XPACK_StrategyImages.DarkEvent_The_Collectors";
	} else if(InStr(obj, "Neutralize") > -1) {
		return "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Guerrilla_Ops";
	} else if (InStr(obj, "Sabotage") > -1) {
		return "img:///UILibrary_XPACK_StrategyImages.CovertOp_Reduce_Avatar_Project_Progress";
	} else if (InStr(obj, "Recover Item") > -1 ) {
		return "img:///UILibrary_XPACK_StrategyImages.CovertOp_Recover_Alien_Loot";
	} else if (InStr(obj, "Investigate") > -1 || obj == "Secure the ADVENT Network Tower" || obj == "Assault the Alien Fortress" || obj == "Destroy Avatar Project") { // story
		return "img:///UILibrary_StrategyImages.X2StrategyMap.POI_WhatsInTheBarn";
	} else { // custom
		return "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Objective_Complete";
	}
}


DefaultProperties {
	bSingleton=true;
}