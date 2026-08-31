extends Node

const ICON_DIR := "user://icons/"
const TEMP_ICON_PATH := "user://icons/temp_icon.png"
const BUTTON_COUNT := 8
const ICON_SIZE := 256
const ICON_MARGIN := 8


func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(ICON_DIR)
	)

	call_deferred("_migrate_old_icons")


func get_icon_path(button_id: int) -> String:
	var page_id: int = ConfigManager.get_current_page()

	return (
		ICON_DIR
		+ "page_"
		+ str(page_id)
		+ "_button_"
		+ str(button_id)
		+ ".png"
	)


func extract_icon(file_path: String, button_id: int) -> String:
	var godot_path: String = get_icon_path(button_id)
	var output_path: String = ProjectSettings.globalize_path(godot_path)

	if _extract_to_file(file_path, output_path):
		return godot_path

	return ""


func extract_icon_temp(file_path: String) -> ImageTexture:
	var output_path: String = ProjectSettings.globalize_path(
		TEMP_ICON_PATH
	)

	if not _extract_to_file(file_path, output_path):
		return null

	var image: Image = Image.new()

	if image.load(TEMP_ICON_PATH) != OK:
		return null

	return ImageTexture.create_from_image(image)


func _extract_to_file(file_path: String, output_path: String) -> bool:
	if OS.get_name() != "Windows":
		return false

	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)

	var safe_source: String = file_path.replace("'", "''")
	var safe_output: String = output_path.replace("'", "''")

	var ps_script: String = """
Add-Type -AssemblyName System.Drawing

$originalSource = '%s'
$source = $originalSource
$output = '%s'

if ($originalSource.EndsWith(
	'.lnk',
	[System.StringComparison]::OrdinalIgnoreCase
)) {
	try {
		$ws = New-Object -ComObject WScript.Shell
		$shortcut = $ws.CreateShortcut($originalSource)

		$iconLocation = $shortcut.IconLocation
		$target = $shortcut.TargetPath
		$arguments = $shortcut.Arguments
		$resolved = $false

		if (-not [string]::IsNullOrWhiteSpace($iconLocation)) {
			$iconPath = $iconLocation

			if ($iconPath -match '^(.*),(-?\\d+)$') {
				$iconPath = $matches[1]
			}

			$iconPath = $iconPath.Trim('"')
			$iconPath = [Environment]::ExpandEnvironmentVariables(
				$iconPath
			)

			if (Test-Path -LiteralPath $iconPath) {
				$source = $iconPath
				$resolved = $true
			}
		}

		if (
			-not $resolved -and
			-not [string]::IsNullOrWhiteSpace($target)
		) {
			$targetName = [System.IO.Path]::GetFileName($target)

			if (
				$targetName -ieq 'Update.exe' -and
				$arguments -match '--processStart\\s+["'']?([^"'']+\\.exe)'
			) {
				$appExe = $matches[1]
				$baseDir = Split-Path -Parent $target

				$candidate = Get-ChildItem `
					-LiteralPath $baseDir `
					-Recurse `
					-File `
					-Filter $appExe `
					-ErrorAction SilentlyContinue |
					Sort-Object LastWriteTime -Descending |
					Select-Object -First 1

				if ($null -ne $candidate) {
					$source = $candidate.FullName
					$resolved = $true
				}
			}
		}

		if (
			-not $resolved -and
			-not [string]::IsNullOrWhiteSpace($target) -and
			(Test-Path -LiteralPath $target)
		) {
			$source = $target
		}
	}
	catch {
		$source = $originalSource
	}
}

$code = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class NovaIconExtractor
{
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct SHFILEINFO
	{
		public IntPtr hIcon;
		public int iIcon;
		public uint dwAttributes;

		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
		public string szDisplayName;

		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
		public string szTypeName;
	}

	[ComImport]
	[Guid("46EB5926-582E-4017-9FDF-E8998DAA0950")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	interface IImageList
	{
		[PreserveSig]
		int Add(IntPtr hbmImage, IntPtr hbmMask, out int pi);

		[PreserveSig]
		int ReplaceIcon(int i, IntPtr hicon, out int pi);

		[PreserveSig]
		int SetOverlayImage(int iImage, int iOverlay);

		[PreserveSig]
		int Replace(int i, IntPtr hbmImage, IntPtr hbmMask);

		[PreserveSig]
		int AddMasked(IntPtr hbmImage, int crMask, out int pi);

		[PreserveSig]
		int Draw(IntPtr pimldp);

		[PreserveSig]
		int Remove(int i);

		[PreserveSig]
		int GetIcon(int i, uint flags, out IntPtr picon);
	}

	[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
	static extern IntPtr SHGetFileInfo(
		string pszPath,
		uint dwFileAttributes,
		out SHFILEINFO psfi,
		uint cbFileInfo,
		uint uFlags
	);

	[DllImport("shell32.dll")]
	static extern int SHGetImageList(
		int iImageList,
		ref Guid riid,
		out IImageList ppv
	);

	[DllImport("user32.dll")]
	static extern bool DestroyIcon(IntPtr hIcon);

	const uint SHGFI_SYSICONINDEX = 0x00004000;

	const int SHIL_EXTRALARGE = 2;
	const int SHIL_JUMBO = 4;

	const uint ILD_TRANSPARENT = 0x00000001;

	public static bool Extract(
		string path,
		string output
	)
	{
		SHFILEINFO info;

		IntPtr result = SHGetFileInfo(
			path,
			0,
			out info,
			(uint)Marshal.SizeOf(typeof(SHFILEINFO)),
			SHGFI_SYSICONINDEX
		);

		if (result == IntPtr.Zero)
			return false;

		if (SaveIcon(
			info.iIcon,
			SHIL_JUMBO,
			output
		))
		{
			return true;
		}

		return SaveIcon(
			info.iIcon,
			SHIL_EXTRALARGE,
			output
		);
	}

	static bool SaveIcon(
		int iconIndex,
		int imageListSize,
		string output
	)
	{
		Guid iid = new Guid(
			"46EB5926-582E-4017-9FDF-E8998DAA0950"
		);

		IImageList imageList;

		int hr = SHGetImageList(
			imageListSize,
			ref iid,
			out imageList
		);

		if (hr != 0 || imageList == null)
			return false;

		IntPtr iconHandle;

		hr = imageList.GetIcon(
			iconIndex,
			ILD_TRANSPARENT,
			out iconHandle
		);

		if (hr != 0 || iconHandle == IntPtr.Zero)
			return false;

		try
		{
			using (
				Icon icon =
					(Icon)Icon.FromHandle(iconHandle).Clone()
			)
			using (
				Bitmap bitmap = icon.ToBitmap()
			)
			{
				bitmap.Save(
					output,
					System.Drawing.Imaging.ImageFormat.Png
				);
			}

			return true;
		}
		finally
		{
			DestroyIcon(iconHandle);
		}
	}
}
'@

$success = $false

try {
	$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location

	Add-Type `
		-TypeDefinition $code `
		-Language CSharp `
		-ReferencedAssemblies $drawingAssembly `
		-ErrorAction Stop

	$success = [NovaIconExtractor]::Extract(
		$source,
		$output
	)
}
catch {
	$success = $false
}

if (-not $success) {
	try {
		$icon = [System.Drawing.Icon]::ExtractAssociatedIcon(
			$source
		)

		if ($null -ne $icon) {
			$bitmap = $icon.ToBitmap()

			$bitmap.Save(
				$output,
				[System.Drawing.Imaging.ImageFormat]::Png
			)

			$bitmap.Dispose()
			$icon.Dispose()

			$success = $true
		}
	}
	catch {
		$success = $false
	}
}

if (
	$success -and
	(Test-Path -LiteralPath $output)
) {
	exit 0
}

exit 1
""" % [
		safe_source,
		safe_output
	]

	var encoded_command: String = Marshalls.raw_to_base64(
		ps_script.to_utf16_buffer()
	)

	var output: Array = []

	var exit_code: int = OS.execute(
		"powershell.exe",
		[
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-EncodedCommand",
			encoded_command
		],
		output,
		true
	)

	if exit_code != 0:
		print("Błąd pobierania ikony: ", file_path)

		for line in output:
			print(line)

		return false

	if not FileAccess.file_exists(output_path):
		return false

	return _normalize_icon(output_path)


func _normalize_icon(icon_path: String) -> bool:
	var image: Image = Image.new()

	if image.load(icon_path) != OK:
		return false

	image.convert(Image.FORMAT_RGBA8)

	var used_rect: Rect2i = image.get_used_rect()

	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return false

	var cropped: Image = image.get_region(used_rect)

	var available_size: int = ICON_SIZE - ICON_MARGIN * 2

	var scale_x: float = (
		float(available_size)
		/ float(cropped.get_width())
	)

	var scale_y: float = (
		float(available_size)
		/ float(cropped.get_height())
	)

	var scale_factor: float = minf(
		scale_x,
		scale_y
	)

	var new_width: int = maxi(
		1,
		int(float(cropped.get_width()) * scale_factor)
	)

	var new_height: int = maxi(
		1,
		int(float(cropped.get_height()) * scale_factor)
	)

	cropped.resize(
		new_width,
		new_height,
		Image.INTERPOLATE_LANCZOS
	)

	var normalized: Image = Image.create(
		ICON_SIZE,
		ICON_SIZE,
		false,
		Image.FORMAT_RGBA8
	)

	normalized.fill(
		Color(0.0, 0.0, 0.0, 0.0)
	)

	var position := Vector2i(
		int((ICON_SIZE - new_width) / 2.0),
		int((ICON_SIZE - new_height) / 2.0)
	)

	normalized.blit_rect(
		cropped,
		Rect2i(
			0,
			0,
			new_width,
			new_height
		),
		position
	)

	return normalized.save_png(icon_path) == OK


func delete_icon(button_id: int):
	var icon_path: String = get_icon_path(button_id)

	if not FileAccess.file_exists(icon_path):
		return

	DirAccess.remove_absolute(
		ProjectSettings.globalize_path(icon_path)
	)


func delete_all_icons():
	var absolute_dir: String = ProjectSettings.globalize_path(
		ICON_DIR
	)

	var dir: DirAccess = DirAccess.open(absolute_dir)

	if dir == null:
		return

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while not file_name.is_empty():
		if (
			not dir.current_is_dir()
			and file_name.begins_with("page_")
			and file_name.ends_with(".png")
		):
			dir.remove(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()


func _migrate_old_icons():
	for button_id in range(1, BUTTON_COUNT + 1):
		var old_path: String = (
			ICON_DIR
			+ "button_"
			+ str(button_id)
			+ ".png"
		)

		var new_path: String = (
			ICON_DIR
			+ "page_1_button_"
			+ str(button_id)
			+ ".png"
		)

		if not FileAccess.file_exists(old_path):
			continue

		if FileAccess.file_exists(new_path):
			continue

		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(old_path),
			ProjectSettings.globalize_path(new_path)
		)
