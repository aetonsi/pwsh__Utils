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

Export-ModuleMember -Function *
