Add-Type -AssemblyName System.Windows.Forms,PresentationFramework;

# Plans: add uninstaller and cpp sim support

$VER = "1.0"
$FONT_FAMILY = "Microsoft Sans Serif"
$WIN_SIZE = New-Object System.Drawing.Size(490, 450)
$WIN_TITLE = "2024 FRC Tools Installer"

$WPILIB_VER = "2023.4.3"
$ADVANTAGESCOPE_VER = "2.3.0"


Function ToggleEnableStates {
    param (
        $ctrls,
        $state
    )
    foreach ($ctrl in $ctrls) {
        $ctrl.Enabled = $state
    }
}

Function CheckReadyInstall {
    if ($t_currentDownloadDir.Text -eq "") {
        $b_startInstall.Enabled = $false
        return
    }
    if ($c_selectWPILib.Checked -eq $false -and $c_selectGit.Checked -eq $false -and $c_selectAdvantageScope.Checked -eq $false -and $c_selectSimSupport.Checked -eq $false) {
        $b_startInstall.Enabled = $false
        return
    }

    $b_startInstall.Enabled = $true
}

Function CenterControl {
    param (
        $ctrl,
        $offset
    )
    if ($null -eq $offset) {
        $offset = 0
    }
    $ctrl.Left = (($win.Width - $ctrl.Width) / 2) + $offset - 5
}

$win = New-Object System.Windows.Forms.Form
$win.MinimizeBox = $false
$win.MaximizeBox = $false
$win.StartPosition = "CenterScreen"
$win.FormBorderStyle = "FixedSingle"
$win.AutoSize = $true
$win.Size = $WIN_SIZE
$win.Text = $WIN_TITLE

$l_title = New-Object System.Windows.Forms.Label
$l_title.AutoSize = $true
$l_title.Font = New-Object System.Drawing.Font($FONT_FAMILY, 16, [System.Drawing.FontStyle]::Bold)
$l_title.Text = $WIN_TITLE
$l_title.TextAlign = "MiddleCenter"
$l_title.Top = 10
$l_title.Add_Click({
    $new_font = $fonts[(Get-Random -Minimum 0 -Maximum $fonts.Length)]
    $all_text = @($l_title, $l_mainInstallersDir, $t_currentDownloadDir, $l_selections, $g_selections, $c_selectWPILib, $c_selectGit, $c_selectAdvantageScope, $c_selectSimSupport, $b_cancel, $b_startInstall)
    $font_sizes = @(16, 8.25, 10, 8.25, 8.25, 9, 9, 9, 9, 10, 10)
    $bold_states = @(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
    for ($i = 0; $i -lt $all_text.Length; $i++) {
        $all_text[$i].Font = New-Object System.Drawing.Font($new_font, $font_sizes[$i], [System.Drawing.FontStyle]$bold_states[$i])
    }
    $ok_fonts = @("Rage Italic", "Comic Sans MS")
    if ($ok_fonts.Contains($new_font)) {
        $win.size = $WIN_SIZE
    }
})
$win.Controls.Add($l_title)
CenterControl -ctrl $l_title

$l_mainInstallersDir = New-Object System.Windows.Forms.Label
$l_mainInstallersDir.AutoSize = $true
$l_mainInstallersDir.Top = $l_title.Bottom + 20
$l_mainInstallersDir.Font = New-Object System.Drawing.Font($FONT_FAMILY, 8.25)
$l_mainInstallersDir.Text = "This is where installer files will be temporarily downloaded to. We recommend simply
using your downloads folder. Make sure there is enough space on the disk (~4GB)"
$l_mainInstallersDir.TextAlign = "MiddleCenter"
$win.Controls.Add($l_mainInstallersDir)
CenterControl -ctrl $l_mainInstallersDir

$t_currentDownloadDir = New-Object System.Windows.Forms.TextBox
$t_currentDownloadDir.Top = $l_mainInstallersDir.Bottom + 5
$t_currentDownloadDir.Size = New-Object System.Drawing.Size(300, 80)
$t_currentDownloadDir.Text = "C:\Users\Public\Public Downloads"
$t_currentDownloadDir.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10)
$t_currentDownloadDir.Add_TextChanged({CheckReadyInstall})
$win.Controls.Add($t_currentDownloadDir)
CenterControl -ctrl $t_currentDownloadDir -offset -48

# incredibly annoying becuase without .net core, you can't use CommonOpenFileDialog and this dialog SUCKS but whatever
$f_mainInstallersDirFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog

$b_showFileDialog = New-Object System.Windows.Forms.Button
$b_showFileDialog.Top = $t_currentDownloadDir.Top
$b_showFileDialog.Size = New-Object System.Drawing.Size(80, $t_currentDownloadDir.Height)
$b_showFileDialog.Text = "Browse..."
$b_showFileDialog.Add_Click({
    $f_mainInstallersDirFileDialog.ShowDialog() | Out-Null
    if ("" -eq $f_mainInstallersDirFileDialog.SelectedPath) { return }
    $t_currentDownloadDir.Text = $f_mainInstallersDirFileDialog.SelectedPath
})
$win.Controls.Add($b_showFileDialog)
$b_showFileDialog.Left = $t_currentDownloadDir.Right + 11

$l_selections = New-Object System.Windows.Forms.Label
$l_selections.AutoSize = $true
$l_selections.Top = $t_currentDownloadDir.Bottom + 12.5
$l_selections.Font = New-Object System.Drawing.Font($FONT_FAMILY, 8.25)
$l_selections.Text = "Please DESELECT any items you currently have installed (ex. Git)"
$l_selections.TextAlign = "MiddleCenter"
$win.Controls.Add($l_selections)
CenterControl -ctrl $l_selections

$g_selections = New-Object System.Windows.Forms.GroupBox
$g_selections.AutoSize = $true
$g_selections.Top = $l_selections.Bottom + 10
$g_selections.Size = New-Object System.Drawing.Size(400, 50)
$g_selections.Text = "Select Items to Install"
$win.Controls.Add($g_selections)
CenterControl -ctrl $g_selections

$c_selectWPILib = New-Object System.Windows.Forms.CheckBox
$c_selectWPILib.AutoSize = $true
$c_selectWPILib.Top = 25
$c_selectWPILib.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectWPILib.Text = "[v" + $WPILIB_VER +  "] WPILib + VSCode (required for robot code)"
$c_selectWPILib.Checked = $true
$c_selectWPILib.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectWPILib)
CenterControl -ctrl $c_selectWPILib -offset (-($g_selections.Left))

$c_selectGit = New-Object System.Windows.Forms.CheckBox
$c_selectGit.AutoSize = $true
$c_selectGit.Top = $c_selectWPILib.Bottom + 5
$c_selectGit.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectGit.Text = "Git (to access our code from Github)"
$c_selectGit.Left = $c_selectWPILib.Left
$c_selectGit.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectGit)

$c_selectAdvantageScope = New-Object System.Windows.Forms.CheckBox
$c_selectAdvantageScope.AutoSize = $true
$c_selectAdvantageScope.Top = $c_selectGit.Bottom + 5
$c_selectAdvantageScope.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectAdvantageScope.Text = "[v" + $ADVANTAGESCOPE_VER + "] AdvantageScope (robot log analysis)"
$c_selectAdvantageScope.Left = $c_selectWPILib.Left
$c_selectAdvantageScope.Enabled = $false
# $c_selectAdvantageScope.Checked = $true
$c_selectAdvantageScope.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectAdvantageScope)

$c_selectSimSupport = New-Object System.Windows.Forms.CheckBox
$c_selectSimSupport.AutoSize = $true
$c_selectSimSupport.Top = $c_selectAdvantageScope.Bottom + 5
$c_selectSimSupport.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectSimSupport.Text = "C++ Simulation Support"
$c_selectSimSupport.Left = $c_selectWPILib.Left
$c_selectSimSupport.Enabled = $false
$c_selectSimSupport.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectSimSupport)

# break in code just for my sake so im not going crazy editing things i dont want to be ediitng (im going clinically insane)

$b_cancel = New-Object System.Windows.Forms.Button
$b_cancel.Top = $win.Bottom - 125
$b_cancel.Size = New-Object System.Drawing.Size(187, 50)
$b_cancel.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10)
$b_cancel.Text = "Cancel"
$b_cancel.Add_Click({
    $win.Close()
})
$win.Controls.Add($b_cancel)
CenterControl -ctrl $b_cancel -offset -108

$b_startInstall = New-Object System.Windows.Forms.Button
$b_startInstall.Top = $win.Bottom - 125
$b_startInstall.Size = New-Object System.Drawing.Size(187, 50)
$b_startInstall.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10, [System.Drawing.FontStyle]::Bold)
$b_startInstall.Text = "Start Install"
$b_startInstall.Add_Click({
    ToggleEnableStates $toDisable -state $false
})
$win.Controls.Add($b_startInstall)
$b_startInstall.Left = $b_cancel.Right + 25

$l_notAffiliated = New-Object System.Windows.Forms.Label
$l_notAffiliated.AutoSize = $true
$l_notAffiliated.Top = $win.Bottom - 55
$l_notAffiliated.Font = New-Object System.Drawing.Font($FONT_FAMILY, 6)
$l_notAffiliated.Text = "v" + $VER + " | Made by Team 862 | Not Affiliated with FIRST"
$l_notAffiliated.TextAlign = "MiddleRight"
$win.Controls.Add($l_notAffiliated)

# computes diff in spacing combining two controls (debugging for centering)
Function DiffTuner {
    param (
        $left,
        $right
    )
    # Write-Host $left.Left
    # Write-Host ($win.Width - $right.Right)
    Write-Host ((($left.Left + ($win.Width - $right.Right - 5))/2) - $left.Left) -ForegroundColor Green
}

# DiffTuner $b_cancel $b_startInstall
# DiffTuner $t_currentDownloadDir $b_showFileDialog

$fonts = @("Rage Italic", "Wingdings", "Comic Sans MS", "Webdings")

$toDisable = @($l_title, $t_currentDownloadDir, $b_showFileDialog, $b_startInstall, $b_cancel, $c_selectWPILib, $c_selectGit)

$win.ShowDialog() | Out-Null