# PowerShell-UDLauncher
Generates a Universal Dashboard scaffolded project based on a JSON file 

# What is this?
UDLauncher uses JSON file to configure your dashboard(s), it will create all necesarry files and folders to create a baseline skeleton for your dashboard project, think of it as a boilerplate template (?) for PowerShell Universal Dashboards. There is no limit to amount of dashboard projects you can generate from a single config file.

# Why?
When I realised that Universal Dashboards can be used to create any type of web pages, not just dashboards, I quickly got my company to purchase a license so I can play around with it. The problem from the very begining was that I did not know where to even begin. I was not able to experiment much until after I've read couple of key pages in official documentation. But where do I go from there? What's the best way to set up development environment? What if I need to dramatically change subheader and page structure, do I risk messing something up?

Then I found  [UDTemplate](https://github.com/ArtisanByteCrafter/ud-template "UDTemplate") project by [ArtisanByteCrafter](https://github.com/ArtisanByteCrafter "ArtisanByteCrafter"). This module generates a basic skeleton project with a JSON file for configuration. I thought JSON config file was a great idea, so that's what my project is based off. However, instead of generating a JSON file using commands, a JSON file is used to generate the dashboard(s).

# How does it work?
Edit the config.json file to set up your dashboard(s) and run Launch.ps1

# Features
- **Autoreload modified pages** - Script runs an endpoint that will detect changes in page files and update them live (currently requires user to reload browser page, though). Duo to nature of UD, autoreloading pages might require to be configured with `isEndpoint = true`(probably won't work if page is set as Content instead)
- **Autoreload modified functions** - Script runs an endpoint that will detect changes in functions files in your sources folder and update them live.
- **Fully JSON based sidenavigation design**- add subheaders or dividers to nicely categorize your pages, there should be no limit on how deep you can go with subheaders.
- Project can be configured to run in CurrentUser scope
- Ability to disable any dashboard (not launch them) without deleting or modifying project files (e.g. historical reasons)
- Enable or Disable Admin mode individually for each dashboard
- Creates Pages folder and generates .PS1 files for each configured page with a template code in them
- Creates Sources folder,  generates an example .PS1 function file that you can call from within running project
- Creates Published folders (used for images, logos, downloads, assets etc)
- If license enabled, allows modifying Footer copyright message
- If enabled, imports PSSQLite module. If local or UNC location for database not set, it will create SQL folder within project and generate a blank SQLite database if .SQLite file not found
- Allows importing all your favorite PowerShell modules from within config
- Allows enabling Login page and generate templates for Authentication methods and Authorization policies
- Add navigation bar links (top right corner of your dashboard, e.g. links to external websites)
- Supports built-in or custom themes, branded example template included. If using custom theme, put your file in Themes folder and update JSON with filename.ps1. To use built-in themes, just add their name (or use "Default") in JSON entry
- Included .gitignore file excludes .SQLite files, handy if you intend to use GIT

# Issues
- Invoke-UDRedirect cannot be used to reload page where changes were detected, need a workaround. Suggestions?

# Publishing
(not tested) If you're using Publish-UDDashboard specify target directory initially to export ASP core files, you will need to rename Launcher.ps1 to Dashboard.ps1. You'll need to copy rest of the files and folders over to the target directory manually. See administrative event log if service is not starting

(not tested) If you're using IIS, same rules apply - rename Launch.ps1 to Dashboard.ps1 and copy over rest of the files and directories

You can also set up NSSM to run dashboard as a service:
Download and unzip binary .exe file from https://nssm.cc/download and save it on your server.
Log on as admin and run below command to create service (adjust paths accordingly):

```
& C:\NSSM\nssm.exe install "UDLauncher" "C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe" '-ExecutionPolicy Bypass -NoProfile -File "C:/UniversalDashboard/Launch.ps1" -Wait'
```

# Example screenshots
**Before running launcher, clean slate:**

![](https://i.imgur.com/ZPNtHWQ.png)

**Example page configuration:**

![](https://i.imgur.com/c08sV0E.png)

**Console output after configuring "example" project in JSON and running launcher:**

![](https://i.imgur.com/gK4yhA1.png)

**Scaffolded project for "example" dashboard:**

![](https://i.imgur.com/J88HQsK.png)

**Autogenerated project files and folders (naming scheme is based off JSON):**

![](https://i.imgur.com/HsBdiDv.png)

**Example pages that were generated:**

![](https://i.imgur.com/Pvlv3fl.png)

**Example branded dashboard that was generated using "example" config:**

![](https://i.imgur.com/Cfvi2jJ.png)

**Example side navigation bar for branded dashboard:**

![](https://i.imgur.com/k4Yl4w5.png)

# JSON Documentation
        "Settings": {
            "Allow CurrentUser Scope": false,
            "Licensed": true,
            "License Location": "license.lic"
        }
These are main settings that affect ALL dashboards. 
`Allow CurrentUser Scope` should dashboard run on user context? (e.g. non-admin user)

`Licensed` is your dashboard licensed? Choice here will determine which version of UD to insall and it also affects whether or not footer will be updated

`License Location` location of license in root of your project (not dashboard)

    "Dashboards": [
            {
                "Enabled":true,
                "Name": "Example",
                "Title": "Example Dashboard",
                "Port":  "10000",
                "Force": true,
                "Admin mode": true,
                "Theme":"Branded.ps1",
                "Update Token":null,

`Dashboards` this is what defines a dashboard. To create another dashboard, simply copy example dashboard JSON object and adjust settings accordingly.

**All settings below are dashboard independent (unique for each dashboard)**

`Enabled` - allows enabling or disabling dashboard without modifying files (not launched)

`Name` Name of your dashboard (also folder name)

`Title` Title of your dashboard

`Port` port number for your dashboard (e.g. http://localhost:10000/)

`Force` if enabled, this will stop and replace any existing running dashboards when script is run. If disabled, script will stop with error message.

`Admin mode` enables admin mode (if licensed product).

`Theme` choose a built-in or custom theme. Custom themes are saved in "themes" folder within root directory of project and need to be defined with p.s1 extension. To view built-in themes use `Get-UDTheme` cmdlet

`Update Token` - used as a "password" for REST APIs that allow updating dashboard. Not sure if should be used with this scaffolding project, but I included it anyway

    			"Pages folder":"Pages",
                "Source folder":"Src",
                "Published folders": [
                    {
                        "Path":"Assets",
                        "RequestPath":"assets"
                    },
                    {
                        "Path": "Logos",
                        "RequestPath": "logos"
                    }
                ],

This part defines naming scheme for your dashboard's scaffolded folders.

`Pages folder` name of the folder that will hold all your dashboard's pages

`Source folder` name of the folder that will hold all your dashboard's functions

`Published folder` name of the folder that will hold all your dashboard's assets

`Path` Foldername for one of assets folder you want to publish

`RequestPath` Request path that will be mapped to URL when requesting an asset (e.g. http://localhost:10000/myRequestPath/mylogo.png)


                "Autoreload dasboard":  true,
                "Autoreload Sources": [
                    {
                        "Enabled": true,
                        "Interval": ["5","Second"]
                    }
                ],
                "Autoreload Pages": [
                    {
                        "Enabled": true,
                        "Interval": ["5","Second"]
                    }
                ],

`Autoreload dasboard` reloads dashboard when changes are detected within Launcher.ps1, quite irrelevant, but I have included it anyway

`Autoreload Sources` If enabled, a special endpoint (Defined in GlobalEndpoints.ps1 file) will monitor changes in your function files and reload them live if changes are detected

`Autoreload Pages` if enabled, a special endpoint (Defined in GlobalEndpoints.ps1 file) will monitor changes in your pages files and reload the live if changes are detected. Unfortunately, user still requires to refresh the page in browser (anyone got workaround? Chrome autoreload extension perhaps?)

`"Interval": ["5","Second"]` Set interval on how often to check for changes. See [New-UDEndpointSchedule](https://github.com/ironmansoftware/universal-dashboard-documentation/blob/master/api/New-UDEndpointSchedule.md "New-UDEndpointSchedule") for settings

                "Footer":true,
                "Footer Copyright":"My Company Ltd.",

This is a configuration part for footer branding

                "SQLite": true,
                "SQLite Folder":"SQL",
                "SQLite Filename":"Example.SQLite",

`SQLite` Enable SQLite support. This will install PSSQLite module and create blank .SQLite datasource. Great if $Cache is not cutting it for you anymore and you need to save data locally that is faster than working with plain text files

`SQLite Folder` Folder where SQLite database resides (or will be crated). Can be local path (C:\SQL\) or UNC (\\fileserver\SQL\). If you simply define a name, e.g. SQLFolder, the script will instead look into your dashboard's root instead (i.e. Projectroot\DashboardRoot\SQLFolder)

`SQLite Filename` Name of your SQL datasource (e.g. mydatabase.sqlite)

                "Import PS Modules": ["myModule1","myModule2"],

`Import PS Modules` Import your favorite PowerShell modules by name here.

                "`Navigation`": [
                    {
                    "Fixed": false,
                    "Width": null,
                    "Hide": true,

`Navigation` this section creates all your side navigation

`Fixed` if enabled, side nav bar is always open (less space for dashboards tho)

`Width` defines width of your sidenav in pixels

`Hide` hide side nav bar and the burger button (single page dashboard)

                    "Items": [
                        {
                            "Icon":"home",
                            "Text":"Home",
                            "URL or PageName":"Home",
                            "Default page": true,
                            "isEndpoint": true
                        },
                        {
                            "Divider":true
                        },
                        {
                            "Icon":"dashboard",
                            "Text":"Sub 1",
                            "Items":[
                                {
                                    "Icon":"dashboard",
                                    "Text":"sub 1 sub 1 sub 1 page 1",
                                    "URL or PageName":"s1s1s1_page1",
                                    "isEndpoint": true
                                }

`Items` this is where you define all your subheaders (folders/sections for your pages), dividers and pages. This part is what also creates all the pages for you and maps them to sidebar

`Icon` You can find all internal icons by using command `New-UDIcon -Icon  ` and then tabbing through options. Yeah I know, this sucks, but you could create a dashboard page that lists all available icons and their names ;)

`Text` name of your page or subheader

`URL or PageName` Can be URL (e.g. https://google.com) or Pagename (will generate pageName.ps1 file) that will later be mapped to a subheader holding it (if any)

`Default page` sets up page as a default "home page" - first page you are redirected to when opening dashboard

`isEndpoint` if page does not exist yet, script will create a template page. If this setting is true, it will define page as "endpoint", if false, it will set it up as "content". Endpoints are loaded only when user visits and content pages are loaded when dashboard is launched. Page has to be endpoint if you want autoreload feature to work (probably, haven't tested with content yet tbh)

`Divider` if set, it will ignore any other settings here and create divider side nav object

`Items` If you add items[], the item will automatically become a subheader (a section) that holds pages. It cannot be a page itself, so, just like with divider, there is no point adding extra page settings.

                "Navigation Bar Links": [
                    {
                        "Text": "UD Forums",
                        "URL": "https://forums.universaldashboard.io/",
                        "Icon": "home"
                    }

`Navigation Bar Links` sets up nav bar links on top-right corner of the page. When clicked, internal or external pages will be opened in a new browser tab

`Text` Name for the navbar

`URL` URL for the navbar

`Icon` Icon for the navbar
