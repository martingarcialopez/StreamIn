-- Converts the review workbook between .xlsx and .numbers with Numbers itself,
-- so the reviewer can edit the .numbers and save it in place with ⌘S.
--
--   osascript numbers.applescript to-numbers <source.xlsx> <destination.numbers> <first sheet>
--   osascript numbers.applescript to-xlsx <source.numbers> <destination.xlsx> <first sheet>
--
-- <first sheet> is the guide sheet's name: the conversion waits until the
-- opened document has it, and fails rather than save an empty document.
-- A document that's already open stays open (to-xlsx then exports what's on
-- screen, saved or not); one this script opened is closed without saving.

on run argv
	set mode to item 1 of argv
	set sourcePath to item 2 of argv
	set destinationPath to item 3 of argv
	set firstSheet to item 4 of argv
	-- Made here, not inside the tell: osascript then hands sandboxed Numbers
	-- access to them. Coerced inside, Numbers can't open a file it hasn't seen.
	set sourceFile to POSIX file sourcePath
	set destinationFile to POSIX file destinationPath
	tell application "Numbers"
		launch
		set wasOpen to false
		repeat with openDocument in documents
			try
				if POSIX path of ((file of openDocument) as alias) is sourcePath then set wasOpen to true
			end try
		end repeat
		set theDocument to open sourceFile
		set loaded to false
		repeat 60 times
			try
				if name of sheet 1 of theDocument is firstSheet then
					set loaded to true
					exit repeat
				end if
			end try
			delay 0.5
		end repeat
		if not loaded then
			if not wasOpen then close theDocument saving no
			error "Numbers didn't finish opening " & sourcePath & "; nothing was converted. Try again."
		end if
		if mode is "to-numbers" then
			save theDocument in destinationFile
		else
			export theDocument to destinationFile as Microsoft Excel
		end if
		if not wasOpen then close theDocument saving no
	end tell
end run
