# https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3
# TODO find out how to make props optional when using pipe, for example
#   @('x','y')|get-index -INDEX 1   ===   @('x','y')|get-index 1
#   get-process|get-prop -PROP 'id'   ===   get-process|get-prop 'id'
using namespace System.Management.Automation.Host
using namespace System.Collections.ObjectModel

Import-Module -Scope Local $PSScriptRoot\pwsh__String\String.psm1



function Get-Prop([Parameter(ValueFromPipeline)] $Obj, [string] $Prop) {
  return $Obj.$Prop
}

function Get-FirstApplication([Parameter(ValueFromPipeline)][string] $Name, [switch] $AsPath) {
  # TODO move to more specific module?
  # TODO check out: https://learn.microsoft.com/en-us/windows/win32/shell/app-registration (example: brave)
  # TODO rename to Find-Application
  $where = ((& where.exe $name 2>$null) -split "`n")[0]
  if ($where) {
    $gcm = Get-Command -Name $name -CommandType ([System.Management.Automation.CommandTypes]::Application) -ea silentlycontinue
    $wherepath = ($where | Resolve-Path).Path
    $gcmpath = ($gcm.Path | Resolve-Path).Path
    if ($gcmpath -ne $wherepath ) {
      throw @"
Get-Command and where.exe paths should be equal, but they aren't:
  $wherepath
<>
  $gcmpath
"@
    }
    if (!$AsPath) { return $gcm }
    else { return ($wherepath | Get-QuotedString) }
  }
  return $null
}


function Get-Index([Parameter(ValueFromPipeline)][array] $arr, [int] $index) {
  if (!!$input) {
    return , $input[$index]
  } else {
    return , $arr[$index]
  }
}


function Get-ReducedArray(
  [Parameter(ValueFromPipeline)] $Arr,
  [scriptblock] $BeginScriptBlock = {},
  [scriptblock] $ProcessScriptBlock,
  [scriptblock] $EndScriptBlock = {}
) {
  # TODO check
  & $BeginScriptBlock
  $Arr | ForEach-Object -Process $ProcessScriptBlock
  return , (& $EndScriptBlock)
}

function Import-PsProfile([switch] $Verbose, [switch] $Force) {
  $Verbose = $Verbose -or $PSBoundParameters['Verbose']
  . $PROFILE -Verbose:$Verbose -Force:$Force
}

$script:__InitialPowershell_Prompt = $function:Prompt
function Set-PsPrompt($prompt = $null, [switch]$restore) {
  throw 'not implemented'
  # TODO
  # https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.scriptblock.invokewithcontext?view=powershellsdk-7.0.0
  # https://www.google.com/search?q=powershell+create+closure&oq=powershell+create+closure&aqs=chrome..69i57.3146j0j1&sourceid=chrome&ie=UTF-8

  # if ($restore) { $script:__InitialPowershell_Prompt.Invoke() ; return }
  if ($restore) { function global:Prompt { & $script:__InitialPowershell_Prompt } ; return }

  if ($prompt -is [string]) {
    # Invoke-Expression ("function global:prompt { '$prompt' }") -Verbose
    function global:Prompt { '???' }
  } else {
    'blk'
    function global:Prompt { '???' ; try { & $prompt.GetNewClosure() }catch {} }
  }
}

function Test-AmIAdministrator () {
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-AmIMemberOfAdministratorsGroup {
  # taken from https://gerardog.github.io/gsudo/docs/tips/script-self-elevation
  ([System.Security.Principal.WindowsIdentity]::GetCurrent()).Claims.Value -contains 'S-1-5-32-544'
}


function Test-PendingReboot {
  # check out:
  #     https://adamtheautomator.com/pending-reboot-registry/
  #     https://github.com/adbertram/Random-PowerShell-Work/blob/master/Random%20Stuff/Test-PendingReboot.ps1
  #     wait for:
  #
  #     https://stackoverflow.com/a/43596428/9156059
  #     https://gist.github.com/altrive/5329377
  #     https://web.archive.org/web/20190503035319/https://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542
  if (Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -EA Ignore) { return $true }
  if (Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -EA Ignore) { return $true }
  if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -EA Ignore) { return $true }
  try {
    # TODO test $util = Invoke-Command -ScriptBlock { $ErrorActionPreference = 'ignore'; return ([wmiclass]'\.\root\ccm\clientsdk:CCM_ClientUtilities') } -ea Ignore
    $util = [wmiclass]'\.\root\ccm\clientsdk:CCM_ClientUtilities'
    $status = $util.DetermineIfRebootPending()
    if (($null -ne $status) -and $status.RebootPending) {
      return $true
    }
  } catch {}
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
  [Parameter(HelpMessage = 'use & to make each option selectable by 1 single character. if & is not used, the user has to type the entire string to select that option')]
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

function New-Constant {
  [CmdletBinding(DefaultParameterSetName = 'anything')]
  Param(
    [Parameter(ParameterSetName = 'var', Position = 0)][string] $LiteralName,
    [Parameter(ParameterSetName = 'objprop', Position = 0)][string] $ObjectProperty,
    [Parameter(ParameterSetName = 'anything', Position = 0)][string] $Name,
    $Value,
    [switch] $ThrowOnAlreadyExisting
  )

  if (('' -ne $LiteralName) -or !($Name -match '.*\..*')) {
    # actual variable
    if ('' -ne $LiteralName) { $nm = $LiteralName } else { $nm = $Name }
    $alreadyExists = (Get-Variable -Name $nm -Scope global -ea Ignore | Select-Object Options).Options -contains [System.Management.Automation.ScopedItemOptions]::Constant
    if ($alreadyExists) {
      if ($ThrowOnAlreadyExisting) { throw "cannot overwrite constant: $nm" }
      # else, do nothing
    } else {
      return (Set-Variable -Option Constant -Scope global -Force -Name $nm -Value $Value)
    }
  } elseif (('' -ne $ObjectProperty) -or ($Name -match '.*\..*')) {
    # object property; object must already exist
    if ('' -ne $ObjectProperty) { $nm = $ObjectProperty } else { $nm = $Name }
    $varAndPath = $nm -split '\.'
    $var = Get-Variable -Name $varAndPath[0] -ValueOnly
    $path = (Get-ArraySlice -Array $varAndPath -Offset 1) -join '.'
    return (Set-ObjectPropertyByPath -Obj $var -KeyPath $path -Value $Value -Immutable)
  } else {
    throw 'wth is this thing'
  }
}

# NOT USING ValueFromPipeline because powershell unwraps arrays and pipes elements 1
#   by 1 into the function, as expected when piping, unless using the comma trick. so,
#       (,$myArray) | get-arrayslice -offset 1
#   is equivalent to
#       get-arrayslice -array $myArray -offset 1
#   this makes the user extremely prone to committing mistakes, since this function is to be
#   used on whole arrays. So no ValueFromPipeline just to be sure.
function Get-ArraySlice(
  [array] $Array,
  [int] $Offset,
  [AllowNull()][Nullable[System.Int32]] $Length = $null
) {
  if ($Offset -notin 0..$Array.Length) {
    throw "invalid offset $Offset"
  }
  $result = @()
  :loop for ($i = $Offset; $i -lt $Array.Length; $i++) {
    $val = $Array[$i]
    if (($null -eq $Length) -or ($i -lt ($Offset + $Length))) {
      $result += $val
    } else {
      break loop
    }
  }
  return $result
}

function get_last_object_by_path([object] $Obj, [string] $KeyPath) {
  $keys = $KeyPath -split '\.'
  $currentObj = $Obj
  $currentPath = '[Obj]'
  for ($i = 0; $i -lt ($keys.Length - 1) ; $i++) {
    $k = $keys[$i]
    $currentPath += ".$k"
    $checkGetMember = Get-Member -InputObject $currentObj -MemberType Properties -View All -Name $k -ea Ignore
    $checkSelectObject = Select-Object -InputObject $currentObj -ExpandProperty $k -ea Ignore
    $checkNull = $null -ne $currentObj.$k
    if (!$checkGetMember -and !$checkSelectObject -and !$checkNull) {
      throw "property not found: $currentPath"
    }
    $currentObj = $currentObj.$k
  }
  return $currentObj
}

function Get-ObjectPropertyByPath([object] $Obj, [string] $KeyPath) {
  # TODO test
  $keys = $KeyPath -split '\.'
  $lastObj = get_last_object_by_path $Obj $KeyPath
  $name = $keys[$keys.Length - 1]
  return $lastObj.$name
}

function Set-ObjectProperty([object] $Obj, [string] $Name, $Value, [switch] $Immutable) {
  if ($Immutable) {
    $memberType = [System.Management.Automation.PSMemberTypes]::ScriptProperty
    $val = { return $Value }.GetNewClosure()
  } else {
    $memberType = [System.Management.Automation.PSMemberTypes]::NoteProperty
    $val = $Value
  }

  return (Add-Member -InputObject $Obj -Force -MemberType $memberType -Name $Name -Value $val)
}


function Set-ObjectPropertyByPath([object] $Obj, [string] $KeyPath, $Value, [switch] $Immutable) {
  $keys = $KeyPath -split '\.'
  $lastObj = get_last_object_by_path $Obj $KeyPath
  $name = $keys[$keys.Length - 1]
  return (Set-ObjectProperty -Obj $lastObj -Name $name -value $Value -Immutable:$Immutable)
}


. "$PSScriptRoot/globals.ps1"

Export-ModuleMember -Function *
