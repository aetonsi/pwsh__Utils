# windows powershell shims
if ('Desktop' -ieq $PSVersionTable.PSEdition) {
    New-Constant 'IsWindows' -Value ('Win32NT' -eq [System.Environment]::OSVersion.Platform)
    New-Constant 'IsLinux' -Value ('Unix' -eq [System.Environment]::OSVersion.Platform)
    New-Constant 'IsMacOS' -Value ('MacOSX' -eq [System.Environment]::OSVersion.Platform)
    switch ($true) {
        $IsWindows { New-Constant 'PSVersionTable.OS' -Value "$((& cmd /c ver) -replace '\[Version ', '' -replace '\]', '')".Trim() }
        $IsLinux { New-Constant 'PSVersionTable.OS' -Value "$(& uname -srv)".Trim() }
        $IsMacOS { New-Constant 'PSVersionTable.OS' -Value '???' } # TODO https://www.cyberciti.biz/faq/mac-osx-find-tell-operating-system-version-from-bash-prompt/
        default { throw 'wth is it' }
    }
}

# my constants
New-Constant 'IS_WINDOWSPOWERSHELL' -Value ($PSVersionTable.PSEdition -ieq 'Desktop')
New-Constant 'IS_PWSH' -Value ($PSVersionTable.PSEdition -ieq 'Core')

New-Constant 'CHAR_ESCAPE' -Value $([char]27) # [char]27 is for powershell 5, "`e" doesn't work
New-Constant 'CHAR_BELL' -Value "`a"

New-Constant 'CHAR_NEWLINE' -Value "`n"
New-Constant 'STR_ENVIRONMENT_NEWLINE' -Value ([System.Environment]::NewLine)

# https://conemu.github.io/en/AnsiEscapeCodes.html#OSC_Operating_system_commands
New-Constant 'STR_CONEMU_STRINGTERMINATOR' -Value "${CHAR_ESCAPE}\"
# New-Constant 'STR_CONEMU_STRINGTERMINATOR' -Value $CHAR_BELL # alternative
New-Constant 'STR_CONEMU_ST' -Value $STR_CONEMU_STRINGTERMINATOR