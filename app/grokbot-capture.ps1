Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$mutex = New-Object System.Threading.Mutex($false, "Global\GrokBotCaptureHelper")
if (-not $mutex.WaitOne(0)) {
  Write-Host "grokbot-capture already running"
  exit 0
}

$hookSrc = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class SwallowD {
  const int WH_KEYBOARD_LL = 13;
  const int WM_KEYDOWN = 0x0100;
  const int WM_KEYUP = 0x0101;
  const int WM_SYSKEYDOWN = 0x0104;
  const int VK_CONTROL = 0x11;
  const int VK_LCONTROL = 0xA2;
  const int VK_RCONTROL = 0xA3;
  const int VK_D = 0x44;
  static IntPtr _hook = IntPtr.Zero;
  static LowLevelProc _proc = Hook;
  static bool _seenD;
  static bool _pass;
  static bool _realD;
  static bool _realCtrl;
  public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);
  [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, LowLevelProc fn, IntPtr hMod, uint thread);
  [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr h, int n, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int v);
  [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string n);
  [StructLayout(LayoutKind.Sequential)] struct KBDLLHOOKSTRUCT { public uint vk; public uint scan; public uint flags; public uint time; public UIntPtr extra; }
  static bool CtrlDown() {
    return (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0
        || (GetAsyncKeyState(VK_LCONTROL) & 0x8000) != 0
        || (GetAsyncKeyState(VK_RCONTROL) & 0x8000) != 0;
  }
  static bool IsCtrl(uint vk) {
    return vk == VK_CONTROL || vk == VK_LCONTROL || vk == VK_RCONTROL;
  }
  static IntPtr Hook(int nCode, IntPtr wParam, IntPtr lParam) {
    if (nCode >= 0) {
      var info = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
      if (info.vk != VK_D && !IsCtrl(info.vk)) return CallNextHookEx(_hook, nCode, wParam, lParam);
      int msg = wParam.ToInt32();
      bool injected = (info.flags & 0x10) != 0;
      bool down = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
      bool up = msg == WM_KEYUP || msg == 0x0105;
      if (!_pass && !injected) {
        if (info.vk == VK_D) {
          if (down) _realD = true;
          else if (up) _realD = false;
        }
        if (IsCtrl(info.vk)) {
          if (down) _realCtrl = true;
          else if (up) _realCtrl = false;
        }
      }
      if (_pass) return CallNextHookEx(_hook, nCode, wParam, lParam);
      if (info.vk == VK_D) {
        if (down) {
          if (CtrlDown() || _realCtrl) {
            if (_seenD) return (IntPtr)1;
            _seenD = true;
          }
        } else if (up) {
          _seenD = false;
        }
      }
      if (!_realCtrl && info.vk != VK_D) _seenD = false;
    }
    return CallNextHookEx(_hook, nCode, wParam, lParam);
  }
  public static void Pass(bool on) { _pass = on; }
  public static bool RealChord() { return _realCtrl && _realD; }
  public static void Start() {
    using (Process p = Process.GetCurrentProcess())
    using (ProcessModule m = p.MainModule) {
      _hook = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(m.ModuleName), 0);
    }
  }
}
"@
Add-Type -TypeDefinition $hookSrc
[SwallowD]::Start()

$mouseSrc = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class MouseBox {
  const int WH_MOUSE_LL = 14;
  const int WM_MOUSEMOVE = 0x0200;
  const int WM_LBUTTONDOWN = 0x0201;
  const int WM_LBUTTONUP = 0x0202;
  static IntPtr _hook = IntPtr.Zero;
  static LowLevelProc _proc = Hook;
  public static bool Arm;
  public static bool Boxing;
  public static bool Done;
  public static int X0, Y0, X1, Y1;
  public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);
  [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, LowLevelProc fn, IntPtr hMod, uint thread);
  [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr h, int n, IntPtr w, IntPtr l);
  [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string n);
  [StructLayout(LayoutKind.Sequential)] struct POINT { public int x; public int y; }
  [StructLayout(LayoutKind.Sequential)] struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData; public uint flags; public uint time; public UIntPtr extra; }
  static IntPtr Hook(int nCode, IntPtr wParam, IntPtr lParam) {
    if (nCode >= 0 && Arm) {
      var info = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
      int msg = wParam.ToInt32();
      if (msg == WM_LBUTTONDOWN) {
        Boxing = true; Done = false;
        X0 = X1 = info.pt.x; Y0 = Y1 = info.pt.y;
        return (IntPtr)1;
      }
      if (msg == WM_MOUSEMOVE && Boxing) {
        X1 = info.pt.x; Y1 = info.pt.y;
      }
      if (msg == WM_LBUTTONUP && Boxing) {
        X1 = info.pt.x; Y1 = info.pt.y;
        Boxing = false; Done = true;
        return (IntPtr)1;
      }
    }
    return CallNextHookEx(_hook, nCode, wParam, lParam);
  }
  public static void Start() {
    using (Process p = Process.GetCurrentProcess())
    using (ProcessModule m = p.MainModule) {
      _hook = SetWindowsHookEx(WH_MOUSE_LL, _proc, GetModuleHandle(m.ModuleName), 0);
    }
  }
}
"@
Add-Type -TypeDefinition $mouseSrc
[MouseBox]::Start()

$code = @"
using System;
using System.Drawing;
using System.Windows.Forms;
public class LiveRectForm : Form {
  [System.Runtime.InteropServices.DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
  public LiveRectForm() {
    FormBorderStyle = FormBorderStyle.None;
    ShowInTaskbar = false;
    TopMost = true;
    StartPosition = FormStartPosition.Manual;
    BackColor = Color.Black;
    TransparencyKey = Color.Black;
    Width = 8; Height = 8;
    AllowTransparency = true;
  }
  protected override bool ShowWithoutActivation { get { return true; } }
  public void Place(int x, int y, int w, int h) {
    SetWindowPos(this.Handle, new IntPtr(-1), x, y, w, h, 0x0010 | 0x0040);
    this.Invalidate();
  }
  protected override CreateParams CreateParams {
    get {
      CreateParams cp = base.CreateParams;
      cp.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x00000080;
      return cp;
    }
  }
  protected override void OnPaint(PaintEventArgs e) {
    int w = Width - 8, h = Height - 8;
    if (w < 4 || h < 4) return;
    using (var gold = new Pen(Color.FromArgb(255, 255, 220, 40), 2)) {
      e.Graphics.DrawRectangle(gold, 4, 4, w, h);
    }
  }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Windows.Forms, System.Drawing
$overlay = New-Object LiveRectForm
$overlay.CreateControl(); $overlay.Hide()

$GOLD = [System.Drawing.Color]::FromArgb(255, 201, 162, 39)
$HALO = [System.Drawing.Color]::FromArgb(191, 0, 0, 0)
$outDir = Join-Path $env:TEMP "grokbot-crops"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Get-ChildItem -LiteralPath $outDir -Filter "rect-*.png" -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue

$script:boxing = $false
$script:pendingFile = $null
$script:x0 = 0; $script:y0 = 0; $script:x1 = 0; $script:y1 = 0
$script:lmbWas = $false

function Write-Last($obj) { $obj | ConvertTo-Json -Compress | Set-Content -Encoding utf8 (Join-Path $outDir "last.json") }
function KeyDown([int]$vk) { (([SwallowD]::GetAsyncKeyState($vk) -band 0x8000) -ne 0) }

function CurrentRect {
  $l = [math]::Min($script:x0, $script:x1)
  $t = [math]::Min($script:y0, $script:y1)
  $r = [math]::Max($script:x0, $script:x1)
  $b = [math]::Max($script:y0, $script:y1)
  return @{ L=[int]$l; T=[int]$t; W=[int][math]::Max(1,$r-$l); H=[int][math]::Max(1,$b-$t) }
}

function Update-LiveRect {
  $rc = CurrentRect
  if ($rc.W -lt 6 -or $rc.H -lt 6) { $overlay.Hide(); return }
  $overlay.Place(($rc.L - 4), ($rc.T - 4), ($rc.W + 8), ($rc.H + 8))
}

function Save-Crop {
  $overlay.Hide()
  [System.Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 50
  $rc = CurrentRect
  if ($rc.W -lt 8 -or $rc.H -lt 8) { Write-Last @{ error="tiny" }; return $null }
  $pt = New-Object System.Drawing.Point $rc.L, $rc.T
  $screen = [System.Windows.Forms.Screen]::FromPoint($pt)
  $b = $screen.Bounds
  $bmp = New-Object System.Drawing.Bitmap ([int]$b.Width), ([int]$b.Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen([int]$b.X, [int]$b.Y, 0, 0, $bmp.Size)
  $g.Dispose()
  $sx = [double]$bmp.Width / [math]::Max(1, $b.Width)
  $sy = [double]$bmp.Height / [math]::Max(1, $b.Height)
  $inset = 4
  $x = [int][math]::Max(0, [math]::Floor(($rc.L - $b.X) * $sx) + $inset)
  $y = [int][math]::Max(0, [math]::Floor(($rc.T - $b.Y) * $sy) + $inset)
  $w = [int][math]::Min($bmp.Width - $x, [math]::Ceiling($rc.W * $sx) - ($inset * 2))
  $h = [int][math]::Min($bmp.Height - $y, [math]::Ceiling($rc.H * $sy) - ($inset * 2))
  if ($w -lt 8 -or $h -lt 8) { $bmp.Dispose(); return $null }
  $crop = $bmp.Clone((New-Object System.Drawing.Rectangle $x, $y, $w, $h), $bmp.PixelFormat)
  $long = [math]::Max($crop.Width, $crop.Height)
  if ($long -gt 800) {
    $scale = 800.0 / $long
    $nw = [int][math]::Max(1, [math]::Round($crop.Width * $scale))
    $nh = [int][math]::Max(1, [math]::Round($crop.Height * $scale))
    $resized = New-Object System.Drawing.Bitmap $nw, $nh
    $rg = [System.Drawing.Graphics]::FromImage($resized)
    $rg.DrawImage($crop, 0, 0, $nw, $nh)
    $rg.Dispose(); $crop.Dispose(); $crop = $resized
  }
  $fp = Join-Path $outDir ("rect-{0}.png" -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $crop.Save($fp, [System.Drawing.Imaging.ImageFormat]::Png)
  $crop.Dispose(); $bmp.Dispose()
  return $fp
}



function Flush-Paste {
  $fp = $script:pendingFile
  if (-not $fp) { return }
  if (-not (Test-Path -LiteralPath $fp)) { Write-Last @{ error="no-file" }; $script:pendingFile = $null; return }
  $script:pendingFile = $null
  $col = New-Object System.Collections.Specialized.StringCollection
  [void]$col.Add($fp)
  [System.Windows.Forms.Clipboard]::SetFileDropList($col)
  Start-Sleep -Milliseconds 80
  [System.Windows.Forms.SendKeys]::SendWait("^v")
  Start-Sleep -Milliseconds 220
  Write-Last @{ attach="clip-v" }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 30
$timer.Add_Tick({
  $chord = ((KeyDown 0x11) -and (KeyDown 0x44))
  if ($chord) {
    if (-not $script:talking) {
      $script:talking = $true
      $script:talkAt = Get-Date
      Write-Last @{ chord="start" }
    }
  }
  $talk = [bool]$script:talking
  [MouseBox]::Arm = [bool]($talk -or $chord)
  $script:x0 = [MouseBox]::X0; $script:y0 = [MouseBox]::Y0
  $script:x1 = [MouseBox]::X1; $script:y1 = [MouseBox]::Y1
  if ([MouseBox]::Boxing) {
    $script:boxing = $true
    Update-LiveRect
  }
  if ([MouseBox]::Done) {
    [MouseBox]::Done = $false
    $script:boxing = $false
    $overlay.Hide()
    try {
      $script:pendingFile = Save-Crop
      Write-Last @{ crop="saved" }
    } catch { Write-Last @{ error=$_.Exception.Message } }
  }
  $heldMs = 0; if ($script:talkAt) { $heldMs = ((Get-Date) - $script:talkAt).TotalMilliseconds }
  if (-not $chord -and $script:talking -and $heldMs -ge 250) {
    if ([MouseBox]::Boxing -or $script:boxing) { return }
    $script:talking = $false
    $script:talkAt = $null
    $hadCrop = [bool]$script:pendingFile
    if ($script:pendingFile) { Flush-Paste }
    Write-Last @{ chord="release"; enter=$false; crop=$hadCrop }
    if ($script:boxing) { $script:boxing = $false; $overlay.Hide() }
  }
})
$timer.Start()

$bmp = New-Object System.Drawing.Bitmap 16, 16
$ig = [System.Drawing.Graphics]::FromImage($bmp)
$ig.Clear([System.Drawing.Color]::FromArgb(201, 162, 39))
$ig.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$ig.DrawString("G", $font, [System.Drawing.Brushes]::Black, (New-Object System.Drawing.RectangleF 0, 0, 16, 16), $sf)
$ig.Dispose()
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$tray.Text = "Grok capture - click to quit"
$tray.Visible = $true
$menu = New-Object System.Windows.Forms.ContextMenuStrip
[void]$menu.Items.Add("Quit", $null, { $tray.Visible = $false; [System.Windows.Forms.Application]::Exit() })
$tray.ContextMenuStrip = $menu
$tray.add_MouseUp({
  param($sender, $e)
  if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
    $tray.Visible = $false
    [System.Windows.Forms.Application]::Exit()
  }
})

[System.Windows.Forms.Application]::Run()
