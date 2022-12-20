// This is an Unreal Script
/*
	Author: Beat
	Had to create a XComGameState because StaticSaveConfig() was causing a crash.
*/
class XComGameState_MissionHistoryLogs extends XComGameState_BaseObject;

// 5 of these are on the top. MissionImagePath is non-negotiable
// Another 5 on the bottom
// 10 of these will be used, the rest are irrelevant.
struct MissionHistoryLogsDetails {
	var int EntryIndex; // This is to keep track of where the entry was added into the CurrentEntries array;
	var int SoldiersDeployed;
	var int SoldiersKilled;
	var string SuccessRate;
	var float wins;
	var string Date;
	var string MissionName;
	var string MissionObjective;
	var string MapName;
	var string MapImagePath;
	var string Squad; // will be XCOM unitl we figure out how to incorporate Squad Manager Mod
	var string Enemies; // either the chosen name or advent
	var string ChosenName;
	var string QuestGiver;
	var string MissionRating; // Poor, Good, Fair, Excellent, Flawless.
	var string MissionLocation; // city and country of the mission
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var int numEncounters;
};


var array<MissionHistoryLogsDetails> TableData;
// fireaxis why
var array<ChosenInformation> TheChosen;


function UpdateTableData() {
	local int injured, captured, killed, total;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local string rating;

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


DefaultProperties {
	bSingleton=true;
}