#Requires -Modules @{ ModuleName="MicrosoftPowerBIMgmt"; ModuleVersion="1.2.1026" }

param(
    [string]$configFilePath = ".\Config.json"
    ,
    [string]$outputPath = ".\output"
    ,
    [bool]$launchBrowsers = $false
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Set-Location $currentPath

Write-Host "Current Path: $currentPath"

Write-Host "Config Path: $configFilePath"

if (Test-Path $configFilePath) {
    $config = Get-Content $configFilePath | ConvertFrom-Json
}
else {
    throw "Cannot find config file '$configFilePath'"
}

# Ensure output folders

Remove-Item $outputPath -Recurse -Force -ErrorAction SilentlyContinue

@($outputPath) |% {
    New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue | Out-Null
}


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

    $loopPages = if($report.loopPages) {1} else {0}

    $pageName = if($report.pageName) {$report.pageName} else {"null"}

    $reportInfo = Get-PowerBIReport -WorkspaceId $report.workspaceId -ReportId $report.reportId
    
    if (!$reportInfo)
    {
        throw "Cannot find report '$($report.reportId)'"
    }

    if ($reportInfo.EmbedUrl.Contains("rdlEmbed"))
    {
        $embedHtmlFilePath = ".\embedPageTemplate.paginated.html"
    }
    else
    {
        $embedHtmlFilePath = ".\embedPageTemplate.html"
    }

    $htmlTemplate = Get-Content $embedHtmlFilePath

    $reportHtml = $htmlTemplate
    
    $reportHtml = $reportHtml.Replace("[ACCESSTOKEN]","$accessToken").Replace("[REPORTID]",$report.reportId).Replace("[WORKSPACEID]",$report.workspaceId)
    $reportHtml = $reportHtml.Replace("[EMBEDURL]",$reportInfo.EmbedUrl);
    $reportHtml = $reportHtml.Replace("[FILTERS_SCRAMBLE]", $filtersScramble.ToString()).Replace("[SLEEP_SECONDS]",$report.sleepSeconds)
    $reportHtml = $reportHtml.Replace("[LOOP_PAGES]",$loopPages).Replace("[PAGE_NAME]",$pageName)
    

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
