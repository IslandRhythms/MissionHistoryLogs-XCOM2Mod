// This is an Unreal Script

class MissionHistory_ListItem extends UITLEChallenge_ListItem dependson(XComGameState_MissionHistoryLogs);

var MissionHistoryLogsDetails Datum;


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
