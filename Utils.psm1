using namespace System.Management.Automation.Host;
using namespace System.Collections.ObjectModel;

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


# usage example: $confirmation = Get-Confirmation 'Overwrite destination file: profile.ovpn' 'File already exists in destination folder. It will be overwritten. Do you want to continue?' ([System.Management.Automation.Host.ChoiceDescription]::new('&Yes','Overwrite the file.'), [System.Management.Automation.Host.ChoiceDescription]::new('&No','Cancel the operation and halt the script.')) 1
function Get-Confirmation(
  [string] $title = '',
  [string] $prompt,
  [Collection[ChoiceDescription]] $choices = ('&Yes', '&No'),
  [int] $default = -1,
  [int] $confirmIndex = 0
) {
  $decision = Get-Choice -title $title -prompt $prompt -choices $choices -default $default
  return $decision -eq $confirmIndex
}

# usage example: $choice = Get-Choice 'File already exists: profile.ovpn' 'File already exists in destination folder. What would you like to do?' ([System.Management.Automation.Host.ChoiceDescription]::new('&Overwrite','Overwrite the destination file.'), [System.Management.Automation.Host.ChoiceDescription]::new('&Cancel','Cancel the operation and halt the script.'), [System.Management.Automation.Host.ChoiceDescription]::new('&Rename the file','Automatically rename the file by appending a suffix to its name.')) 1
function Get-Choice(
  [string] $title = '',
  [string] $prompt,
  [Collection[ChoiceDescription]] $choices,
  [int] $default = -1
) {
  return $Host.UI.PromptForChoice($title, $prompt, $choices, $default)
}


Export-ModuleMember -Function *
