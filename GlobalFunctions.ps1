### Globally defined functions are called from here and will be imported into all launched dashboards.
function New-Scriptblock {
    param (
        [Parameter(Mandatory=$false)][string]$String = "",
        [Parameter(Mandatory=$false)][string]$Path = ""
    )
    
    $code = if ($String -ne "") {
        $String
    } elseif (Test-Path $Path) {
        (Get-Content -Path $Path -Raw)
    } else {""}
    
    $scriptBlock = [scriptblock]::Create($code)
    
    return $scriptBlock
}

function New-Function {
    param (
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$scriptBlock
    )

    if ($Name -notmatch "\s") {
        Set-Item -Path "function:global:$Name" -Value $scriptBlock
    } else {
        Write-Host "ERROR: function names cannot contain spaces" -ForegroundColor Red
    }
}