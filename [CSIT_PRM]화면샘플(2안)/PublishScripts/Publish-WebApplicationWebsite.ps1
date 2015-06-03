#Requires -Version 3.0

<#
.SYNOPSIS
Visual Studio 웹 프로젝트의 Microsoft Azure 웹 사이트를 만들고 배포하세요.
자세한 설명서를 보려면 http://go.microsoft.com/fwlink/?LinkID=394471로 이동하십시오. 

.EXAMPLE
PS C:\> .\Publish-WebApplicationWebSite.ps1 `
-Configuration .\Configurations\WebApplication1-WAWS-dev.json `
-WebDeployPackage ..\WebApplication1\WebApplication1.zip `
-Verbose

#>
[CmdletBinding(HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=391696')]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $Configuration,

    [Parameter(Mandatory = $false)]
    [String]
    $SubscriptionName,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $WebDeployPackage,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ !($_ | Where-Object { !$_.Contains('Name') -or !$_.Contains('Password')}) })]
    [Hashtable[]]
    $DatabaseServerPassword,

    [Parameter(Mandatory = $false)]
    [Switch]
    $SendHostMessagesToOutput = $false
)


function New-WebDeployPackage
{
    #웹 응용 프로그램을 빌드하고 패키지하는 함수를 쓰십시오.

    #웹 응용 프로그램을 빌드하려면 MsBuild.exe를 사용하십시오. 도움말은 MSBuild Command-Line Reference(http://go.microsoft.com/fwlink/?LinkId=391339)를 참조하십시오.
}

function Test-WebApplication
{
    #이 함수를 편집하여 웹 응용 프로그램에서 단위 테스트를 실행하십시오.

    #함수를 웹 응용 프로그램에서 단위 테스트를 실행하도록 쓰려면 VSTest.Console.exe를 사용하십시오. 도움말은 VSTest.Console Command-Line Reference(http://go.microsoft.com/fwlink/?LinkId=391340)를 참조하십시오.
}

function New-AzureWebApplicationWebsiteEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Configuration,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword
    )
       
    Add-AzureWebsite -Name $Config.name -Location $Config.location | Out-String | Write-HostWithTime
    # SQL 데이터베이스를 만드십시오. 연결 문자열이 배포에 사용됩니다.
    $connectionString = New-Object -TypeName Hashtable
    
    if ($Config.Contains('databases'))
    {
        @($Config.databases) |
            Where-Object {$_.connectionStringName -ne ''} |
            Add-AzureSQLDatabases -DatabaseServerPassword $DatabaseServerPassword -CreateDatabase |
            ForEach-Object { $connectionString.Add($_.Name, $_.ConnectionString) }           
    }
    
    return @{ConnectionString = $connectionString}   
}

function Publish-AzureWebApplicationToWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Configuration,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage
    )

    if ($ConnectionString -and $ConnectionString.Count -gt 0)
    {
        Publish-AzureWebsiteProject `
            -Name $Config.name `
            -Package $WebDeployPackage `
            -ConnectionString $ConnectionString
    }
    else
    {
        Publish-AzureWebsiteProject `
            -Name $Config.name `
            -Package $WebDeployPackage
    }
}


# 스크립트 주요 루틴
Set-StrictMode -Version 3

Remove-Module AzureWebSitePublishModule -ErrorAction SilentlyContinue
$scriptDirectory = Split-Path -Parent $PSCmdlet.MyInvocation.MyCommand.Definition
Import-Module ($scriptDirectory + '\AzureWebSitePublishModule.psm1') -Scope Local -Verbose:$false

New-Variable -Name VMWebDeployWaitTime -Value 30 -Option Constant -Scope Script 
New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
New-Variable -Name SendHostMessagesToOutput -Value $SendHostMessagesToOutput -Scope Global -Force

try
{
    $originalErrorActionPreference = $Global:ErrorActionPreference
    $originalVerbosePreference = $Global:VerbosePreference
    
    if ($PSBoundParameters['Verbose'])
    {
        $Global:VerbosePreference = 'Continue'
    }
    
    $scriptName = $MyInvocation.MyCommand.Name + ':'
    
    Write-VerboseWithTime ($scriptName + ' 시작')
    
    $Global:ErrorActionPreference = 'Stop'
    Write-VerboseWithTime ('{0} $ErrorActionPreference가 {1}(으)로 설정됩니다.' -f $scriptName, $ErrorActionPreference)
    
    Write-Debug ('{0}: $PSCmdlet.ParameterSetName = {1}' -f $scriptName, $PSCmdlet.ParameterSetName)

    # 현재 구독을 저장하십시오. 스크립트 뒷부분에 Current 상태로 복원됩니다.
    Backup-Subscription -UserSpecifiedSubscription $SubscriptionName
    
    # Azure 모듈이 버전 0.7.4 이상인지 확인합니다.
    if (-not (Test-AzureModule))
    {
         throw 'Microsoft Azure PowerShell 버전이 오래되었습니다. 최신 버전을 설치하려면 http://go.microsoft.com/fwlink/?LinkID=320552로 이동하십시오.'
    }
    
    if ($SubscriptionName)
    {

        # 구독 이름을 제공한 경우 계정에 구독이 있는지 확인하십시오.
        if (!(Get-AzureSubscription -SubscriptionName $SubscriptionName))
        {
            throw ("{0}: 구독 이름 $SubscriptionName을 찾을 수 없습니다." -f $scriptName)

        }

        # 지정된 구독을 현재 구독으로 설정하십시오.
        Select-AzureSubscription -SubscriptionName $SubscriptionName | Out-Null

        Write-VerboseWithTime ('{0}: 구독이 {1}(으)로 설정됩니다.' -f $scriptName, $SubscriptionName)
    }

    $Config = Read-ConfigFile $Configuration 

    #웹 응용 프로그램을 빌드하고 패키지하십시오.
    New-WebDeployPackage

    #웹 응용 프로그램에서 단위 테스트를 실행하십시오.
    Test-WebApplication

    #JSON 구성 파일에 설명된 Azure 환경을 만드십시오.
    $newEnvironmentResult = New-AzureWebApplicationWebsiteEnvironment -Configuration $Config -DatabaseServerPassword $DatabaseServerPassword

    #사용자가 $WebDeployPackage를 지정한 경우 웹 응용 프로그램 패키지를 배포하십시오. 
    if($WebDeployPackage)
    {
        Publish-AzureWebApplicationToWebsite `
            -Configuration $Config `
            -ConnectionString $newEnvironmentResult.ConnectionString `
            -WebDeployPackage $WebDeployPackage
    }
}
finally
{
    $Global:ErrorActionPreference = $originalErrorActionPreference
    $Global:VerbosePreference = $originalVerbosePreference

    # 원래 현재 구독을 Current 상태로 복원하십시오.
    Restore-Subscription

    Write-Output $Global:AzureWebAppPublishOutput    
    $Global:AzureWebAppPublishOutput = @()
}
