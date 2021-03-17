/*
============================================================================


 2DO
V Combineer FeedExplorer en FeedNotepad tot 1 routine.
V Maak daar een functie van: FeedDialog(WinID, folder)
V Roep FeedDialog(selecteditem) aan vanuit FolderChoice
- TEST
V Get_Zfolder(), maar dan zonder de cm_CopySrcPathToClip iets met Global)
- Hotkey variabel maken (nu overal Ctrl-Q gedefinieerd)
? Keep dialog-list in memory. Re-read when changes are made.
? Own copy of file manager icons? (instead of reading exe)
? Support paths > 259 ? (max length menu text = 260)
V Function SmellsLikeAFileDialog($WinID)
? Lees huidige folder. Als gelijk aan switchfolder: doe nix
- Vervang GetModuleFileNameEx door ahk internal functie 
  (WinGet, OutputVar, ProcessPath [)
? Add check SmellsLikeAFileDialog() to ShowMenu()? 
  ( maybe later; not now in "learnming mode")
- Optimize timings (currently quite slow)
V Support for XYPlorer:





Known Bugs:
V FeedDialog Notepad SaveAs vanuit FolderChoice wiebelig ..
V $DialogAction is niet bekend binnen ShowMenu
V Is $Fingerprint wel bekend in Menu? (tbv AutoSwitch/ Never here etc.)
- Long paths (>=255) not supported
- 
============================================================================
*/


;_____________________________________________________________________________
;
;					SETTINGS
;_____________________________________________________________________________
;

	#NoEnv  						; Recommended for performance and compatibility with future AutoHotkey releases.
;	#Warn							; Enable warnings to assist with detecting common errors.
	SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.
	#singleinstance force


;	Total Commander internal codes
	global cm_CopySrcPathToClip  := 2029
	global cm_CopyTrgPathToClip  := 2030

;	2DO
;	ActivateMenuHotkey :=  "^Q"

;	Hotkey, ^Q, ShowMenu, Off
;	Hotkey, ^Q, Off



	CallShowMenu := Func("ShowMenu")
	Hotkey, ^Q, %CallShowMenu%, Off




;	INI file ( <program name without extension>.INI)
	SplitPath, A_ScriptFullPath,,,, name_no_ext
	$INI := name_no_ext  . ".ini"
	name_no_ext := ""
	




;_____________________________________________________________________________
;
;					ACTION!
;_____________________________________________________________________________
;

loop
{
	
	WinWaitActive, ahk_class #32770

;_____________________________________________________________________________
;
;					DIALOG ACTIVE
;_____________________________________________________________________________
;

	
;	Get ID of dialog box
	$WinID := WinExist("A")
;MsgBox DEBUG WINID = %$WinID%
	
	
;	Get Windows title and process.exe of this dialog
	WinGet, $ahk_exe, ProcessName, ahk_id %$WinID%
	WinGetTitle, $window_title , ahk_id %$WinID%

	$FingerPrint := $ahk_exe . "___" . $window_title


;	Check if FingerPrint entry is already in INI, so we know what to do.
	IniRead, $DialogAction, %$INI%, Dialogs, %$FingerPrint%

;MsgBox DEBUG Action = %$DialogAction%

	If ($DialogAction = 1 ) {  								;	======= AutoSwitch ==
;MsgBox	Auto
		$FolderPath := Get_Zfolder($WinID)

		If ( ValidFolder( $FolderPath )) { 
			FeedDialog($WinID, $FolderPath)
		}
	
	} else if ($DialogAction = 0 ) {  						;	======= Never here ==

		;	Do nothing
	
	} 	else {  														 ;	======= Show Menu ==

;		Do a basic check if this might be a file dialog
;		If so: Show menu

		if SmellsLikeAFileDialog($WinID)
			ShowMenu()

	}



;	If we end up here, we checked the INI for what to do in this dialog and did it
;	We are still in this dialog and can now aenable the hotkey for manual menu-activation
;	Activate the CTR-Q hotkey. When pressed, start the  ShowMenu routine

	Hotkey, ^Q, On

	

; End of File Dialog routine

;MsgBox DEBUG Still Active ..
	WinWaitNotActive
	
;_____________________________________________________________________________
;
;					DIALOG NOT ACTIVE
;_____________________________________________________________________________
;


;MsgBox ------------------------------ Dialog no longer active!
	Hotkey, ^Q, Off

	sleep, 100



;_____________________________________________________________________________
;
}	; End of continuous	WinWaitActive /	WinWaitNotActive loop
;_____________________________________________________________________________




MsgBox We never get here (and that's how it should be)
ExitApp






;=============================================================================
;=============================================================================
;=============================================================================
;
;			SUBROUTINES AND FUNCTIONS
;
;=============================================================================
;=============================================================================
;=============================================================================



;_____________________________________________________________________________
;
					SmellsLikeAFileDialog(_thisID )
;_____________________________________________________________________________
;
{

;	Only consider this dialog a possible file-dialog when:
;	(SysListView321 AND ToolbarWindow321) OR (DirectUIHWND1 AND ToolbarWindow321) controls detected
;	First is for Notepad++; second for all other iledialogs
;	That is our rough detection of a File dialog. Returns 1 or 0 (TRUE/FALSE)

;	SysListView32 is what Notepad++ uses. Thanks, @tuska!

	WinGet, _controlList, ControlList, ahk_id %_thisID%


	Loop, Parse, _controlList, `n
	{
		If ( A_LoopField = "SysListView321"  )
			_SysListView321 := 1
		If ( A_LoopField = "ToolbarWindow321")
			_ToolbarWindow321 := 1
		If ( A_LoopField = "DirectUIHWND1"   ) 
			_DirectUIHWND1 := 1
	}

	if ( (_SysListView321 or _DirectUIHWND1 ) and _ToolbarWindow321 ) {
		return TRUE
	} else {
		return FALSE
	}
}



;_____________________________________________________________________________
;
					FeedDialog( _thisID, _thisFOLDER )
;_____________________________________________________________________________
;    
{
;MsgBox 1
	WinActivate, ahk_id %_thisID%
	Sleep, 50
	WinGet, _thisEXE, ProcessName, A

;MsgBox 2


;	Read the current text in the "File Name:" box (= $OldText)

	ControlGetText _oldText, Edit1, A
;MsgBox 3
	Sleep, 20
	

	If ( _thisEXE = "notepad.exe" AND (_oldText)) {	; ====== Notepad SaveAs dialog

		Sleep, 100
		ControlClick, ToolbarWindow324, A, , , 2, X10 Y10
		sleep, 100
		ControlSetText, Edit2, %_thisFOLDER%, A
		Sleep 100
		ControlSend Edit2, {Enter}, A

	} else {										; ==== Regular File Dialog ==

		_thisFOLDER := _thisFOLDER . "\"

		Loop, 5
		{
			ControlSetText, Edit1, %_thisFOLDER%, A		; set
			Sleep, 25
			ControlGetText, _thisCONTROLTEXT, Edit1, A		; check
			if ( _thisCONTROLTEXT = _thisFOLDER )
				break
		}

		Sleep, 30
		ControlSend Edit1, {Enter}, A

	}

;												===== For all dialog types ===

;	re-insert original filename / make empty in case of previous folder

	sleep, 15

	ControlFocus Edit1, A
	Sleep, 20


	Loop, 5
	{
		ControlSetText, Edit1, %_oldText%, A		; set
		Sleep, 15
		ControlGetText, _2thisCONTROLTEXT, Edit1, A		; check
		if ( _2thisCONTROLTEXT = _oldText )
			break
	}
	
return
}



;_____________________________________________________________________________
;
					ShowMenu()
;_____________________________________________________________________________
;
{

	global $DialogAction
;	global $FingerPrint
	
	_showMenu := 0

;---------------[ Title BAr ]--------------------------------------
	Menu ContextMenu, Add,  QuickSwitch Menu, Dummy
	Menu ContextMenu, Default,  QuickSwitch Menu
	Menu ContextMenu, disable, QuickSwitch Menu



	WinGet, _allWindows, list
	Loop, %_allWindows%
	{
		_thisID := _allWindows%A_Index%
		WinGetClass, _thisClass, ahk_id %_thisID%

;---------------[ Total Commander Folders]--------------------------------------

		If ( _thisClass = "TTOTAL_CMD") {
		
		;	Get Process information for TC icon
			WinGet, _thisPID, PID, ahk_id %_thisID%
			_TC_exe := GetModuleFileNameEx( _thisPID )

			ClipSaved := ClipboardAll
			Clipboard := ""

			SendMessage 1075, %cm_CopySrcPathToClip%, 0, , ahk_id %_thisID%

			;check if valid folder first. Only add it if it is.
			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) ) {
					Menu ContextMenu, Add,  %clipboard%, FolderChoice
					Menu ContextMenu, Icon, %clipboard%, %_TC_exe%,0, 32
					_showMenu := 1

			}

			SendMessage 1075, %cm_CopyTrgPathToClip%, 0, , ahk_id %_thisID%

			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) ) {
					Menu ContextMenu, Add,  %clipboard%, FolderChoice
					Menu ContextMenu, Icon, %clipboard%, %_TC_exe%,0,32
					_showMenu := 1
			}


			Clipboard := ClipSaved
			ClipSaved := ""
		}

		
;---------------[ XYPlorer               ]--------------------------------------

		If ( _thisClass = "ThunderRT6FormDC") {
		
		;	Get Process information for TC icon
			WinGet, _thisPID, PID, ahk_id %_thisID%
			_XYPlorer_exe := GetModuleFileNameEx( _thisPID )

			ClipSaved := ClipboardAll
			Clipboard := ""

			Send_XYPlorer_Message(_thisID, "::copytext get('path', a);")
;			SendMessage 1075, %cm_CopySrcPathToClip%, 0, , ahk_id %_thisID%

			;check if valid folder first. Only add it if it is.
			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) ) {
					Menu ContextMenu, Add,  %clipboard%, FolderChoice
					Menu ContextMenu, Icon, %clipboard%, %_XYPlorer_exe%,0, 32
					_showMenu := 1

			}

			Send_XYPlorer_Message(_thisID, "::copytext get('path', i);")
;
;			SendMessage 1075, %cm_CopyTrgPathToClip%, 0, , ahk_id %_thisID%

			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) ) {
					Menu ContextMenu, Add,  %clipboard%, FolderChoice
					Menu ContextMenu, Icon, %clipboard%, %_XYPlorer_exe%,0,32
					_showMenu := 1
			}


			Clipboard := ClipSaved
			ClipSaved := ""
		}


		
	}



;---------------[ File Explorer Folders ]----------------------------------------

	For _Exp in ComObjCreate("Shell.Application").Windows	{
		_thisExplorerPath := _Exp.Document.Folder.Self.Path

;		check if valid folder first. Don't add it if not.
		If ( ValidFolder(_thisExplorerPath) ) {
			Menu ContextMenu, Add,  %_thisExplorerPath%, FolderChoice
			Menu ContextMenu, Icon, %_thisExplorerPath%, shell32.dll, 5,32
			_showMenu := 1
		}
	}


;	If no folders found to be shown: no need to show menu ...
	
	If ( _showMenu = 0 ) {
		Menu ContextMenu, Delete
	return
	}



;---------------[ Settings ]----------------------------------------

	Menu ContextMenu, Add,
	Menu ContextMenu, Add, Settings for this dialog, Dummy
	Menu ContextMenu, disable, Settings for this dialog

	Menu ContextMenu, Add,  Allow AutoSwitch, AutoSwitch, Radio
	Menu ContextMenu, Add,  Never here, Never, Radio
	Menu ContextMenu, Add,  Not now, ThisMenu, Radio

; Activate radiobutton for current setting (depends on INI setting)

	If ($DialogAction = 1) {
		Menu ContextMenu, Check, Allow AutoSwitch
	}
	else if ($DialogAction = 0) {
		Menu ContextMenu, Check, Never here
	}
	else {
		Menu ContextMenu, Check, Not now
	}
	


;---------------[ Show ]----------------------------------------

;	Menu ContextMenu, Standard
;	BAckup to prevent errors
	Menu ContextMenu, UseErrorLevel

	Menu ContextMenu, Color, C0C59C

	Menu ContextMenu, Show, 100,100
	Menu ContextMenu, Delete

	show_menu := 0



return
}



;_____________________________________________________________________________
;
					FolderChoice:
;_____________________________________________________________________________
;

;	MsgBox DEBUG 	FeedDialog__%$WinID%__%A_ThisMenuItem%__
;	FeedDialog($WinID, A_ThisMenuItem)

;MsgBox DEBUG WinID = %$WinID% Folder = %A_ThisMenuItem%__ 
		If ValidFolder( A_ThisMenuItem ) { 

			FeedDialog( $WinID, A_ThisMenuItem )

		}
		
return


;_____________________________________________________________________________
;
					AutoSwitch:
;_____________________________________________________________________________
;

	IniWrite, 1, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := 1
;2DO: Gelijk ook maar autoswitch doen dan ...

	$FolderPath := Get_Zfolder($WinID)

	If ( ValidFolder( $FolderPath )) { 
		FeedDialog($WinID, $FolderPath)
	}

return



;_____________________________________________________________________________
;
					Never:
;_____________________________________________________________________________
;

	IniWrite, 0, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := 0

return



;_____________________________________________________________________________
;
					ThisMenu:
;_____________________________________________________________________________
;

	IniDelete, %$INI%, Dialogs, %$FingerPrint%
	$DialogAction := ""

return



;_____________________________________________________________________________
;
					Dummy:
;_____________________________________________________________________________
;

return



;_____________________________________________________________________________
;
					ValidFolder(_thisPath_)
;_____________________________________________________________________________
;
{
;	Prepared for extra checks
	If ( _thisPath_ != "") {

		if InStr(FileExist(_thisPath_), "D")
			return TRUE
		else
			return FALSE
	}
	else
		return FALSE

}

;_____________________________________________________________________________
;
					Get_Zfolder( _thisID_ )
;_____________________________________________________________________________
;
{
	;	Get z-order of all applicatiions.
	;	When "our" ID is found: save z-order of "the next one"
	;	Actualy: The next-next one as the next one is the parent-program that opens the dialog (e.g. notepad )
	;	if the next-next one is a file mananger (Explorer class = CabinetWClass ; TC = TTOTAL_CMD),
	;	read the active folder and browse to it in the dialog.


;2DO:  global cm_CopySrcPathToClip or static X:=0, Y:="fox"


		WinGet, id, list

		Loop, %id%
		{
			this_id := id%A_Index%
			If ( _thisID_ = this_id ) {
				this_z := A_Index
				break
			}
		}	; end id loop

		$next := this_z + 2
		next_id := id%$next%
		WinGetClass, next_class, ahk_id %next_id%
;MsgBox DEBUG nextclass = %next_class%


		If ( next_class = "TTOTAL_CMD") {							;	Total Commander

			ClipSaved := ClipboardAll
			Clipboard := ""

			SendMessage 1075, %cm_CopySrcPathToClip%, 0, , ahk_id  %next_id%

			If (ErrorLevel = 0) {

				$ZFolder := clipboard
				Clipboard	:= ClipSaved
			}
		}
;2DO: ADD XYPlorer


		If ( next_class = "ThunderRT6FormDC") {							;	XYPlorer

			ClipSaved := ClipboardAll
			Clipboard := ""

			Send_XYPlorer_Message( next_id, "::copytext get('path', a);")
			ClipWait,0
;			If (ErrorLevel = 0) {

				$ZFolder := clipboard
;				MsgBox DEBUG Z-Folder = __%$ZFolder%__
				Clipboard	:= ClipSaved
;			}
		}


			
		If ( next_class = "CabinetWClass") {						;	File Explorer

			For $Exp in ComObjCreate("Shell.Application").Windows
			{
				if ( $Exp.hwnd = next_id )
				{
					$ZFolder := $Exp.Document.Folder.Self.Path
					break
				}
			}
		}

	Return $ZFolder
}


;_____________________________________________________________________________
;
					GetModuleFileNameEx( p_pid )
;_____________________________________________________________________________
;
;	From: https://autohotkey.com/board/topic/32965-getting-file-path-of-a-running-process/
;	NotNull: changed "GetModuleFileNameExA" to "GetModuleFileNameExW""

{
	
	h_process := DllCall( "OpenProcess", "uint", 0x10|0x400, "int", false, "uint", p_pid )
	if ( ErrorLevel or h_process = 0 )
	  return

	name_size = 255
	VarSetCapacity( name, name_size )

	result := DllCall( "psapi.dll\GetModuleFileNameExW", "uint", h_process, "uint", 0, "str", name, "uint", name_size )

	DllCall( "CloseHandle", h_process )

	return, name
}




;_____________________________________________________________________________
;
					Send_XYPlorer_Message(xyHwnd, message)
;_____________________________________________________________________________
;

{
	size := StrLen(message)
	if !(A_IsUnicode) {
		VarSetCapacity(data, size * 2, 0)
		StrPut(message, &data, "UTF-16")
	} else {
		data := message
	}
	VarSetCapacity(COPYDATA, A_PtrSize * 3, 0)
	NumPut(4194305, COPYDATA, 0, "Ptr")
	NumPut(size * 2, COPYDATA, A_PtrSize, "UInt")
	NumPut(&data, COPYDATA, A_PtrSize * 2, "Ptr")
	result := DllCall("User32.dll\SendMessageW", "Ptr", xyHwnd, "UInt", 74, "Ptr", 0, "Ptr", &COPYDATA, "Ptr")
return
}
