Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -MemberDefinition @"
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr FindWindow(string c, string n);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
"@ -Name "N" -Namespace W

$WM_CLOSE = 0x0010
$SW_HIDE  = 0
$total    = 0
$running  = $true

# ── Скрываем консоль ──
$console = [W.N]::GetConsoleWindow()
if ($console -ne [IntPtr]::Zero) {
    [void][W.N]::ShowWindow($console, $SW_HIDE)
}

# ── Иконка в трее ──
$icon = New-Object System.Drawing.Icon([System.Drawing.SystemIcons]::Application, 16, 16)

$exitItem = New-Object System.Windows.Forms.MenuItem
$exitItem.Text = "Exit"

$menu = New-Object System.Windows.Forms.ContextMenu
$menu.MenuItems.Add($exitItem)

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $icon
$tray.Text = "1C popup monitor"
$tray.ContextMenu = $menu
$tray.Visible = $true

$exitPressed = $false
$exitItem.Add_Click({
    $script:exitPressed = $true
    $script:running = $false
})

while ($running) {
    # V8NotificationWindow -> SW_HIDE
    $h = [W.N]::FindWindow("V8NotificationWindow", $null)
    if (($h -ne [IntPtr]::Zero) -and ([W.N]::IsWindow($h))) {
        [void][W.N]::ShowWindow($h, $SW_HIDE)
        $total++
    }

    # V8ConfirmationWindow -> WM_CLOSE
    $h = [W.N]::FindWindow("V8ConfirmationWindow", $null)
    if (($h -ne [IntPtr]::Zero) -and ([W.N]::IsWindow($h))) {
        [void][W.N]::PostMessage($h, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $total++
    }

    # V8ConfirmationWindowTaxi -> WM_CLOSE
    $h = [W.N]::FindWindow("V8ConfirmationWindowTaxi", $null)
    if (($h -ne [IntPtr]::Zero) -and ([W.N]::IsWindow($h))) {
        [void][W.N]::PostMessage($h, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $total++
    }

    [System.Windows.Forms.Application]::DoEvents()

    Start-Sleep -Milliseconds 100
}

$tray.Visible = $false
$tray.Dispose()