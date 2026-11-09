-- 指定アプリを前面化し、指定秒数だけ待つ。
-- 使い方: osascript activate-app.applescript <application> [<delay-seconds>]
on run argv
	set appName to item 1 of argv
	set waitSeconds to 1
	if (count of argv) >= 2 then set waitSeconds to (item 2 of argv) as integer

	tell application appName to activate
	delay waitSeconds
	return ""
end run
