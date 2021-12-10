#Requires -Modules @{ ModuleName="MicrosoftPowerBIMgmt"; ModuleVersion="1.2.1026" }

param(
    [string]$configFilePath = ".\Config.json"
    ,
    [string]$outputPath = ".\output"
    ,
    [string]$embedHtmlFilePath = ".\embedPageTemplate.html"
    ,
    [bool]$launchBrowsers = $true
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Write-Host "Current Path: $currentPath"

Write-Host "Config Path: $configFilePath"

if (Test-Path $configFilePath) {
    $config = Get-Content $configFilePath | ConvertFrom-Json
}
else {
    throw "Cannot find config file '$configFilePath'"
}

# Ensure output folders

@($outputPath) |% {
    New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue | Out-Null
}

$htmlTemplate = Get-Content $embedHtmlFilePath

try {
    $accessToken = Get-PowerBIAccessToken -AsString
}
catch {
    Connect-PowerBIServiceAccount
    $accessToken = Get-PowerBIAccessToken -AsString 
}

$accessToken = $accessToken.Replace("Bearer ","").Trim()

Write-Host "Preparing HTML files on '$outputPath'"

foreach($report in $config.Reports)
{
    $filtersScramble = if($report.filtersScramble) {1} else {0}

    $reportHtml = $htmlTemplate.Replace("[ACCESSTOKEN]","$accessToken").Replace("[REPORTID]",$report.reportId).Replace("[WORKSPACEID]",$report.workspaceId).Replace("[FILTERS_SCRAMBLE]", $filtersScramble.ToString()).Replace("[SLEEP_SECONDS]",$report.sleepSeconds)

    $reportHtml | Out-File "$outputPath\$($report.reportId).html"

}

if ($launchBrowsers)
{
    Write-Host "Launching browser windows"

    foreach($report in $config.Reports)
    {
        $reportHtmlFilePath = Resolve-Path "$outputPath\$($report.reportId).html"

        if (!(Test-Path $reportHtmlFilePath))
        {
            throw "Cannot find HTML file on path: '$reportHtmlFilePath'"
        }

        (1..$report.instances) |% {

            Start-Process chrome "--incognito --disable-default-apps --new-window ""$($reportHtmlFilePath)"""    

        }

    }

    Write-Host "Press enter when load test is complete (IT WILL CLOSE ALL CHROME WINDOWS)"

    Read-Host

    Write-Host "Closing all chrome windows"

    Get-Process |? {$_.Name -eq "Chrome" -and  $_.SI -eq (Get-Process -PID $PID).SessionId} | Stop-Process

}