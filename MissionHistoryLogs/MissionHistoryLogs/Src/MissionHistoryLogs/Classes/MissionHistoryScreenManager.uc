// This is an Unreal Script

class MissionHistoryScreenManager extends Object;


simulated static function WipeLogs() {
	default.CurrentEntries.Length = 0;
	StaticSaveConfig();
}
// TODO: function that adds an entry into the array
simulated static function AppendEntry() {
	
}

// TODO: function that updates the local array to match the DB

// TODO: function that updates both the local array and DB


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