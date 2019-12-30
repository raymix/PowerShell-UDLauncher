param (
    [Parameter(Mandatory=$false)][switch]$Wait
)

$scriptRoot = if ($PSScriptRoot) {$PSScriptRoot} else {".\"}
$cfg = Get-Content (Join-Path $scriptRoot config.json) | ConvertFrom-Json
$GlobalVariablesFile = (Join-Path $scriptRoot "GlobalVariables.ps1")
$GlobalFunctionsFile = (Join-Path $scriptRoot "GlobalFunctions.ps1")
$GlobalEndpointsFile = (Join-Path $scriptRoot "GlobalEndpoints.ps1")

if ($null -eq (Get-Module -Name UniversalDashboard* -ListAvailable)) {
    Write-Host "Universal Dashboard module not found, installing" -ForegroundColor Yellow

    try {
        if ($cfg.Settings.Licensed) {
            Install-Module -Name UniversalDashboard -Force
        } else {
            Install-Module -Name UniversalDashboard.Community -Force
        }
    }
    catch {
        if ($cfg.Settings.'Allow CurrentUser Scope') {
            if ($cfg.Settings.Licensed) {
                Install-Module -Name UniversalDashboard -Force -Scope CurrentUser
                Import-Module UniversalDashboard
            } else {
                Install-Module -Name UniversalDashboard.Community -Force -Scope CurrentUser
                Import-Module UniversalDashboard.Community
            }
        } else {
            Write-Host  "ERROR: You need to be an admin to install UD. Alternatively enable 'Allow CurrentUser Scope' in config" -ForegroundColor Red
            exit
        }
    }
}

if ($cfg.Settings.Licensed) {
    $license = Get-UDLicense
    $LicenseLocation = Join-Path $scriptRoot $cfg.Settings.'License Location'

    if ($license.IsTrial) {
        Write-Host "WARNING: Universal Dashboard running in trial mode" -ForegroundColor Yellow
    }
    
    if ($license.Status -eq "Expired") {
        Write-Host "WARNING: Universal Dashboard license expired" -ForegroundColor Yellow
    
        if ((Test-Path $LicenseLocation) -and (Get-Content $LicenseLocation).Length -gt 0) {
            Write-Host "Attempting to install license from $LicenseLocation"
            Set-UDLicense -License (Get-Content $LicenseLocation -Raw)
            $license = Get-UDLicense
        }
    }
    
    if ($cfg.Dashboards.count -gt $license.SeatNumber) {
        Write-Host "WARNING: You have configured $($cfg.Dashboards.count) dashboards, but your license allows $($license.SeatNumber)" -ForegroundColor Yellow
    }
}

. $GlobalVariablesFile
. $GlobalFunctionsFile

$GlobalVariables = @()
$GlobalFunctions = @()

foreach ($line in Get-Content $GlobalVariablesFile) {
    if ($line.Trim().StartsWith("$")) {
        $GlobalVariables += ($line | Select-String -Pattern "(\$.*?)(\s|\=)").Matches.Groups[1].Value
    }
}

foreach ($line in Get-Content $GlobalFunctionsFile) {
    if ($line.Trim().toLower().StartsWith("function ")) {
        $GlobalFunctions += ($line | Select-String -Pattern "(function\s)(.*?)(\s|\{|\})").Matches.Groups[2].Value
    }
}

foreach ($dashboard in $cfg.Dashboards) {
    
    if ($dashboard.Enabled) {

        $ProjectRoot = Join-Path $scriptRoot $dashboard.Name
        $ProjectFooterFile = Join-Path $ProjectRoot "Footer.ps1"
        $ProjectEndpointsFile = Join-Path $ProjectRoot "Endpoints.ps1"
        $ProjectPagesLocation = Join-Path $ProjectRoot $dashboard.'Pages folder'
        $ProjectSourceLocation = Join-Path $ProjectRoot $dashboard.'Source Folder'
        
        $ProjectModules = @()
        $ProjectVariables = $GlobalVariables
        $ProjectFunctions = $GlobalFunctions

        $AutoReloadSources = $dashboard.'Autoreload Sources'
        $AutoReloadPages = $dashboard.'Autoreload Pages'

        $LoginPage = ""

        if (!(Test-Path $ProjectRoot)) {
            New-Item $ProjectRoot -ItemType Directory | Out-Null
        }
        
        if (!(Test-Path $ProjectPagesLocation)) {
            New-Item $ProjectPagesLocation -ItemType Directory | Out-Null
        }

        if (!(Test-Path $ProjectSourceLocation)) {
            New-Item $ProjectSourceLocation -ItemType Directory | Out-Null
        }

        foreach ($p in ($dashboard.'Published folders')) {
            $publishedFolder = Join-Path $ProjectRoot $p.Path
            if (!(Test-Path $publishedFolder)) {
                New-Item $publishedFolder -ItemType Directory | Out-Null
            }
        }

        if ($dashboard.SQLite) {
            
            $SQLiteDBLocation = ""
            $SQLiteDatasource = ""

            if ($dashboard.'SQLite Folder' -notmatch "^\\\\|^\w:\\") {
                $SQLiteDBLocation = Join-Path $ProjectRoot $dashboard.'SQLite Folder'
                $SQLiteDatasource = Join-Path $SQLiteDBLocation ($dashboard.'SQLite Filename')
            } else {
                $SQLiteDBLocation = $dashboard.'SQLite Folder'
                $SQLiteDatasource = Join-Path ($dashboard.'SQLite Folder') ($dashboard.'SQLite Filename')
            }
            
            ### reuse below to install modules from config instead, then import them
            if ($null -eq (Get-Module -Name PSSQLite -ListAvailable)) {
                Write-Host "PSSQLite module not found, installing" -ForegroundColor Yellow
            
                try {
                    Install-Module -Name PSSQLite -Force
                }
                catch {
                    if ($cfg.Settings.'Allow CurrentUser Scope') {
                        Install-Module -Name PSSQLite -Force -Scope CurrentUser
                        Import-Module PSSQLite
                    } else {
                        Write-Host  "ERROR: You need to be an admin to install PSSQLite. Alternatively enable 'Allow CurrentUser Scope' in config" -ForegroundColor Red
                        exit
                    }
                }
            }

            if (!(Test-Path $SQLiteDBLocation)) {
                New-item $SQLiteDBLocation -ItemType Directory -Force | Out-Null
            }

            if (!(Test-Path $SQLiteDatasource)) {
                Import-Module PSSQLite -Force
                Invoke-SqliteQuery -DataSource $SQLiteDatasource -Query "create table a(f1 int); drop table a;"
            }

            $ProjectModules += "PSSQLite"
            $ProjectVariables += "SQLiteDatasource"
        }
        
        $NavBarLinks = @()
        $dashboard."Navigation Bar Links" | ForEach-Object {
            $NavBarLinks += New-UDLink -Text $_.Text -Url $_.URL -Icon $_.Icon -OpenInNewWindow
        }

        if ($dashboard.Footer -and $cfg.Settings.Licensed) {
            if (!(Test-Path $ProjectFooterFile)) {
                New-Item $ProjectFooterFile -ItemType File | Out-Null
                'New-UDFooter -Copyright "' + $dashboard.'Footer Copyright' + '"' | Out-File $ProjectFooterFile
            }
        }

        if (!(Test-Path $ProjectEndpointsFile)) {
            New-Item $ProjectEndpointsFile -ItemType File | Out-Null            
        }
        
        $UDSideNavParams = @{
            Fixed       = $dashboard.Navigation.Fixed
        }

        if ( $null -ne $dashboard.Navigation.Width ) {
            $UDSideNavParams.Add("Width", $dashboard.Navigation.Width) 
        }
        
        
        function enumCFG ($sideNavs) {
            foreach ($nav in $sideNavs) {
                if ($nav.Divider) {
                    New-UDSideNavItem -Divider
                } else {
                    if ($nav.Items) {
                        New-UDSideNavItem -SubHeader -Text $nav.Text -Icon $nav.Icon -Children {
                            enumCFG $nav.Items
                        }
                    } else {
                        $url = if ($nav.'URL or PageName') {$nav.'URL or PageName'} else {$nav.Text}
                        New-UDSideNavItem -Text $nav.Text -Icon $nav.Icon -Url $url
                        
                        if ($url.toLower -notmatch "http" -and $url -ne "") {
                            $page = Join-Path $ProjectPagesLocation "$($nav.Text).ps1"

                            if (!(Test-Path $page)) {
                                $default = $nav.'Default page'
                                $isEndpoint = if ($nav.isEndpoint) {"Endpoint"} else {"Content"}
                                Write-Host "INFO: Setting up new $(if ($default) {"Default "})page at $page" -ForegroundColor Cyan
                                New-Item $page -ItemType File | Out-Null
                                "New-UDPage -Name '$url' $(if ($default) {"-DefaultHomePage"}) -$isEndpoint { New-UDHeading -Color '#FFFFFF' -Text 'Hello! This is $($nav.Text) page' }" | Out-File $page
                            }
                        }
                    }
                }
            }
        }

        $Navigation = New-UDSideNav -Content { (enumCFG $Dashboard.Navigation.Items) } @UDSideNavParams

        $ProjectPages = @()
        $Cache:ProjectPagesHash = @{}
        foreach ($page in (Get-ChildItem $ProjectPagesLocation)) {

            $pageFileHash = Get-FileHash -LiteralPath $page.FullName -Algorithm MD5
            $pageObj = . $page.FullName
            
            $ProjectPages += $pageObj
            
            $Cache:ProjectPagesHash.Add($pageObj.Name,$pageFileHash)

        }

        $Theme = if ($dashboard.Theme -match ".ps1") {
            $ThemePath = Join-Path $scriptRoot "themes\$($dashboard.Theme)"
            if (Test-Path $ThemePath) {
                . $ThemePath
            } else {
                Get-UDTheme -Name "Default"
            }
        } else { 
            Get-UDTheme -Name $dashboard.Theme 
        }
        
        if ((Get-ChildItem $ProjectSourceLocation).count -eq 0) {
            'Write-Output "This is an example function in Sources folder"' | Out-File (Join-Path $ProjectSourceLocation "Test-Example.ps1")
        }

        $Cache:ProjectSourcesHash = @{}
        $ProjectSourceFiles = Get-ChildItem $ProjectSourceLocation
        foreach ($src in $ProjectSourceFiles) {
            New-Function -Name $src.BaseName -scriptBlock (New-Scriptblock -Path $src.FullName)
            $ProjectFunctions += $src.BaseName

            $Cache:ProjectSourcesHash.Add($src.BaseName,(Get-FileHash -LiteralPath $src.FullName -Algorithm MD5).Hash)
        }

        if ($Dashboard.Security.Enabled) {
            $AuthenticationMethodFile = Join-Path $ProjectRoot "AuthenticationMethod.ps1"
            $AuthorizationPolicyFile = Join-Path $ProjectRoot "AuthorizationPolicy.ps1"

            if (!(Test-Path $AuthenticationMethodFile)) {
                New-Item $AuthenticationMethodFile -ItemType File | Out-Null
                'New-UDAuthenticationMethod -Endpoint {New-UDAuthenticationResult -UserName "Demo" -Success}' | Out-File $AuthenticationMethodFile
            }

            if (!(Test-Path $AuthorizationPolicyFile)) {
                New-Item $AuthorizationPolicyFile -ItemType File | Out-Null
                'New-UDAuthorizationPolicy -Name "Demo Policy" -Endpoint { $true }' | Out-File $AuthorizationPolicyFile
            }

            $loginPageParams = @{
                AuthenticationMethod    = (. $AuthenticationMethodFile)
                AuthorizationPolicy     = (. $AuthorizationPolicyFile)
            }
            
            if ($dashboard.Security.Title) {
                $loginPageParams.Add("Title", $dashboard.Security.Title) 
            }

            if ($dashboard.Security.Logo.Change) {
                $loginPageParams.Add("Logo", (New-UDImage -Url $dashboard.Security.Logo.URL -Height $dashboard.Security.Logo.Height -Width $dashboard.Security.Logo.Width )) 
            }

            if ($dashboard.Security.WelcomeText) {
                $loginPageParams.Add("WelcomeText", $dashboard.Security.WelcomeText) 
            }

            if ($dashboard.Security.LoadingText) {
                $loginPageParams.Add("LoadingText", $dashboard.Security.LoadingText) 
            }

            if ($dashboard.Security.LoginFormFontColor) {
                $loginPageParams.Add("LoginFormFontColor", $dashboard.Security.LoginFormFontColor) 
            }

            if ($dashboard.Security.LoginFormBackgroundColor) {
                $loginPageParams.Add("LoginFormBackgroundColor", $dashboard.Security.LoginFormBackgroundColor) 
            }

            if ($dashboard.Security.PageBackgroundColor) {
                $loginPageParams.Add("PageBackgroundColor", $dashboard.Security.PageBackgroundColor) 
            }

            if ($dashboard.Security.LoginButtonFontColor) {
                $loginPageParams.Add("LoginButtonFontColor", $dashboard.Security.LoginButtonFontColor) 
            }

            if ($dashboard.Security.LoginButtonBackgroundColor) {
                $loginPageParams.Add("LoginButtonBackgroundColor", $dashboard.Security.LoginButtonBackgroundColor) 
            }

            $LoginPage = New-UDLoginPage @loginPageParams
        }

        $ProjectVariables   += @("ProjectRoot","ProjectFooterFile","ProjectPages","ProjectPagesLocation","ProjectSourceLocation","ProjectSourceFiles","AutoReloadSources","AutoReloadPages","Cache:ProjectSourcesHash","Cache:ProjectPagesHash")
        $ProjectFunctions   += @()
        $ProjectModules     += $dashboard.'Import PS Modules'

        $NewDBParams = @{
            Title       = $dashboard.Title
            NavbarLinks = $NavBarLinks
            Navigation  = $Navigation
            Pages       = $ProjectPages
            Theme       = $Theme
            EndpointInitialization = New-UDEndpointInitialization -Variable $ProjectVariables -Function $ProjectFunctions -Module $ProjectModules
        }

        if ($cfg.Settings.Licensed) {
            $NewDBParams.Add("Footer", (. $ProjectFooterFile)) 
        }

        if ($Dashboard.Security.Enabled) {
            $NewDBParams.Add("LoginPage", $LoginPage)
        }

        $ProjectPublishedFolders = ($dashboard.'Published folders') | ForEach-Object {
            Publish-UDFolder -Path $(Join-Path $ProjectRoot $_.Path) -RequestPath "/$($_.RequestPath)"
        }

        $StartDBParams = @{
            Port            = $dashboard.Port
            Name            = $dashboard.Name
            PublishedFolder = $ProjectPublishedFolders
            Endpoint        = @($GlobalEndpointsFile, $ProjectEndpointsFile) | ForEach-Object {. $_}
        }

        if ($dashboard.Force ) {
            $StartDBParams.Add("Force", $true) 
        }

        if ($dashboard.'Admin mode') {
            if ($cfg.Settings.Licensed) {
                $StartDBParams.Add("AdminMode", $true) 
            } else {
                Write-Host "WARNING: Admin mode does not work with Community edition" -ForegroundColor Yellow
            }
            
        }

        if ($dashboard.'Autoreload dashboard' ) {
            $StartDBParams.Add("Autoreload", $true)
        }

        if ($dashboard.'Update Token') {
            $StartDBParams.Add("UpdateToken ", $dashboard.'Update Token')
        }

        if ($Dashboard.Security.Enabled) {
            $StartDBParams.Add("AllowHttpForLogin", $Dashboard.Security.'Allow HTTP')
        }

        if ($Wait) {
            $StartDBParams.Add("Wait", $true)
        }

        Start-UDDashboard -Dashboard (New-UDDashboard @NewDBParams) @StartDBParams
    }
}