tell application "System Preferences"
	reveal anchor "output" of pane "com.apple.preference.sound"
end tell
tell application "System Events"
	tell application process "System Preferences"
		repeat until exists tab group 1 of window 1
		end repeat
		tell table 1 of scroll area 1 of tab group 1 of window 1
			set target to "External Headphones"
			set alternative to "MacBook Pro Speakers"
			set retry to 1 -- 重试次数，可为 0
			set interval to 1 -- 重试间隔（秒），可为小数
			if value of text field 1 of (row 1 whose selected is true) is target then
				set target to alternative
			end if
			repeat with counter from 0 to retry
				try
					select (row 1 whose value of text field 1 is target)
					exit repeat
				end try
				if counter < retry then
					delay (interval)
				end if
			end repeat
		end tell
	end tell
end tell
tell application "System Preferences" to quit
