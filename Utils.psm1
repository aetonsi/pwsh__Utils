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


# TODO #conf1: implement OPTIONAL ref parameter $choiceMade
# TODO #conf1 NEW usage example: $confirmation = confirm 'Overwrite destination file: profile.ovpn' 'File already exists in destination folder. It will be overwritten. Do you want to continue?' ([System.Management.Automation.Host.ChoiceDescription]::new('&Yes','Overwrite the file.'), [System.Management.Automation.Host.ChoiceDescription]::new('&No','Cancel the operation and halt the script.'), [System.Management.Automation.Host.ChoiceDescription]::new('See &more options','See additional options (renaming the file, moving it, etc)'))
# usage example: $confirmation = confirm 'Overwrite destination file: profile.ovpn' 'File already exists in destination folder. It will be overwritten. Do you want to continue?' ([System.Management.Automation.Host.ChoiceDescription]::new('&Yes','Overwrite the file.'), [System.Management.Automation.Host.ChoiceDescription]::new('&No','Cancel the operation and halt the script.'))
function confirm(
  [string] $title = '',
  [string] $prompt,
  [Collection[ChoiceDescription]] $choices = ('&Yes', '&No'),
  [int] $default = -1
  # [ref][Parameter(Mandatory = $false)][AllowNull()][int] $choiceMade = $null) # TODO #conf1
) {
  $decision = $Host.UI.PromptForChoice($title, $prompt, $choices, $default)
  # if ($choiceMade -is [ref]) { $choiceMade.value = $decision } # TODO #conf1
  return $decision -eq 0
}


Export-ModuleMember -Function *
