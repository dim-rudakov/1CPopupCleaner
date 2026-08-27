Add-Type -MemberDefinition @"
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr hWnd);
"@ -Name "NativeMethods" -Namespace Win32

$WM_CLOSE = 0x0010

# ═══════════════════════════════════════
#  Список классов окон для закрытия
#  Добавляй новые через запятую
# ═══════════════════════════════════════
$targetClasses = @(
    "V8NotificationWindow",
    "V8ConfirmationWindow",
    "V8ConfirmationWindowTaxi"
    # "V8AnotherWindow",  ← раскомментируй для добавления
    # "SomeOtherClass"
)

$totalClosed = 0

Write-Host "Мониторинг классов:" -ForegroundColor Cyan
foreach ($class in $targetClasses) {
    Write-Host "  • $class" -ForegroundColor White
}
Write-Host "Интервал: 100 мс | Через WM_CLOSE" -ForegroundColor Cyan
Write-Host "Для выхода Ctrl+C" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    foreach ($className in $targetClasses) {
        $hWnd = [Win32.NativeMethods]::FindWindow($className, $null)
        
        if ($hWnd -ne [IntPtr]::Zero -and [Win32.NativeMethods]::IsWindow($hWnd)) {
            [void][Win32.NativeMethods]::PostMessage($hWnd, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            $totalClosed++
            Write-Host "[$(Get-Date -Format 'HH:mm:ss.fff')] #$totalClosed Закрыто: $className" -ForegroundColor Green
        }
    }
    
    Start-Sleep -Milliseconds 100
}