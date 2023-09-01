Add-Type -AssemblyName System.Windows.Forms,PresentationFramework;

# Plans: add uninstaller and cpp sim support
# - auto check for updates from github

$VER = "1.0"
$FONT_FAMILY = "Microsoft Sans Serif"
$WIN_SIZE = New-Object System.Drawing.Size(490, 500)
$WIN_TITLE = "2024 FRC Tools Installer"

$WPILIB_VER = "2023.4.3"
$ADVANTAGESCOPE_VER = "2.3.0"

$WPILIB_LINK = "https://github.com/wpilibsuite/allwpilib/releases/download/v2023.4.3/WPILib_Windows-2023.4.3.iso"

# $GIT_COMMAND = "winget install --id Git.Git -e --source winget"
# $LAZYGIT_COMMAND = "winget install -e --id=JesseDuffield.lazygit"

# Set-Variable -Name path -Value "D:\frc\installers" -Scope Script # debug
Set-Variable -Name path -Value "C:\Users\Public\Downloads" -Scope Script
Set-Variable -Name isCreatingFolder -Value $true -Scope Script
Set-Variable -Name itemsToInstall -Value @() -Scope Script

Set-Variable -Name currentInstallStep -Value 0 -Scope Script
Set-Variable -Name installStepsMax -Value 0 -Scope Script
Set-Variable -Name currentPackageIndex -Value 0 -Scope Script
Set-Variable -Name packageMax -Value 0 -Scope Script

Function ShowProgressBar {
    param (
        $ctrls,
        $state
    )
    foreach ($ctrl in $ctrls) {
        $ctrl.Enabled = $state
    }
    if (!$state) {
        $p_progressBar.Value = 0
        $p_progressBar.Visible = !$state
        $l_progressBar.Visible = !$state
    }
}

Function UpdateProgressBar {
    param (
        $pBarProgress,
        $pBarMax
    )
    $p_progressBar.Maximum = $pBarMax
    $p_progressBar.Value = $pBarProgress
}

Function ShowFinishedState {
    $l_progressBar.Text = "[" + $installStepsMax + "/" + $installStepsMax + "] Finished!"
    CenterControl -ctrl $l_progressBar
    $p_progressBar.Value = $p_progressBar.Maximum
    $b_cancel.Enabled = $true
}

Function CheckReadyInstall {
    if ($t_currentDownloadDir.Text -eq "") {
        $b_startInstall.Enabled = $false
        return
    }
    if ($c_selectWPILib.Checked -eq $false -and $c_selectGit.Checked -eq $false -and $c_selectAdvantageScope.Checked -eq $false -and $c_selectSimSupport.Checked -eq $false -and $c_selectLazygit.Checked -eq $false) {
        $b_startInstall.Enabled = $false
        return
    }

    $b_startInstall.Enabled = $true
}

Function CenterControl {
    param (
        $ctrl,
        $offset,
        $window
    )
    if ($null -eq $offset) {
        $offset = 0
    }
    if ($null -eq $window) {
        $window = $win
    }
    $ctrl.Left = (($window.Width - $ctrl.Width) / 2) + $offset - 5
}

$win = New-Object System.Windows.Forms.Form
$win.MinimizeBox = $false
$win.MaximizeBox = $false
$win.StartPosition = "CenterScreen"
$win.FormBorderStyle = "FixedSingle"
# $win.AutoSize = $true
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
    $all_text = @($l_title, $l_mainInstallersDir, $t_currentDownloadDir, $l_selections, $g_selections, $c_selectWPILib, $c_selectGit, $c_selectAdvantageScope, $c_selectSimSupport, $c_selectLazygit, $c_selectLazygitTheme, $c_selectLazygitAddPath, $b_cancel, $b_startInstall)
    $font_sizes = @(16, 8.25, 10, 8.25, 8.25, 9, 9, 9, 9, 9, 9, 9, 10, 10)
    $bold_states = @(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)
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
$l_mainInstallersDir.Text = "This is where installer files will be temporarily downloaded to. We recommend`r`nusing your downloads folder. Make sure there is enough space on the disk"
$l_mainInstallersDir.TextAlign = "MiddleCenter"
$win.Controls.Add($l_mainInstallersDir)
CenterControl -ctrl $l_mainInstallersDir

$t_currentDownloadDir = New-Object System.Windows.Forms.TextBox
$t_currentDownloadDir.Top = $l_mainInstallersDir.Bottom + 5
$t_currentDownloadDir.Size = New-Object System.Drawing.Size(300, 80)
$t_currentDownloadDir.Text = "C:\Users\Public\Downloads\2024FRCInstaller"
$t_currentDownloadDir.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$t_currentDownloadDir.TabStop = $false
$t_currentDownloadDir.Add_TextChanged({
    $tempText = $t_currentDownloadDir.Text
    if ($t_currentDownloadDir.Text.EndsWith("\") -eq $true -or $t_currentDownloadDir.Text.EndsWith("/") -eq $true) {
        $tempText = $tempText.Substring(0, $t_currentDownloadDir.Text.Length - 1)
    }
    if ($tempText.EndsWith("\2024FRCInstaller") -eq $false) {
        Set-Variable -Name path -Value $tempText -Scope Script
        Set-Variable -Name isCreatingFolder -Value $false -Scope Script
    } else {
        Set-Variable -Name path -Value $tempText.Substring(0, $tempText.Length - 17) -Scope Script
        Set-Variable -Name isCreatingFolder -Value $true -Scope Script
    }
    CheckReadyInstall
})
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
    Set-Variable -Name path -Value $f_mainInstallersDirFileDialog.SelectedPath -Scope Script
    $t_currentDownloadDir.Text = $f_mainInstallersDirFileDialog.SelectedPath + "\2024FRCInstaller"
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
$c_selectGit.Text = "Git (source code management)"
$c_selectGit.Left = $c_selectWPILib.Left
$c_selectGit.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectGit)

$c_selectLazygit = New-Object System.Windows.Forms.CheckBox
$c_selectLazygit.AutoSize = $true
$c_selectLazygit.Top = $c_selectGit.Bottom + 5
$c_selectLazygit.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectLazygit.Text = "LazyGit (git interface)"
$c_selectLazygit.Left = $c_selectWPILib.Left
$c_selectLazygit.Add_CheckedChanged({
    $c_selectLazygitAddPath.Visible = $c_selectLazygit.Checked
    $c_selectLazygitAddPath.Checked = $false
    $c_selectLazygitTheme.Visible = $c_selectLazygit.Checked
    $c_selectLazygitTheme.Checked = $false

    CheckReadyInstall
})
$g_selections.Controls.Add($c_selectLazygit)

$c_selectLazygitTheme = New-Object System.Windows.Forms.CheckBox
$c_selectLazygitTheme.AutoSize = $true
$c_selectLazygitTheme.Top = $c_selectGit.Bottom + 5
$c_selectLazygitTheme.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectLazygitTheme.Text = "LR Theme"
$c_selectLazygitTheme.Left = $c_selectLazygit.Right + 12
$c_selectLazygitTheme.Visible = $false
$c_selectLazygitTheme.Enabled = $false
$g_selections.Controls.Add($c_selectLazygitTheme)

$c_selectLazygitAddPath = New-Object System.Windows.Forms.CheckBox
$c_selectLazygitAddPath.AutoSize = $true
$c_selectLazygitAddPath.Top = $c_selectGit.Bottom + 5
$c_selectLazygitAddPath.Font = New-Object System.Drawing.Font($FONT_FAMILY, 9)
$c_selectLazygitAddPath.Text = "``lg`` shortcut"
$c_selectLazygitAddPath.Left = $c_selectLazygitTheme.Right + 12
$c_selectLazygitAddPath.Visible = $false
# $c_selectLazygitAddPath.Add_CheckedChanged({CheckReadyInstall})
$g_selections.Controls.Add($c_selectLazygitAddPath)

$c_selectAdvantageScope = New-Object System.Windows.Forms.CheckBox
$c_selectAdvantageScope.AutoSize = $true
$c_selectAdvantageScope.Top = $c_selectLazygit.Bottom + 5
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
$b_cancel.Text = "Exit"
$b_cancel.Add_Click({
    $win.Close()
})
$win.Controls.Add($b_cancel)
CenterControl -ctrl $b_cancel -offset -108

$p_progressBar = New-Object System.Windows.Forms.ProgressBar
$p_progressBar.Size = New-Object System.Drawing.Size(400, 20)
$p_progressBar.Style = "Continuous"
$p_progressBar.Visible = $false
$p_progressBar.Minimum = 0
$p_progressBar.Maximum = 10
$p_progressBar.Value = 5
$p_progressBar.Step = 1
$win.Controls.Add($p_progressBar)
$p_progressBar.Top = $b_cancel.Top - $p_progressBar.Height - 15
CenterControl -ctrl $p_progressBar

$l_progressBar = New-Object System.Windows.Forms.Label
$l_progressBar.AutoSize = $true
$l_progressBar.Visible = $false
$l_progressBar.Font = New-Object System.Drawing.Font($FONT_FAMILY, 8)
$l_progressBar.Text = "Awaiting... (you should not see this!)"
$l_progressBar.TextAlign = "MiddleCenter"
$win.Controls.Add($l_progressBar)
$l_progressBar.Top = $p_progressBar.Top - $l_progressBar.Height - 1
CenterControl -ctrl $l_progressBar

$b_progressBarPlaceholderConfirm = New-Object System.Windows.Forms.Button
$b_progressBarPlaceholderConfirm.Size = New-Object System.Drawing.Size(250, ($p_progressBar.Height + $l_progressBar.Height - 10))
$b_progressBarPlaceholderConfirm.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10)
$b_progressBarPlaceholderConfirm.Text = "Continue with Installation"
$b_progressBarPlaceholderConfirm.Visible = $false
$b_progressBarPlaceholderConfirm.Add_Click({
    $b_progressBarPlaceholderConfirm.Visible = $false
    $p_progressBar.Visible = $true
    $l_progressBar.Visible = $true
    Set-Variable -Name installQueue_continueOnce -Value $true -Scope Script
})
$win.Controls.Add($b_progressBarPlaceholderConfirm)
$b_progressBarPlaceholderConfirm.Top = $l_progressBar.Top + 10
CenterControl -ctrl $b_progressBarPlaceholderConfirm

$b_startInstall = New-Object System.Windows.Forms.Button
$b_startInstall.Top = $win.Bottom - 125
$b_startInstall.Size = New-Object System.Drawing.Size(187, 50)
$b_startInstall.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10, [System.Drawing.FontStyle]::Bold)
$b_startInstall.Text = "Start Install"
$b_startInstall.Add_Click({
    # checks
    $testPath = $(Test-Path -LiteralPath $path)
    if ($testPath -eq $false) {
        [System.Windows.MessageBox]::Show("Please choose a valid folder!", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    if ($isCreatingFolder) {
        # New-Item -Path $path -ItemType directory -Name "2024FRCInstaller" | Out-Null
        # Set-Variable -Name path -Value ($path + "\2024FRCInstaller") -Scope Script
        # Set-Variable -Name isCreatingFolder -Value $false -Scope Script
    }

    # TODO: check disk space

    # launch confirmation dialog
    Set-Variable -Name itemsToInstall -Value @() -Scope Script
    $itemsToInstallText = ""
    if ($c_selectWPILib.Checked) {
        $itemsToInstallText += "WPILib + VSCode`r`n"
        $(Get-Variable -Name itemsToInstall -Scope Script).Value += "WPILib"
    }
    if ($c_selectGit.Checked) {
        $itemsToInstallText += "Git`r`n"
        $(Get-Variable -Name itemsToInstall -Scope Script).Value += "Git"
    }
    if ($c_selectLazygit.Checked) {
        $itemsToInstallText += "LazyGit" + ("`r`n    -> LR Theme" * $c_selectLazygitTheme.Checked) + ("`r`n    -> Command Shortcut" * $c_selectLazygitAddPath.Checked) + "`r`n"
        $(Get-Variable -Name itemsToInstall -Scope Script).Value += "LazyGit"
    }
    if ($c_selectAdvantageScope.Checked) {
        $itemsToInstallText += "AdvantageScope`r`n"
        $(Get-Variable -Name itemsToInstall -Scope Script).Value += "AdvantageScope"
    }
    if ($c_selectSimSupport.Checked) {
        $itemsToInstallText += "C++ Simulation Support`r`n"
        $(Get-Variable -Name itemsToInstall -Scope Script).Value += "SimSupport"
    }

    $sConf_t_items.Text = $itemsToInstallText
    $win_confirm.ShowDialog() | Out-Null
})
$win.Controls.Add($b_startInstall)
$b_startInstall.Left = $b_cancel.Right + 25

$l_notAffiliated = New-Object System.Windows.Forms.Label
$l_notAffiliated.AutoSize = $true
$l_notAffiliated.Font = New-Object System.Drawing.Font($FONT_FAMILY, 6)
$l_notAffiliated.Text = "v" + $VER + " | Made by Team 862 | Not Affiliated with FIRST"
$l_notAffiliated.TextAlign = "MiddleRight"
$win.Controls.Add($l_notAffiliated)
$l_notAffiliated.Top = $win.Bottom - $l_notAffiliated.Height - 40

# confirm dialog
$win_confirm = New-Object System.Windows.Forms.Form
$win_confirm.MinimizeBox = $false
$win_confirm.MaximizeBox = $false
$win_confirm.StartPosition = "CenterScreen"
$win_confirm.FormBorderStyle = "FixedSingle"
$win_confirm.AutoSize = $true
$win_confirm.Size = New-Object System.Drawing.Size(300, 260)
$win_confirm.Text = "Confirm Install"

$sConf_l_mainText = New-Object System.Windows.Forms.Label
$sConf_l_mainText.AutoSize = $true
$sConf_l_mainText.Top = 10
$sConf_l_mainText.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10.5)
$sConf_l_mainText.Text = "Are you sure you want to install the`r`nfollowing items?"
$sConf_l_mainText.TextAlign = "MiddleCenter"
$win_confirm.Controls.Add($sConf_l_mainText)
CenterControl -ctrl $sConf_l_mainText -window $win_confirm

$sConf_t_items = New-Object System.Windows.Forms.TextBox
$sConf_t_items.Top = $sConf_l_mainText.Bottom + 10
$sConf_t_items.Size = New-Object System.Drawing.Size(250, 100)
$sConf_t_items.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10)
$sConf_t_items.Multiline = $true
$sConf_t_items.ReadOnly = $true
$sConf_t_items.TabStop = $false
$win_confirm.Controls.Add($sConf_t_items)
CenterControl -ctrl $sConf_t_items -window $win_confirm
$sConf_t_items.Left = $sConf_t_items.Left - 3

$sConf_b_cancel = New-Object System.Windows.Forms.Button
$sConf_b_cancel.Top = $win_confirm.Bottom - 90
$sConf_b_cancel.Left = 30
$sConf_b_cancel.Size = New-Object System.Drawing.Size(100, 40)
$sConf_b_cancel.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10)
$sConf_b_cancel.Text = "Cancel"
$sConf_b_cancel.Add_Click({
    $win_confirm.Close()
})
$win_confirm.Controls.Add($sConf_b_cancel)

$sConf_b_startInstall = New-Object System.Windows.Forms.Button
$sConf_b_startInstall.Top = $win_confirm.Bottom - 90
$sConf_b_startInstall.Left = $sConf_b_cancel.Right + 25
$sConf_b_startInstall.Size = New-Object System.Drawing.Size(100, 40)
$sConf_b_startInstall.Font = New-Object System.Drawing.Font($FONT_FAMILY, 10, [System.Drawing.FontStyle]::Bold)
$sConf_b_startInstall.Text = "Confirm"
$sConf_b_startInstall.Add_Click({
    $win_confirm.Close()

    ShowProgressBar $toDisable -state $false

    $pBarSteps = 0
    $itemsToInstall = $(Get-Variable -Name itemsToInstall -Scope Script).Value
    foreach ($item in $itemsToInstall) {
        switch ($item) {
            "WPILib" {
                $pBarSteps += 2
            }
            "Git" {
                $pBarSteps += 1
            }
            "LazyGit" {
                $pBarSteps += 1
            }
            "AdvantageScope" {
                $pBarSteps += 1
            }
            "SimSupport" {
                $pBarSteps += 1
            }
        }
    }

    Set-Variable -Name currentInstallStep -Value 0 -Scope Script
    Set-Variable -Name installStepsMax -Value $pBarSteps -Scope Script
    Set-Variable -Name currentPackageIndex -Value 0 -Scope Script
    Set-Variable -Name packageMax -Value ($itemsToInstall.Length) -Scope Script
    
    Set-Variable -Name installQueue_continueOnce -Value $true -Scope Script
    $timer_installQueue.Start()
})
$win_confirm.Controls.Add($sConf_b_startInstall)

$installQueue_continueOnce = $false
$timer_installQueue = New-Object System.Windows.Forms.Timer
$timer_installQueue.Interval = 100
$timer_installQueue.Add_Tick({
    if ($installQueue_continueOnce -eq $false) { return }
    Set-Variable -Name installQueue_continueOnce -Value $false -Scope Script

    if ($packageMax -eq ($currentPackageIndex + 1)) { # + 1 since $currentPackageIndex starts at 0
        $timer_installQueue.Stop()
        ShowFinishedState
        # Write-Host "timer destroyed: " $currentPackageIndex
    }
    
    InstallItem $itemsToInstall[$currentPackageIndex]
    Set-Variable -Name currentPackageIndex -Value ($currentPackageIndex + 1) -Scope Script
})

$timer_afterWPIInstallContinue = New-Object System.Windows.Forms.Timer
$timer_afterWPIInstallContinue.Interval = 4500 # fake timer until i can come up with something better
$timer_afterWPIInstallContinue.Add_Tick({
    $b_progressBarPlaceholderConfirm.Visible = $true
    $p_progressBar.Visible = $false
    $l_progressBar.Visible = $false
    $timer_afterWPIInstallContinue.Stop()
})

$webClient = New-Object System.Net.WebClient

Function InstallItem {
    param (
        $itemType
    )
    switch ($itemType) {
        "WPILib" {
            Set-Variable -Name currentInstallStep -Value ($currentInstallStep + 1) -Scope Script
            $l_progressBar.Text = "[1/" + $installStepsMax + "] Downloading WPILib " + $WPILIB_VER + "..."
            CenterControl -ctrl $l_progressBar
            $webClient.Add_DownloadProgressChanged({
                # Write-Host $($args[1].ProgressPercentage)
                UpdateProgressBar $args[1].ProgressPercentage 100
            })
            $webClient.Add_DownloadFileCompleted({
                UpdateProgressBar 0 100
                # $l_progressBar.Text = "[1/" + $installStepsMax + "] Finished downloading WPILib " + $WPILIB_VER
                # CenterControl -ctrl $l_progressBar

                Set-Variable -Name currentInstallStep -Value ($currentInstallStep + 1) -Scope Script
                $l_progressBar.Text = "[2/" + $installStepsMax + "] Launching WPILib " + $WPILIB_VER + " Installer..."
                CenterControl -ctrl $l_progressBar

                if ($(Test-Path ($path + "\WPILIB_Windows-" + $WPILIB_VER + ".iso")) -eq $false) {
                    $l_progressBar.Text = "Failed to install WPILib " + $WPILIB_VER
                    CenterControl -ctrl $l_progressBar
                    [System.Windows.MessageBox]::Show("Could not locate download. Check the path or try downloading and installing manually.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    ShowProgressBar $toDisable -state $true
                    return
                }

                $driveLetter = (Mount-DiskImage -ImagePath ($path + "\WPILIB_Windows-" + $WPILIB_VER + ".iso") -PassThru | Get-Volume).DriveLetter

                Invoke-Expression ($driveLetter + ":\WPILibInstaller.exe")

                # maybeeeee check the actual installer window progress somehow and update the progress bar accordingly here maybe instead of waiting for user input to continue ahahaahahhh
                if ($installStepsMax -eq $currentInstallStep) {
                    $timer_installQueue.Stop()
                    ShowFinishedState
                    $l_progressBar.Text = "[" + $installStepsMax + "/" + $installStepsMax + "] Finished downloading WPILib " + $WPILIB_VER + ". Continue installation in installer window."
                    CenterControl -ctrl $l_progressBar
                    return
                }
                $timer_afterWPIInstallContinue.Start()
            })
            $webClient.DownloadFileAsync($WPILIB_LINK, "." + "\WPILib_Windows-" + $WPILIB_VER + ".iso")
            # $webClient.DownloadFileAsync("https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.progressbar?view=windowsdesktop-7.0", "." + "\WPILib_Window-" + $WPILIB_VER + ".iso") # debug test
        }
        "Git" {
            Set-Variable -Name currentInstallStep -Value ($currentInstallStep + 1) -Scope Script
            $l_progressBar.Text = "[" + $currentInstallStep + "/" + $installStepsMax + "] Installing Git..."
            CenterControl -ctrl $l_progressBar
            # one time it spammed this message box, and i have no idea what happened but it doesnt seem to do that anymore??
            [System.Windows.MessageBox]::Show("Git is not currently supported. Please install manually.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
        "LazyGit" {
            # [System.Windows.MessageBox]::Show("LazyGit is not currently supported. Please install manually.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }

}

# computes diff in spacing combining two controls (debugging for centering)
Function DiffTuner {
    param (
        $left,
        $right
    )
    # Write-Host $left.Left
    # Write-Host ($win.Width - $right.Right)
    Write-Host ((($left.Left + ($win_confirm.Width - $right.Right - 5))/2) - $left.Left) -ForegroundColor Green
}

# DiffTuner $sConf_b_cancel $sConf_b_startInstall


$fonts = @("Rage Italic", "Wingdings", "Comic Sans MS", "Webdings")

$toDisable = @($l_title, $t_currentDownloadDir, $b_showFileDialog, $b_startInstall, $c_selectWPILib, $c_selectGit, $c_selectLazygit, $c_selectLazygitTheme, $c_selectLazygitAddPath, $b_cancel)

$win.ShowDialog() | Out-Null

$timer_installQueue.Dispose()
$timer_afterWPIInstallContinue.Dispose()