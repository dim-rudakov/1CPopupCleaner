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
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr h, int n);
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr h, int n, int v);
"@ -Name "N" -Namespace W

$WM_CLOSE = 0x0010
$SW_HIDE  = 0
$GWL_EXSTYLE = -20
$WS_EX_APPWINDOW = 0x00040000
$WS_EX_TOOLWINDOW = 0x00000080
$total    = 0
$running  = $true

# ── Скрываем консоль И из панели задач ──
$console = [W.N]::GetConsoleWindow()
if ($console -ne [IntPtr]::Zero) {
    $ex = [W.N]::GetWindowLong($console, $GWL_EXSTYLE)
    $ex = ($ex -band (-bnot $WS_EX_APPWINDOW)) -bor $WS_EX_TOOLWINDOW
    [void][W.N]::SetWindowLong($console, $GWL_EXSTYLE, $ex)
    [void][W.N]::ShowWindow($console, $SW_HIDE)
}

# ── Функция: создать иконку ──
function New-TrayIcon {
    param([string]$type = "check")
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if ($type -eq "check") {
        $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 180, 0))
        $g.FillEllipse($bg, 1, 1, 30, 30)
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, 4)
        $g.DrawLines($pen, @(
            (New-Object System.Drawing.Point 8, 17),
            (New-Object System.Drawing.Point 13, 22),
            (New-Object System.Drawing.Point 25, 10)
        ))
        $pen.Dispose(); $bg.Dispose()
    }
    elseif ($type -eq "shield") {
        $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 120, 220))
        $pts = @(
            (New-Object System.Drawing.Point 16, 4),
            (New-Object System.Drawing.Point 26, 8),
            (New-Object System.Drawing.Point 26, 16),
            (New-Object System.Drawing.Point 16, 28),
            (New-Object System.Drawing.Point 6, 16),
            (New-Object System.Drawing.Point 6, 8)
        )
        $g.FillPolygon($bg, $pts)
        $bg.Dispose()
    }
    else {
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red, 4)
        $g.DrawLine($pen, 7, 7, 25, 25)
        $g.DrawLine($pen, 25, 7, 7, 25)
        $pen.Dispose()
    }
    $g.Dispose()
    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $bmp.Dispose()
    return $icon
}

$icon = New-TrayIcon -type "check"

# ── Иконка в трее ──
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
$icon.Dispose()