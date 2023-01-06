// This is an Unreal Script

// This is an Unreal Script
class MissionHistory_ListItem extends UITLEChallenge_ListItem dependson(XComGameState_MissionHistoryLogs);

var MissionHistoryLogsDetails Datum;
/*
simulated function Refresh(MissionHistoryLogsDetails UpdateData) {
	Datum = UpdateData;
	PopulateData();
}
*/

simulated function RefreshHistory(MissionHistoryLogsDetails UpdateData) {
	Datum = UpdateData;
	FillTable();
}

simulated function FillTable() {
	MC.BeginFunctionOp("UpdateData");
	
	MC.QueueString(Datum.MissionName);		// Mission
	MC.QueueString(Datum.SquadName);	// Squad
	MC.QueueString(Datum.Date);			// Date
	MC.QueueString(Datum.MissionRating);				// Rating
	MC.QueueString(Datum.SuccessRate);			// Rate
	
	MC.EndOp();
}
// For reference
/*
simulated function PopulateData()
{
	MC.BeginFunctionOp("UpdateData");
	
	MC.QueueString(Data.MissionName);		// Mission
	MC.QueueString(Data.MissionObjective);	// Objective
	MC.QueueString(Data.MapName);			// Map
	MC.QueueString(Data.Squad);				// Squad
	MC.QueueString(Data.Enemies);			// Enemies
	
	MC.EndOp();
}
*/