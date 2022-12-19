// This is an Unreal Script
class UISL_CommanderQuarter extends UIScreenListener config (UI);

var localized string LabelShortcut,TooltipShortcut;


var config bool bShowButtonIn_Barracks,		bShowButtonIn_Engineering, 		bShowButtonIn_Research, 	bShowButtonIn_Command, 		bShowButtonIn_Shadow;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//on init, so this will cover a load game, or tactical > strategy transition
event OnInit(UIScreen Screen)
{
	local UIAvengerHUD HUD;

	//AvengerHUD basically happens ONCE per getting into strategy, it's almost a 'strat init' call
	HUD = UIAvengerHUD(Screen);

	if (HUD != none)
	{
    	AddSubMenuItems(HUD);
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	ADD NEW SUB MENU ITEMS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function AddSubMenuItems(UIScreen Screen) 
{
	local UIAvengerHUD AvengerHud;
	local UIAvengerShortcutSubMenuItem MenuItem;

	//ensure the screen is the HUD
	AvengerHud = UIAvengerHUD(Screen);
	if (AvengerHud == none)	{ return; }

	//--------------------------
	//	STANDARD BUTTON
	//--------------------------
	MenuItem.Id = 'GotoMissionHistoryLogTLE';
	MenuItem.Message.Label = default.LabelShortcut;
	MenuItem.Message.Description = default.TooltipShortcut;
	MenuItem.Message.OnItemClicked = OnButtonClickedSimple; // see below		//SelectFacilityHotlink
	MenuItem.Message.Urgency = eUIAvengerShortcutMsgUrgency_Low;
	//MenuItem.Message.HotLinkRef = FacilityState.GetReference();

	AddToMultipleMenuSections(MenuItem, 
		default.bShowButtonIn_Barracks, 
		default.bShowButtonIn_Engineering, 
		default.bShowButtonIn_Research, 
		default.bShowButtonIn_Command, 
		default.bShowButtonIn_Shadow);

	//refresh the HUD buttons
	AvengerHud.Shortcuts.UpdateCategories();
}

//Add menu item to these places
static function AddToMultipleMenuSections(UIAvengerShortcutSubMenuItem MenuItem, bool bInArm, bool bInEng, bool bInRes, bool bInCom, bool bInShd)
{
    if (bInArm)	{ AddToMenuIfNotFound(eUIAvengerShortcutCat_Barracks, MenuItem); 			}
    if (bInEng) { AddToMenuIfNotFound(eUIAvengerShortcutCat_Engineering, MenuItem); 		}
    if (bInRes) { AddToMenuIfNotFound(eUIAvengerShortcutCat_Research, MenuItem); 			}
    if (bInCom) { AddToMenuIfNotFound(eUIAvengerShortcutCat_CommandersQuarters, MenuItem);	}
    if (bInShd) { AddToMenuIfNotFound(eUIAvengerShortcutCat_ShadowChamber, MenuItem); 		}
}

//shortcut not added ... add it ... stops it being added twice
static function AddToMenuIfNotFound(int Category, UIAvengerShortcutSubMenuItem MenuItem)
{
	local UIAvengerHUD AvengerHud;
	local UIAvengerShortcutSubMenuItem MenuCheck; // Dummy, just because Find needs an OUT
	
	AvengerHud = `HQPRES.m_kAvengerHUD;

	if( AvengerHud.Shortcuts.FindSubMenu(Category, MenuItem.Id, MenuCheck) == false)
	{
		AvengerHud.Shortcuts.AddSubMenu(Category, MenuItem);
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	REMOVE NEW SUB MENU ITEMS -- NOT ACTUALLY USED --
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function ResetSubMenuItems(UIScreen Screen) 
{
	local UIAvengerHUD AvengerHud;

	//ensure screen is the HUD
	AvengerHud = UIAvengerHUD(Screen);
	if (AvengerHud == none) { return; }

	RemoveMenuItemByNameFromAllCategories(AvengerHud, 'GotoMYSCREEN');

	//refresh the HUD buttons
	AvengerHud.Shortcuts.UpdateCategories();
}

static function RemoveMenuItemByNameFromAllCategories(UIAvengerHUD AvengerHud, name MenuID)
{
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Barracks, MenuID);
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Research, MenuID);
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Engineering, MenuID);
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_CommandersQuarters, MenuID);
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_ShadowChamber, MenuID);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	ON CLICK BUTTONS     //do not pass go, do not collect £200, go direct to jail.. wait.. pexm, no Bestiary... 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

static protected function OnButtonClickedSimple  (optional StateObjectReference Facility) { OnButtonClicked();		}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	MOVE TO UFOPEDIA
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function OnButtonClicked()
{
	local MissionHistoryScreen MHS;
	//Movie.Pres.UIXComDatabase();
	if( `HQPRES.ScreenStack.IsNotInStack(class'MissionHistoryScreen') )
	{
		MHS = `HQPRES.Spawn(class'MissionHistoryScreen',`HQPRES);
        // MHS.InitProcess();

        `HQPRES.ScreenStack.Push(MHS);
	}

}