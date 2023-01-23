# https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3
using namespace System.Management.Automation.Host;
using namespace System.Collections.ObjectModel;


function Update-PowershellProfile {
  . $PROFILE
}



function New-TemporaryDirectory {
  # https://stackoverflow.com/a/34559554
  $parent = [System.IO.Path]::GetTempPath()
  $name = [System.IO.Path]::GetRandomFileName()
  return New-Item -ItemType Directory -Path (Join-Path $parent $name)
}


function Test-PendingReboot {
  # https://stackoverflow.com/a/43596428/9156059
  # https://gist.github.com/altrive/5329377
  # https://web.archive.org/web/20190503035319/https://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542
  if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
  if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
  if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
  try {
    $util = [wmiclass]"\.\root\ccm\clientsdk:CCM_ClientUtilities"
    $status = $util.DetermineIfRebootPending()
    if (($null -ne $status) -and $status.RebootPending) {
      return $true
    }
  }
  catch {}
  return $false
}


# usage example: $confirmation = Get-Confirmation 'File already exists: profile.ovpn' 'File already exists in destination folder. It will be overwritten. Do you want to continue?' -choices @('&Yes','&No') -choicesDescriptions @('Overwrite the file.','Cancel the operation and halt the script.') -defaultChoice 1
function Get-Confirmation(
  [string] $title = '',
  [string] $prompt,
  [string[]] $choices = @('&Yes', '&No'),
  [int] $default = -1,
  [int] $confirmIndex = 0,
  [string[]] $choicesDescriptions = @()
) {
  $decision = Get-Choice -title $title -prompt $prompt -choices $choices -default $default -choicesDescriptions $choicesDescriptions
  return $decision -eq $confirmIndex
}

# usage example: $choice = Get-Choice 'File already exists: profile.ovpn' 'File already exists in destination folder. What would you like to do?' -choices @('&Overwrite','&Cancel','&Rename the file') -choicesDescriptions @('Overwrite the destination file.','Cancel the operation and halt the script.','Automatically rename the file by appending a suffix to its name.') -defaultChoice 1
function Get-Choice(
  [string] $title = '',
  [string] $prompt,
  [string[]] $choices,
  [int] $defaultChoice = -1,
  [string[]] $choicesDescriptions = @()
) {
  $choiceCollection = [Collection[ChoiceDescription]]::new()
  for ($i = 0; $i -lt $choices.Length; $i++) {
    $choice = [ChoiceDescription]::new($choices[$i], $choicesDescriptions[$i])
    $choiceCollection.Add($choice)
  }
  return $Host.UI.PromptForChoice($title, $prompt, $choiceCollection, $defaultChoice)
}


Export-ModuleMember -Function *
