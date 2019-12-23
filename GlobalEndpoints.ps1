### Global Endpoints are initialized for all dashboards being launched. Add your schedules or API endpoints here.

if ($AutoReloadSources.Enabled) {
    $params = @{
        Every = $AutoReloadSources.Interval[0]
        $AutoReloadSources.Interval[1] = $true
    }

    $AutoReloadSourcesSchedule = New-UDEndpointSchedule @params
    New-UDEndpoint -Schedule $AutoReloadSourcesSchedule -Endpoint {
        $ProjectSourceFiles = Get-ChildItem $ProjectSourceLocation
        
        foreach ($sourceFile in $ProjectSourceFiles) {
            $sourceFileHash = Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm MD5
            if ($sourceFile.FullName -notin $Cache:ProjectSourcesHash.Keys) {
                $Cache:ProjectSourcesHash.Add($sourceFile.BaseName,$sourceFileHash.Hash)
            }

            if ($sourceFileHash.Hash -notin $Cache:ProjectSourcesHash.Values) {   
                New-Function -Name $sourceFile.BaseName -scriptBlock (New-Scriptblock -Path $sourceFile.FullName)
                $Cache:ProjectSourcesHash.($sourceFile.BaseName) = $sourceFileHash.Hash
            }
        }
    }
}

if ($AutoReloadPages.Enabled) {
    $params = @{
        Every = $AutoReloadPages.Interval[0]
        $AutoReloadPages.Interval[1] = $true
    }

    $AutoReloadPagesSchedule = New-UDEndpointSchedule @params

    New-UDEndpoint -Schedule $AutoReloadPagesSchedule -Endpoint {
        foreach ($key in $Cache:ProjectPagesHash.Keys) {
            $pageFileHash = Get-FileHash -LiteralPath $Cache:ProjectPagesHash.$key.Path -Algorithm MD5

            if ($pageFileHash.Hash -ne $Cache:ProjectPagesHash.$key.Hash) {

                $Private:tmpPageObj = . $Cache:ProjectPagesHash.$key.Path
                $livePageObj = $ProjectPages | Where-Object {$_.name -eq $key}

                $livePageObj.Callback.ScriptBlock =  $Private:tmpPageObj.Callback.ScriptBlock

                $Private:tmpPageObj = $null
                $Cache:ProjectPagesHash.$key.Hash = $pageFileHash.Hash

                Invoke-UDRedirect -Url "/$key"     # Refresh/Redirect to changed page, doesn't work
            }
        }
    }
}
