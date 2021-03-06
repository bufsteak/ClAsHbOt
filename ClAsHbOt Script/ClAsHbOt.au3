#cs
ClAsHbOt!

TODO:
queue up troops for donating in barracks
don't unqueue expensive/long build troops

#ce

Opt("MustDeclareVars", 1)
Opt("GUIOnEventMode", 1)

Global $version = "20150411"

; AutoIt includes
#include <ScreenCapture.au3>
#include <Date.au3>
#include <GDIPlus.au3>
#include <Math.au3>
#include <Array.au3>
#include <WinAPI.au3>
#include <File.au3>
#include <WindowsConstants.au3>

; CoC Bot Includes
#include <Globals.au3>
#include <GUI.au3>
#include <Settings.au3>
#include <Scraper.au3>
#include <KeepOnline.au3>
#include <CollectLoot.au3>
#include <FindMatch.au3>
#include <FindSnipableTH.au3>
#include <AutoRaid.au3>
#include <AutoRaidStrategy.au3>
#include <Mouse.au3>
#include <BlueStacks.au3>
#include <Screen.au3>
#include <Donate.au3>



Main()

Func Main()

   StartBlueStacks()

   InitScraper()

   ReadSettings()

;ZoomOut(true)
;QueueDonatableTroops()
;Exit
   InitGUI()

   MainApplicationLoop()
EndFunc

Func MainApplicationLoop()
   Local $lastOnlineCheckTimer = TimerInit()
   Local $lastCollectLootTimer = TimerInit()
   Local $lastDonateTroopsTimer = TimerInit()
   Local $lastQueueDonatableTroopsTimer = TimerInit()
   Local $lastTrainingCheckTimer = TimerInit()

   While 1
	  DebugWrite("Main loop: AR Stage " & $gAutoRaidStage & " clicked: " & $gKeepOnlineClicked & " " & $gDonateTroopsClicked & " " & _
		 $gCollectLootClicked & " " & $gFindMatchClicked & " " & $gFindSnipableTHClicked & " " & $gAutoRaidClicked)

	  ; Update status on GUI
	  GetMyLootNumbers()

		 ; Check for offline issues
		 If _GUICtrlButton_GetCheck($GUI_KeepOnlineCheckBox) = $BST_CHECKED And _
			(TimerDiff($lastOnlineCheckTimer) >= $gOnlineCheckInterval Or $gKeepOnlineClicked) Then

			$gKeepOnlineClicked = False

			If WhereAmI()=$eScreenAndroidHome Then
			   ResetToCoCMainScreen()
			EndIf

			CheckForAndroidMessageBox()
			$lastOnlineCheckTimer = TimerInit()
			UpdateCountdownTimers($lastOnlineCheckTimer, $lastCollectLootTimer, $lastDonateTroopsTimer, $lastTrainingCheckTimer)
		 EndIf

	  Local $autoRaidInProgress = $gAutoRaidStage=$eAutoRaidFindMatch Or $gAutoRaidStage=$eAutoRaidExecuteRaid Or $gAutoRaidStage=$eAutoRaidExecuteDEZap

	  If $autoRaidInProgress = False Then

		 ; Donate Troops
		 If _GUICtrlButton_GetCheck($GUI_DonateTroopsCheckBox) = $BST_CHECKED  And _
			(TimerDiff($lastDonateTroopsTimer) >= $gCheckChatWindowForDonateInterval Or $gDonateTroopsClicked Or IsColorPresent($rNewChatMessagesColor)) Then

			$gDonateTroopsClicked = False

			ResetToCoCMainScreen()
			If WhereAmI()=$eScreenMain Then DonateTroops()
			$lastDonateTroopsTimer = TimerInit()
			UpdateCountdownTimers($lastOnlineCheckTimer, $lastCollectLootTimer, $lastDonateTroopsTimer, $lastTrainingCheckTimer)
		 EndIf

		 ; Queue Troops for Donation
		 #cs
		 If _GUICtrlButton_GetCheck($GUI_DonateTroopsCheckBox) = $BST_CHECKED And _
			(TimerDiff($lastQueueDonatableTroopsTimer) >= $gQueueDonatableTroopsInterval Or $gDonateTroopsStartup = True) Then

			$gDonateTroopsStartup = False

			ResetToCoCMainScreen()
			If WhereAmI()=$eScreenMain Then QueueDonatableTroops()
			$lastQueueDonatableTroopsTimer = TimerInit()
		 EndIf
		 #ce

		 ; Collect loot
		 If _GUICtrlButton_GetCheck($GUI_CollectLootCheckBox) = $BST_CHECKED  And _
			(TimerDiff($lastCollectLootTimer) >= $gCollectLootInterval Or $gCollectLootClicked) Then

			$gCollectLootClicked = False

			ResetToCoCMainScreen()
			If WhereAmI()=$eScreenMain Then CollectLoot()
			$lastCollectLootTimer = TimerInit()
			UpdateCountdownTimers($lastOnlineCheckTimer, $lastCollectLootTimer, $lastDonateTroopsTimer, $lastTrainingCheckTimer)
		 EndIf

	  Endif ; If $autoRaidInProgress = False

	  ; Find a raiding match
	  If _GUICtrlButton_GetCheck($GUI_FindMatchCheckBox) = $BST_CHECKED Then

		 $gFindMatchClicked = False

		 ResetToCoCMainScreen()
		 If WhereAmI()=$eScreenMain Then
			If FindAValidMatch() = True Then
			   _GUICtrlButton_SetCheck($GUI_FindMatchCheckBox, $BST_UNCHECKED)
			   _GUICtrlButton_Enable($GUI_FindSnipableTHCheckBox, True)
			   _GUICtrlButton_Enable($GUI_AutoRaidCheckBox, True)
			EndIf
		 EndIf
	  EndIf

	  ; Find a snipable TH
	  If _GUICtrlButton_GetCheck($GUI_FindSnipableTHCheckBox) = $BST_CHECKED Then

		 $gFindSnipableTHClicked = False

		 ResetToCoCMainScreen()
		 If WhereAmI()=$eScreenMain Then
			If FindASnipableTH() = True Then
			   _GUICtrlButton_SetCheck($GUI_FindSnipableTHCheckBox, $BST_UNCHECKED)
			   _GUICtrlButton_Enable($GUI_FindMatchCheckBox, True)
			   _GUICtrlButton_Enable($GUI_AutoRaidCheckBox, True)
			EndIf
		 EndIf
	  EndIf

	  ; Auto Raid, Dump Cups
	  If _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox) = $BST_CHECKED And _
		 _GUICtrlButton_GetCheck($GUI_AutoRaidDumpCups) = $BST_CHECKED And _
		 IsButtonPresent($AndroidMessageButton) = False Then

		 ResetToCoCMainScreen()
		 If WhereAmI()=$eScreenMain Then DumpCups()
	  EndIf

	  ; Auto Raid, Attack
	  If _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox) = $BST_CHECKED And _
		 IsButtonPresent($AndroidMessageButton) = False Then

		 If $gAutoRaidBeginLoot[0]=-1 Or $gAutoRaidBeginLoot[1]=-1 Or _
			$gAutoRaidBeginLoot[2]=-1 Or $gAutoRaidBeginLoot[3]=-1 Then

			CaptureAutoRaidBegin()
		 EndIf

		 $gAutoRaidClicked = False
		 CheckForAndroidMessageBox()
		 AutoRaid($lastTrainingCheckTimer)
	  EndIf

	  ; Pause for 5 seconds
	  For $i = 1 To 10
		 UpdateCountdownTimers($lastOnlineCheckTimer, $lastCollectLootTimer, $lastDonateTroopsTimer, $lastTrainingCheckTimer)

		 If $gKeepOnlineClicked Or $gCollectLootClicked Or $gDonateTroopsClicked Or $gFindMatchClicked Or $gFindSnipableTHClicked Or $gAutoRaidClicked Then ExitLoop
		 If $gAutoRaidStage=$eAutoRaidFindMatch Or $gAutoRaidStage=$eAutoRaidExecuteRaid Or $gAutoRaidStage=$eAutoRaidExecuteDEZap Then ExitLoop
		 If _GUICtrlButton_GetCheck($GUI_KeepOnlineCheckBox) = $BST_CHECKED And TimerDiff($lastOnlineCheckTimer) >= $gOnlineCheckInterval Then ExitLoop
		 If _GUICtrlButton_GetCheck($GUI_CollectLootCheckBox) = $BST_CHECKED And TimerDiff($lastCollectLootTimer) >= $gCollectLootInterval Then ExitLoop
		 If _GUICtrlButton_GetCheck($GUI_DonateTroopsCheckBox) = $BST_CHECKED And TimerDiff($lastDonateTroopsTimer) >= $gCheckChatWindowForDonateInterval Then ExitLoop

		 Sleep(500)
	  Next
   WEnd
EndFunc

Func UpdateCountdownTimers(Const $onlineTimer, Const $lootTimer, Const $troopsTimer, Const $trainingTimer)
   If _GUICtrlButton_GetCheck($GUI_KeepOnlineCheckBox) = $BST_UNCHECKED Then
	  GUICtrlSetData($GUI_KeepOnlineCheckBox, "F5 Keep Online 0:00")
   Else
	  Local $ms = $gOnlineCheckInterval - TimerDiff($onlineTimer)
	  If $ms < 0 Then $ms = 0
	  GUICtrlSetData($GUI_KeepOnlineCheckBox, "F5 Keep Online " & millisecondToMMSS($ms))
   EndIf

   If _GUICtrlButton_GetCheck($GUI_CollectLootCheckBox) = $BST_UNCHECKED Then
	  GUICtrlSetData($GUI_CollectLootCheckBox, "F6 Collect Loot 0:00")
   Else
	  Local $ms = $gCollectLootInterval - TimerDiff($lootTimer)
	  If $ms < 0 Then $ms = 0
	  GUICtrlSetData($GUI_CollectLootCheckBox, "F6 Collect Loot " & millisecondToMMSS($ms))
   EndIf

   If _GUICtrlButton_GetCheck($GUI_DonateTroopsCheckBox) = $BST_UNCHECKED Then
	  GUICtrlSetData($GUI_DonateTroopsCheckBox, "F7 Donate Troops 0:00")
   Else
	  Local $ms = $gCheckChatWindowForDonateInterval - TimerDiff($troopsTimer)
	  If $ms < 0 Then $ms = 0
	  GUICtrlSetData($GUI_DonateTroopsCheckBox, "F7 Donate Troops " & millisecondToMMSS($ms))
   EndIf

   If _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox) = $BST_CHECKED And _
	  $gAutoRaidStage = $eAutoRaidWaitForTrainingToComplete Then
	  Local $ms = $gTroopTrainingCheckInterval - TimerDiff($trainingTimer)
	  If $ms < 0 Then $ms = 0
	  GUICtrlSetData($GUI_AutoRaid, "Auto Raid: Waiting For Training " & millisecondToMMSS($ms))
   EndIf
EndFunc

Func millisecondToMMSS(Const $ms)
   Local $m = Int(Mod($ms, 1000*60*60) / (1000*60))
   Local $s = Int(Mod(Mod($ms, 1000*60*60), 1000*60) / 1000)

   Return $m & ":" & StringRight("00" & $s, 2);
EndFunc

Func GetMyLootNumbers()
   ;DebugWrite("GetMyLootNumbers()")

   ; My loot is only scrapable on main screen
   If WhereAmI()<>$eScreenMain Then Return

   ; My loot info can't be seen for some reason
   If IsTextBoxPresent($rMyGoldTextBox) = False Then Return

   ; Scrape text fields
   Local $MyGold = Number(ScrapeFuzzyText($smallCharacterMaps, $rMyGoldTextBox))
   Local $MyElix = Number(ScrapeFuzzyText($smallCharacterMaps, $rMyElixTextBox))
   Local $MyDark = Number(ScrapeFuzzyText($smallCharacterMaps, $rMyDarkTextBox))
   Local $MyGems = Number(ScrapeFuzzyText($smallCharacterMaps, $rMyGemsTextBox))
   GUICtrlSetData($GUI_MyGold, $MyGold)
   GUICtrlSetData($GUI_MyElix, $MyElix)
   GUICtrlSetData($GUI_MyDark, $MyDark)
   GUICtrlSetData($GUI_MyGems, $MyGems)

   Local $MyCups = Number(ScrapeFuzzyText($largeCharacterMaps, $rMyCupsTextBox))
   GUICtrlSetData($GUI_MyCups, $MyCups)
EndFunc

Func DebugWrite($text)
   If $gDebug Then
	  ConsoleWrite(_NowDate() & " " & _NowTime() & " " & $text & @CRLF)
	  FileWrite("ClashBotLog.txt", _NowDate() & " " & _NowTime() & " " & $text & @CRLF)
   EndIf
EndFunc

Func TimeStamp()
   Return StringReplace(StringReplace(StringStripWS(_NowCalc(),$STR_STRIPALL),"/",""),":","")
EndFunc