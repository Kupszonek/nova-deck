extends Node


func execute_button(button_id: int):
	var button := ConfigManager.get_button(button_id)

	if button.is_empty():
		return

	var shortcut = button.get("shortcut", {})

	if shortcut is Dictionary and not shortcut.is_empty():
		execute_shortcut(shortcut)
		return

	var path: String = button.get("path", "")

	if path.is_empty() or not FileAccess.file_exists(path):
		return

	if path.get_extension().to_lower() == "lnk":
		launch_shortcut(path)
	else:
		OS.create_process(path, [])


func launch_shortcut(path: String):
	var safe_path := path.replace("'", "''")

	var ps_script := """
$path = '%s'

$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut($path)

$target = $shortcut.TargetPath
$args = $shortcut.Arguments

if ([string]::IsNullOrWhiteSpace($target)) {
	Start-Process -FilePath $path
	exit
}

$processName = [System.IO.Path]::GetFileNameWithoutExtension($target)

# Discord i inne aplikacje Squirrel:
# Update.exe --processStart Discord.exe
if (
	$processName -ieq 'Update' -and
	$args -match '--processStart\\s+["'']?([^"'']+\\.exe)'
) {
	$processName = [System.IO.Path]::GetFileNameWithoutExtension($matches[1])
}

$process = Get-Process `
	-Name $processName `
	-ErrorAction SilentlyContinue |
	Where-Object { $_.MainWindowHandle -ne 0 } |
	Select-Object -First 1

if ($process) {
	Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class NovaWindow
{
	[DllImport("user32.dll")]
	public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
'@

	# SW_RESTORE
	[NovaWindow]::ShowWindowAsync(
		$process.MainWindowHandle,
		9
	) | Out-Null

	Start-Sleep -Milliseconds 60

	$ws.AppActivate($process.Id)
	exit
}

Start-Process -FilePath $path
""" % safe_path

	var encoded_command := Marshalls.raw_to_base64(
		ps_script.to_utf16_buffer()
	)

	OS.create_process(
		"powershell.exe",
		[
			"-NoProfile",
			"-ExecutionPolicy", "Bypass",
			"-EncodedCommand", encoded_command
		]
	)
func execute_shortcut(shortcut: Dictionary):
	var keys := shortcut_to_sendkeys(shortcut)

	if keys.is_empty():
		return

	var safe_keys := keys.replace("'", "''")

	var ps_script := """
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('%s')
""" % safe_keys

	OS.create_process(
		"powershell.exe",
		[
			"-NoProfile",
			"-WindowStyle", "Hidden",
			"-Command", ps_script
		]
	)

func shortcut_to_sendkeys(shortcut: Dictionary) -> String:
	var result := ""

	if shortcut.get("ctrl", false):
		result += "^"

	if shortcut.get("alt", false):
		result += "%"

	if shortcut.get("shift", false):
		result += "+"

	var keycode := int(shortcut.get("keycode", 0))
	var key_name := OS.get_keycode_string(keycode)

	match keycode:
		KEY_ENTER:
			return result + "{ENTER}"

		KEY_TAB:
			return result + "{TAB}"

		KEY_ESCAPE:
			return result + "{ESC}"

		KEY_SPACE:
			return result + " "

		KEY_BACKSPACE:
			return result + "{BACKSPACE}"

		KEY_DELETE:
			return result + "{DELETE}"

		KEY_INSERT:
			return result + "{INSERT}"

		KEY_HOME:
			return result + "{HOME}"

		KEY_END:
			return result + "{END}"

		KEY_PAGEUP:
			return result + "{PGUP}"

		KEY_PAGEDOWN:
			return result + "{PGDN}"

		KEY_UP:
			return result + "{UP}"

		KEY_DOWN:
			return result + "{DOWN}"

		KEY_LEFT:
			return result + "{LEFT}"

		KEY_RIGHT:
			return result + "{RIGHT}"

	if key_name.length() == 1:
		match key_name:
			"+":
				return result + "{+}"

			"^":
				return result + "{^}"

			"%":
				return result + "{%}"

			_:
				return result + key_name.to_lower()

	if key_name.begins_with("F"):
		return result + "{" + key_name + "}"

	return ""
