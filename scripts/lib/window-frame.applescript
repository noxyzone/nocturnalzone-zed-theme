-- 対象プロセスのうち、タイトルに指定文字列を含むウィンドウの位置とサイズを読み書きする。
-- 利用者の作業中ウィンドウを動かさないよう、window 1へはフォールバックしない。
-- 使い方:
--   osascript window-frame.applescript <process> <title-substring> get
--   osascript window-frame.applescript <process> <title-substring> set <width> <height> [<x> <y>]
-- getは"x,y,width,height"を出力する。位置指定を省いたsetはサイズだけを変える。
on run argv
	set processName to item 1 of argv
	set titlePart to item 2 of argv
	set mode to item 3 of argv

	tell application "System Events" to tell process processName
		set targetWindow to missing value
		repeat with w in windows
			if (name of w as text) contains titlePart then
				set targetWindow to w
				exit repeat
			end if
		end repeat
		if targetWindow is missing value then error "window not found: " & titlePart

		if mode is "get" then
			set {x, y} to position of targetWindow
			set {windowWidth, windowHeight} to size of targetWindow
			return (x as text) & "," & (y as text) & "," & (windowWidth as text) & "," & (windowHeight as text)
		else if mode is "set" then
			perform action "AXRaise" of targetWindow
			set targetWidth to (item 4 of argv) as integer
			set targetHeight to (item 5 of argv) as integer
			set size of targetWindow to {targetWidth, targetHeight}
			if (count of argv) >= 7 then
				set position of targetWindow to {(item 6 of argv) as integer, (item 7 of argv) as integer}
			end if
			return ""
		else
			error "unknown mode: " & mode
		end if
	end tell
end run
