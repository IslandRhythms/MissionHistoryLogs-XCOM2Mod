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
	var int ForceLevel; // in BattleData: function int GetForceLevel();
	var int NumEnemiesDeployed;
	var int NumEnemiesKilled;
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
	// XComGameState_Analytics will have the information we need to determine the MVP
	var string SoldierMVP; // Calculated by function
	var string SquadName;
	var string SoldiersDeployed;
	var string Enemies;
	var string ChosenName;
	var string QuestGiver; // Reapers, Skirmishers, Templars, The Council
	var string MissionRating; // Poor, Good, Fair, Excellent, Flawless.
	var string MissionLocation; // city and country of the mission
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
	local int injured, captured, killed, total;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local string rating;
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
	`log("AlienHQ retrieved");
	Faction = XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(MissionDetails.ResistanceFaction.ObjectID));
	`log("Faction Retrieved");
	ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(AlienHQ.LastAttackingChosen.ObjectID));
	`log("Chosen retrieved");
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	`log("Mission Template Manager Retrieved");
	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	`log("History Retrieved");
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	// we need to keep track of this because any variable that could help us do this is only valid in the tactical layer.
	// for some reason when it gets to strategy, any variable that could help us determine if the chosen was on the most recent mission gets wiped.
	if (ChosenState.FirstName == "") {
		`log("there was no chosen");
		ItemData.Enemies = "Advent";
	}
	else if (ChosenState.NumEncounters == 1) {
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
	} else if (ChosenState.NumEncounters > 1) {
		`log("we've encountered them before");
		for (Index = 0; Index < TheChosen.Length; Index++) {
			ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
			if (TheChosen[Index].ChosenName == ChosenName && TheChosen[Index].NumEncounters != ChosenState.NumEncounters) {
				TheChosen[Index].NumEncounters = ChosenState.NumEncounters;
				if(BattleData.bChosenLost) {
					TheChosen[Index].NumDefeats += 1;
				}
				ItemData.ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
				ItemData.Enemies = TheChosen[Index].ChosenType;
				ItemData.NumChosenEncounters = ChosenState.NumEncounters;
				ItemData.WinPercentageAgainstChosen = float(TheChosen[Index].NumDefeats / TheChosen[Index].NumEncounters);
				break;
			}
		}
	} else {
		`log("Some weird case we didn't cover");
		ItemData.Enemies = "Advent";
	}
	ItemData.NumEnemiesKilled = GetNumEnemiesKilled(BattleData);
	ItemData.NumEnemiesDeployed = GetNumEnemiesDeployed(BattleData);
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
	`log("got the parcel manager and map name and map image");
	ItemData.CampaignIndex = CampaignIndex;
	ItemData.EntryIndex = TableData.Length + 1;
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
	ItemData.NumSoldiersDeployed = total;
	ItemData.NumSoldiersKilled = killed;
	ItemData.NumSoldiersMIA = captured;
	ItemData.NumSoldiersInjured = injured;
	ItemData.SoldierMVP = CalculateMissionMVP();
	if (TableData.Length > 1) {
		TableData.Sort(sortByWins);
	}
	for (Index = 0; Index < TableData.Length; Index++) {
		`log("Is the array sorted?"@TableData[Index].Wins);
	}
	// win
	if (BattleData.AllStrategyObjectivesCompleted()) {
		`log("its a win");
		ItemData.Wins = TableData[TableData.Length - 1].Wins + 1.0;
		`log("number of wins is"@ItemData.Wins);
		ItemData.SuccessRate = (ItemData.Wins/ (TableData.Length + 1.0)) * 100 $ "%";
		`log("denominator is the number plus 1"@TableData.Length);
		`log("success rate is"@ItemData.SuccessRate);
		`log("math has finished");
	} else {
	// loss
		`log("its a loss");
		ItemData.Wins = TableData[TableData.Length - 1].Wins;
		ItemData.SuccessRate = (TableData[TableData.Length - 1].Wins / (TableData.Length + 1.0)) * 100 $ "%";
		`log("math has finished");
	}
	if (Faction.FactionName == "") {
		ItemData.QuestGiver = "The Council";
	} else {
		ItemData.QuestGiver = Faction.FactionName;
	}
	`log("faction name assigned");
	TableData.AddItem(ItemData);
	`log("everything was saved");
}

function int sortByWins(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return sortNumerically(A.Wins, B.Wins);
}
// we want the entry with the greatest numbner of wins to be the last entry.
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

function int GetNumEnemiesKilled(XComGameState_BattleData BattleData) {
	local array<XComGameState_Unit> arrUnits;
	local XGAIPlayer_TheLost LostPlayer;
	local int iKilled;
	local int i;

	BATTLE().GetAIPlayer().GetOriginalUnits(arrUnits);
	LostPlayer = BATTLE().GetTheLostPlayer();
	if (LostPlayer != none) { LostPlayer.GetOriginalUnits(arrUnits); }
	if(class'CHHelpers'.static.TeamOneRequired()) // issue #188 - account for added enemy teams
	{
		class'CHHelpers'.static.GetTeamOnePlayer().GetOriginalUnits(arrUnits);
	}
		
	if(class'CHHelpers'.static.TeamTwoRequired()) // issue #188 - account for added enemy teams
	{
		class'CHHelpers'.static.GetTeamTwoPlayer().GetOriginalUnits(arrUnits);
	}
	for(i = 0; i < arrUnits.Length; i++)
	{
		if(arrUnits[i].IsDead())
		{
			iKilled++;
		}
	}

	// add in any aliens from the transfer state
	if(BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		iKilled += BattleData.DirectTransferInfo.AliensKilled;
	}
	return iKilled;
}

function int GetNumEnemiesDeployed(XComGameState_BattleData BattleData) {
	local array<XComGameState_Unit> arrUnits;
	local XGAIPlayer_TheLost LostPlayer;
	local int iTotal;

	BATTLE().GetAIPlayer().GetOriginalUnits(arrUnits);
	LostPlayer = BATTLE().GetTheLostPlayer();
	if (LostPlayer != none) { LostPlayer.GetOriginalUnits(arrUnits); }
	if(class'CHHelpers'.static.TeamOneRequired()) // issue #188 - account for added enemy teams
	{
		class'CHHelpers'.static.GetTeamOnePlayer().GetOriginalUnits(arrUnits);
	}
		
	if(class'CHHelpers'.static.TeamTwoRequired()) // issue #188 - account for added enemy teams
	{
		class'CHHelpers'.static.GetTeamTwoPlayer().GetOriginalUnits(arrUnits);
	}
	iTotal = arrUnits.Length;
	// add in any aliens from the transfer state
	if(BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		iTotal += BattleData.DirectTransferInfo.AliensSeen;
	}

	return iTotal;
}

function XGBattle_SP BATTLE() {
	return XGBattle_SP(`BATTLE);
}


function string GetMissionRating(int injured, int captured, int killed, int total)
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
/* Template for how to set image for the expanded view
function string GetObjectiveImagePath() {
	local string StrButtonIcon;

	switch(Source)
	{
	case 'MissionSource_LandedUFO':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Advent";
		break;
	case 'MissionSource_AlienNetwork':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Alien";
		break;
	case 'MissionSource_Council':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Council";
		break;
	case 'MissionSource_GuerillaOp':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GOPS";
		break;
	case 'MissionSource_Retaliation':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Retaliation";
		if (GeneratedMission.Mission.MissionName == 'ChosenRetaliation')
		{
			StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Retaliation";
		}
		break;
	case 'MissionSource_BlackSite':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Blacksite";
		break;
	case 'MissionSource_Forge':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Forge";
		break;
	case 'MissionSource_PsiGate':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_PsiGate";
		break;
	case 'MissionSource_Broadcast':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_FinalMission";
		break;
	case 'MissionSource_Final':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_AlienFortress";
		break;
	case 'MissionSource_SupplyRaid':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_SupplyRaid";
		if (GeneratedMission.Mission.MissionName == 'SupplyExtraction')
		{
			StrButtonIcon = "img:///UILibrary_XPACK_Common.MissionIcon_SupplyExtraction";
		}
		break;
	case 'MissionSource_LostAndAbandoned':
	case 'MissionSource_ResistanceOp':
		StrButtonIcon = "img:///UILibrary_XPACK_Common.MissionIcon_ResOps";
		break;
	case 'MissionSource_RescueSoldier':
		StrButtonIcon = "img:///UILibrary_XPACK_Common.MissionIcon_RescueSoldier";
		break;
	case 'MissionSource_ChosenAmbush':
		StrButtonIcon = "img:///UILibrary_XPACK_Common.MissionIcon_EscapeAmbush";
		break;
	case 'MissionSource_ChosenStronghold':
		StrButtonIcon = "img:///UILibrary_XPACK_Common.MissionIcon_ChosenStronghold";
		break;
	default:
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GoldenPath";
	};

	// Start Issue #537
	TriggerOverrideMissionSiteIconImage(StrButtonIcon);
	// End Issue #537

	return StrButtonIcon;

}

simulated function TriggerOverrideMissionSiteIconImage(out string ImagePath)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideMissionSiteIconImage';
	Tuple.Data.Add(1);
	Tuple.Data[0].Kind = XComLWTVString;
	Tuple.Data[0].s = ImagePath;

	`XEVENTMGR.TriggerEvent('OverrideMissionSiteIconImage', Tuple, self);

	ImagePath = Tuple.Data[0].s;
}
*/



DefaultProperties {
	bSingleton=true;
}