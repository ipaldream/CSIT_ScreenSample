#  AzureWebSitePublishModule.psm1은 Windows PowerShell 스크립트 모듈입니다. 이 모듈에서는 웹 응용 프로그램에 대한 수명 주기 관리를 자동화하는 Windows PowerShell 함수를 내보냅니다. 함수를 그대로 사용하거나, 사용하는 응용 프로그램 및 게시 환경에 맞게 사용자 지정할 수 있습니다.

Set-StrictMode -Version 3

# 원래 구독을 저장하는 변수입니다.
$Script:originalCurrentSubscription = $null

# 원래 저장소 계정을 저장하는 변수입니다.
$Script:originalCurrentStorageAccount = $null

# 사용자가 지정한 구독의 저장소 계정을 저장하는 변수입니다.
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# 구독 이름을 저장하는 변수입니다.
$Script:userSpecifiedSubscription = $null


<#
.SYNOPSIS
메시지에 날짜와 시간을 추가합니다.

.DESCRIPTION
메시지에 날짜와 시간을 추가합니다. 이 함수는 Error와 Verbose 스트림에 쓴 메시지를 위해 설계된 것입니다.

.PARAMETER  Message
날짜 없이 메시지를 지정합니다.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "디렉토리에 파일 $filename 추가"
2/5/2014 1:03:08 PM - 디렉토리에 파일 $filename 추가

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
현재 시간을 접두사로 한 오류 메시지를 쓰십시오.

.DESCRIPTION
현재 시간을 접두사로 한 오류 메시지를 쓰십시오. 이 함수는 Format-DevTestMessageWithTime 함수를 호출하여 시간을 추가한 다음 Error 스트림에 메시지를 씁니다.

.PARAMETER  Message
오류 메시지 호출에 메시지를 지정합니다. 함수에 메시지 문자열을 파이프할 수 있습니다.

.INPUTS
System.String

.OUTPUTS
없음. 함수가 Error 스트림에 씁니다.

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
현재 시간을 접두사로 한 자세한 메시지를 쓰십시오.

.DESCRIPTION
현재 시간을 접두사로 한 자세한 메시지를 쓰십시오. Write-Verbose를 호출하기 때문에, 스크립트가 Verbose 매개 변수와 실행되는 경우나 VerbosePreference 기본 설정이 Continue로 설정되어 있는 경우에만 메시지가 표시됩니다.

.PARAMETER  Message
자세한 메시지 호출에 메시지를 지정합니다. 함수에 메시지 문자열을 파이프할 수 있습니다.

.INPUTS
System.String

.OUTPUTS
없음. 함수가 Verbose 스트림에 씁니다.

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
현재 시간을 접두사로 한 호스트 메시지를 쓰십시오.

.DESCRIPTION
이 함수는 현재 시간을 접두사로 한 호스트 프로그램(Write-Host)에 메시지를 씁니다. 호스트 프로그램에 쓰는 효과는 다양하게 나타납니다. Windows PowerShell을 호스팅하는 대부분의 프로그램은 표준 출력에 이러한 메시지를 씁니다.

.PARAMETER  Message
날짜 없이 기본 메시지를 지정합니다. 함수에 메시지 문자열을 파이프할 수 있습니다.

.INPUTS
System.String

.OUTPUTS
없음. 함수가 호스트 프로그램에 메시지를 씁니다.

.EXAMPLE
PS C:> Write-HostWithTime -Message "작업이 성공했습니다."
1/27/2014 11:02:37 AM - 작업이 성공했습니다.

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
속성 또는 방법이 개체의 멤버이면 $true를 반환합니다. 그렇지 않으면 $false를 반환합니다.

.DESCRIPTION
속성 또는 방법이 개체의 멤버이면 $true를 반환합니다. 이 함수는 클래스의 정적 방법과 PSBase와 PSObject 등의 뷰에 대해 $false를 반환합니다.

.PARAMETER  Object
테스트에서 개체를 지정합니다. 개체가 포함되어 있는 변수 또는 개체를 반환하는 식을 입력하십시오. 이 함수에는 [DateTime]과 같은 형식을 지정하거나 개체를 파이프할 수 없습니다.

.PARAMETER  Member
테스트에서 속성 또는 방법의 이름을 지정합니다. 방법을 지정할 때는 방법 이름 뒤에 나오는 괄호를 생략하십시오.

.INPUTS
없음. 이 함수는 파이프라인에서 입력을 꺼내지 않습니다.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Azure 모듈 버전이 0.7.4 이상이면 $true를 반환합니다. 아니면 $false를 반환합니다.

.DESCRIPTION
Test-AzureModuleVersion은 Azure 모듈 버전이 0.7.4 이상이면 $true를 반환합니다. 모듈이 설치되어 있지 않거나 이전 버전일 경우 $false를 반환합니다. 이 함수에는 매개 변수가 없습니다.

.INPUTS
없음

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
설치된 Azure 모듈 버전이 0.7.4 이상이면 $true를 반환합니다.

.DESCRIPTION
Test-AzureModule은 설치된 Azure 모듈 버전이 0.7.4 이상이면 $true를 반환합니다. 모듈이 설치되어 있지 않거나 이전 버전일 경우 $false를 반환합니다. 이 함수에는 매개 변수가 없습니다.

.INPUTS
없음

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
현재 Microsoft Azure 구독을 스크립트 범위의 $Script:originalSubscription 변수에 저장합니다.

.DESCRIPTION
Backup-Subscription 함수는 현재 Microsoft Azure 구독(Get-AzureSubscription -Current) 및 저장소 계정과 이 스크립트로 변경되는 구독($UserSpecifiedSubscription) 및 저장소 계정을 스크립트 범위에 저장합니다. 이 값을 저장하면 현재 상태가 변경된 경우 Restore-Subscription과 같은 함수를 사용하여 원래 현재 구독과 저장소 계정을 현재 상태로 복원할 수 있습니다.

.PARAMETER UserSpecifiedSubscription
새 리소스를 만들고 게시할 구독의 이름을 지정합니다. 함수는 스크립트 범위에 구독의 이름과 저장소 계정을 저장합니다. 이 매개 변수는 필수 사항입니다.

.INPUTS
없음

.OUTPUTS
없음

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Microsoft Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: 시작'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: 원래 구독이 다음과 같습니다. ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: 끝'
}


<#
.SYNOPSIS
스크립트 범위의 $Script:originalSubscription 변수에 저장된 Microsoft Azure 구독을 "현재" 상태로 복원합니다.

.DESCRIPTION
Restore-Subscription 함수는 $Script:originalSubscription 변수에 저장된 구독을 다시 현재 구독으로 만듭니다. 원래 구독에 저장소 계정이 있으면 이 함수는 저장소 계정을 현재 구독 계정으로 만듭니다. 함수는 환경에 null이 아닌 $SubscriptionName 변수가 있을 경우에만 구독을 복원합니다. 그렇지 않으면 종료됩니다. $SubscriptionName은 채워져 있는데 $Script:originalSubscription이 $null이면, Restore-Subscription은 Select-AzureSubscription cmdlet를 사용하여 Microsoft Azure PowerShell에서 구독의 현재 및 기본 설정을 지웁니다. 이 함수에는 매개 변수가 없고, 입력을 사용하지 않고, 아무것도 반환하지 않습니다(void). -Verbose를 사용하여 Verbose 스트림에 메시지를 쓸 수 있습니다.

.INPUTS
없음

.OUTPUTS
없음

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: 시작'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: 끝'
}


<#
.SYNOPSIS
config 파일의 유효성을 검사하고 config 파일 값의 해시 테이블을 반환합니다.

.DESCRIPTION
Read-ConfigFile 함수는 JSON 구성 파일의 유효성을 검사하고 선택한 값의 해시 테이블을 반환합니다.
-- JSON 파일을 PSCustomObject(으)로 변환하면 시작됩니다. 웹 사이트 해시 테이블에 있는 키는 다음과 같습니다.
-- Location: 웹 사이트 위치
-- Databases: 웹 사이트 SQL 데이터베이스

.PARAMETER  ConfigurationFile
웹 프로젝트에 대해 JSON 구성 파일의 경로와 이름을 지정합니다. Visual Studio는 웹 프로젝트를 만들면 JSON 파일을 자동으로 생성하고 솔루션의 PublishScripts 폴더에 저장합니다.

.PARAMETER HasWebDeployPackage
웹 응용 프로그램에 대한 웹 배포 패키지 ZIP 파일이 있음을 나타냅니다. $true 값을 지정하려면 -HasWebDeployPackage 또는 HasWebDeployPackage:$true를 사용하고, false 값을 지정하려면 HasWebDeployPackage:$false를 사용합니다. 이 매개 변수는 필수 사항입니다.

.INPUTS
없음. 이 함수에 입력을 파이프할 수 없습니다.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
website                        @{name="mysite"; location="West US";}                                                      
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile
    )

    Write-VerboseWithTime 'Read-ConfigFile: 시작'

    # JSON 파일의 콘텐츠(-raw는 줄 바뀜 무시)를 가져와 PSCustomObject로 변환하십시오.
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: ConvertFrom-Json 실패: ' + $error[0])
    }

    # 속성 값에 관계없이 environmentSettings 개체에 'webSite' 속성이 있는지 확인하십시오.
    $hasWebsiteProperty =  Test-Member -Object $config.environmentSettings -Member 'webSite'

    if (!$hasWebsiteProperty)
    {
        throw 'Read-ConfigFile: 구성 파일에 webSite 속성이 없습니다.'
    }

    # PSCustomObject의 값에서 해시 테이블을 빌드하십시오.
    $returnObject = New-Object -TypeName Hashtable

    $returnObject.Add('name', $config.environmentSettings.webSite.name)
    $returnObject.Add('location', $config.environmentSettings.webSite.location)

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: 끝'

    return $returnObject
}


<#
.SYNOPSIS
Microsoft Azure 웹 사이트를 만듭니다.

.DESCRIPTION
특정 이름과 위치를 사용하여 Microsoft Azure 웹 사이트를 만듭니다. 이 함수는 Azure 모듈에서 New-AzureWebsite cmdlet을 호출합니다. 구독에 지정된 이름의 웹 사이트가 없는 경우 이 함수가 웹 사이트를 만들고 웹 사이트 개체를 반환합니다. 그렇지 않으면, 기존 웹 사이트를 반환합니다.

.PARAMETER  Name
새 웹 사이트의 이름을 지정합니다. VM 이름은 Microsoft Azure에서 고유해야 합니다. 이 매개 변수는 필수 사항입니다.

.PARAMETER  Location
웹 사이트의 위치를 지정합니다. 올바른 값은 "West US"와 같은 Microsoft Azure 위치입니다. 이 매개 변수는 필수 사항입니다.

.INPUTS
없음.

.OUTPUTS
Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.Site

.EXAMPLE
Add-AzureWebsite -Name TestSite -Location "West US"

Name       : contoso
State      : Running
Host Names : contoso.azurewebsites.net

.LINK
New-AzureWebsite
#>
function Add-AzureWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )

    Write-VerboseWithTime 'Add-AzureWebsite: 시작'
    $website = Get-AzureWebsite -Name $Name -ErrorAction SilentlyContinue

    if ($website)
    {
        Write-HostWithTime ('Add-AzureWebsite: 기존 웹 사이트입니다. ' +
        $website.Name + ' 찾았습니다.')
    }
    else
    {
        if (Test-AzureName -Website -Name $Name)
        {
            Write-ErrorWithTime ('웹 사이트 {0}이(가) 이미 있습니다.' -f $Name)
        }
        else
        {
            $website = New-AzureWebsite -Name $Name -Location $Location
        }
    }

    $website | Out-String | Write-VerboseWithTime
    Write-VerboseWithTime 'Add-AzureWebsite: 끝'

    return $website
}

<#
.SYNOPSIS
URL이 절대이고 스키마가 https이면 $True를 반환합니다.

.DESCRIPTION
Test-HttpsUrl 함수는 입력 URL을 System.Uri 개체로 변환합니다. URL이 (상대가 아닌) 절대이고 스키마가 https이면 $True를 반환합니다. 둘 중 하나가 false이거나 입력 문자열을 URL로 변환할 수 없으면 함수가 $false를 반환합니다.

.PARAMETER Url
테스트에 URL을 지정합니다. URL 문자열을 입력하십시오.

.INPUTS
없음.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # $uri를 System.Uri 개체로 변환할 수 없으면 Test-HttpsUrl이 $false를 반환합니다.
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Microsoft Azure SQL 데이터베이스에 연결할 수 있는 문자열을 만듭니다.

.DESCRIPTION
Get-AzureSQLDatabaseConnectionString 함수는 연결 문자열을 조합하여 Microsoft Azure SQL 데이터베이스에 연결합니다.

.PARAMETER  DatabaseServerName
Microsoft Azure 구독에서 기존 데이터베이스 서버의 이름을 지정합니다. 모든 Microsoft Azure 데이터베이스는 SQL 데이터베이스 서버와 연결되어 있어야 합니다. 서버 이름을 가져오려면 Get-AzureSqlDatabaseServer cmdlet(Azure 모듈)를 사용하십시오. 이 매개 변수는 필수 사항입니다.

.PARAMETER  DatabaseName
SQL 데이터베이스의 이름을 지정합니다. 이것은 기존의 SQL 데이터베이스 또는 새 SQL 데이터베이스에 사용되는 이름일 수 있습니다. 이 매개 변수는 필수 사항입니다.

.PARAMETER  Username
SQL 데이터베이스 관리자의 이름을 지정합니다. 사용자 이름은 $Username@DatabaseServerName입니다. 이 매개 변수는 필수 사항입니다.

.PARAMETER  Password
SQL 데이터베이스 관리자의 암호를 지정합니다. 암호를 평문으로 입력하십시오. 안전 문자열은 허용되지 않습니다. 이 매개 변수는 필수 사항입니다.

.INPUTS
없음.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName[0]
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'password'

Server=tcp:testserver.database.windows.net,1433;Database=testdb;User ID=admin@testserver;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Visual Studio가 생성하는 JSON 구성 파일의 값에서 Microsoft Azure SQL 데이터베이스를 만듭니다.

.DESCRIPTION
Add-AzureSQLDatabases 함수는 JSON 파일의 데이터베이스 섹션에서 정보를 가져갑니다. 이 함수 Add-AzureSQLDatabases(복수)는 JSON 파일의 각 SQL 데이터베이스에 대해 Add-AzureSQLDatabase(단수) 함수를 호출합니다. Add-AzureSQLDatabase(단수)는 SQL 데이터베이스를 만드는 New-AzureSqlDatabase cmdlet(Azure 모듈)를 호출합니다. 이 함수는 데이터베이스 개체를 반환하지 않습니다. 데이터베이스를 만드는 데 사용된 값의 해시 테이블을 반환합니다.

.PARAMETER DatabaseConfig
 JSON 파일에 웹 사이트 속성이 있을 경우 Read-ConfigFile 함수가 반환하는 JSON 파일에서 발생하는 PSCustomObjects의 어레이를 꺼냅니다. 여기에는 environmentSettings.databases 속성이 포함됩니다. 이 함수에 목록을 파이프할 수 있습니다.
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
SQL 데이터베이스 서버 관리자의 암호를 지정합니다. Name 및 Password 키를 사용하여 해시 테이블을 입력합니다. Name 값은 SQL 데이터베이스 서버의 이름이고, Password 값은 관리자 암호입니다(예: @Name = "TestDB1"; Password = "password"). 이 매개 변수는 선택 사항입니다. 생략하거나 SQL 데이터베이스 서버 이름이 $DatabaseConfig 개체의 serverName 속성 값과 일치하지 않는 경우 함수가 연결 문자열에서 SQL 데이터베이스에 대해 $DatabaseConfig 개체의 Password 속성을 사용합니다.

.PARAMETER CreateDatabase
데이터베이스를 만들고자 함을 확인합니다. 이 매개 변수는 선택 사항입니다.

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $false
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: 시작'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: 만드는 중 ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # DatabaseConfig 값으로 새 SQL 데이터베이스 만들기(이미 존재하지 않는 경우)
            # 명령 출력이 생략되었습니다.
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: 끝'
    }
}


<#
.SYNOPSIS
새 Microsoft Azure SQL 데이터베이스를 만듭니다.

.DESCRIPTION
Add-AzureSQLDatabase 함수는 Visual Studio가 생성하는 JSON 구성 파일의 데이터에서 Microsoft Azure SQL 데이터베이스를 생성하고 새 데이터베이스를 반환합니다. 구독에 이미 SQL 데이터베이스 서버에 데이터베이스 이름이 지정된 SQL 데이터베이스가 있는 경우 함수는 기존 데이터베이스를 반환합니다. 이 함수는 SQL 데이터베이스를 실제로 만드는 New-AzureSqlDatabase cmdlet(Azure 모듈)를 호출합니다.

.PARAMETER DatabaseConfig
JSON 파일에 웹 사이트 속성이 있을 경우 Read-ConfigFile 함수가 반환하는 JSON 구성 파일에서 발생하는 PSCustomObject를 꺼냅니다. 여기에는 environmentSettings.databases 속성이 포함됩니다. 이 함수에 개체를 파이프할 수 없습니다. Visual Studio는 모든 웹 프로젝트에 대해 JSON 구성 파일을 생성하고 솔루션의 PublishScripts 폴더에 저장합니다.

.INPUTS
없음. 이 함수는 파이프라인에서 입력을 꺼내지 않습니다.

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: 시작'

    # 매개 변수 값에 serverName 속성이 없거나 serverName 속성 값이 채워져 있지 않으면 실패합니다.
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: DatabaseConfig 값에 데이터베이스 serverName(필수 사항)이 없습니다.'
    }

    # 매개 변수 값에 databasename 속성이 없거나 databasename 속성 값이 채워져 있지 않으면 실패합니다.
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: DatabaseConfig 값에 databasename(필수 사항)이 없습니다.'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: 기존 데이터베이스 사용 ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # $DatabaseConfig 개체에 collation 속성이 있고 null 또는 비어 있지 않은 경우
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # $DatabaseConfig 개체에 edition 속성이 있고 null 또는 비어 있지 않은 경우
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # Verbose 스트림에 해시 테이블을 쓰십시오.
        $param | Out-String | Write-VerboseWithTime
        # 스플래팅으로 New-AzureSqlDatabase를 호출하십시오(출력 생략).
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: 끝'
    return $db
}
