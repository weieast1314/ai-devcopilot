[CmdletBinding()]
param(
    [string]$TargetProject = ".",
    [string]$Editor = "",
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LegacySkillsSource = Join-Path $ScriptDir 'skills/ai-devcopilot'
$DistDir = Join-Path $ScriptDir 'dist'
$AdaptersDir = Join-Path $ScriptDir 'adapters'
$EditorManifestPath = Join-Path $AdaptersDir 'editors.json'
$TemplateFile = Join-Path $ScriptDir 'env.sh.template'
$Version = '1.3.0'

$GlobalConfigDir = Join-Path $HOME '.ai-devcopilot'
$EnvFile = Join-Path $GlobalConfigDir 'env.sh'
$ProjectConfigDirRel = '.ai-devcopilot'
$ProjectEnvFileRel = '.ai-devcopilot/env.sh'
$ProjectMemoryDirRel = '.ai-devcopilot/memory'
$ProjectStateDirRel = '.ai-devcopilot/state'
$FlowStateTemplate = Join-Path $ScriptDir 'templates/flow-state.template.json'

function Expand-HomePath {
    param([string]$RawPath)

    if ([string]::IsNullOrWhiteSpace($RawPath)) {
        return $RawPath
    }

    if ($RawPath -eq '~') {
        return $HOME
    }

    if ($RawPath.StartsWith('~/') -or $RawPath.StartsWith('~\')) {
        return Join-Path $HOME $RawPath.Substring(2)
    }

    return $RawPath
}

function Normalize-EditorId {
    param([string]$Value)
    return $Value.ToLowerInvariant()
}

function Test-CommandAvailable {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

if (Test-Path $EditorManifestPath) {
    $editorManifest = Get-Content $EditorManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($editorManifest.sharedConfig) {
        $GlobalConfigDir = Expand-HomePath $editorManifest.sharedConfig.globalConfigDir
        $EnvFile = Expand-HomePath $editorManifest.sharedConfig.globalEnvFile
        $ProjectConfigDirRel = $editorManifest.sharedConfig.projectConfigDir
        $ProjectEnvFileRel = $editorManifest.sharedConfig.projectEnvFile
        $ProjectMemoryDirRel = $editorManifest.sharedConfig.projectMemoryDir
    }
} else {
    $editorManifest = $null
}

function Get-LegacyAdapter {
    param([string]$EditorId)

    switch (Normalize-EditorId $EditorId) {
        'claude' {
            return [pscustomobject]@{
                id = 'claude'
                displayName = 'Claude'
                paths = [pscustomobject]@{
                    skillsRoot = '~/.claude/skills'
                    skillsInstallDir = '~/.claude/skills/ai-devcopilot'
                    mcpConfigPath = '~/.claude/mcp.json'
                }
                install = [pscustomobject]@{
                    scanMode = 'top_level_only'
                    requiresTopLevelSymlink = $true
                    linkStrategy = [pscustomobject]@{
                        recordFile = '~/.claude/skills/.ai-devcopilot-links'
                        categories = @(
                            [pscustomobject]@{ name = 'atoms'; depth = 2 },
                            [pscustomobject]@{ name = 'composites'; depth = 2 },
                            [pscustomobject]@{ name = 'pipelines'; depth = 1 }
                        )
                    }
                }
                runtime = [pscustomobject]@{
                    supportsMcp = $true
                    supportsAutoRun = $true
                    supportsAskFollowup = $true
                    supportsStatePersistence = $true
                    agentFrontmatterProfile = 'claude'
                }
            }
        }
        'codebuddy' {
            return [pscustomobject]@{
                id = 'codebuddy'
                displayName = 'CodeBuddy'
                paths = [pscustomobject]@{
                    skillsRoot = '~/.codebuddy/skills'
                    skillsInstallDir = '~/.codebuddy/skills/ai-devcopilot'
                    mcpConfigPath = '~/.codebuddy/mcp.json'
                }
                install = [pscustomobject]@{
                    scanMode = 'package_root'
                    requiresTopLevelSymlink = $false
                    linkStrategy = $null
                }
                runtime = [pscustomobject]@{
                    supportsMcp = $true
                    supportsAutoRun = $true
                    supportsAskFollowup = $true
                    supportsStatePersistence = $true
                    agentFrontmatterProfile = 'codebuddy'
                }
            }
        }
        'opencode' {
            return [pscustomobject]@{
                id = 'opencode'
                displayName = 'OpenCode'
                paths = [pscustomobject]@{
                    skillsRoot = '~/.opencode/skills'
                    skillsInstallDir = '~/.opencode/skills/ai-devcopilot'
                    mcpConfigPath = '~/.opencode/mcp.json'
                }
                install = [pscustomobject]@{
                    scanMode = 'package_root'
                    requiresTopLevelSymlink = $false
                    linkStrategy = $null
                }
                runtime = [pscustomobject]@{
                    supportsMcp = $true
                    supportsAutoRun = $true
                    supportsAskFollowup = $true
                    supportsStatePersistence = $true
                    agentFrontmatterProfile = 'opencode'
                }
            }
        }
        default {
            throw "Unknown editor config: $EditorId"
        }
    }
}

function Get-EditorConfig {
    param([string]$EditorId)

    $normalizedEditorId = Normalize-EditorId $EditorId
    $adapterFile = Join-Path $AdaptersDir ("{0}.json" -f $normalizedEditorId)

    if (Test-Path $adapterFile) {
        return Get-Content $adapterFile -Raw -Encoding UTF8 | ConvertFrom-Json
    }

    return Get-LegacyAdapter $normalizedEditorId
}

function Get-DistSkillsSource {
    param([string]$EditorId)
    return Join-Path $DistDir ("{0}/skills/ai-devcopilot" -f (Normalize-EditorId $EditorId))
}

function Resolve-SkillsSource {
    param([string]$EditorId)

    $distSource = Get-DistSkillsSource $EditorId

    # 优先使用已存在的 dist
    if (Test-Path $distSource) {
        return $distSource
    }

    # dist 不存在，尝试自动构建
    $buildScript = Join-Path $ScriptDir 'scripts/build-dist.sh'
    if (Test-Path $buildScript) {
        Write-Host "      Building dist artifacts..." -ForegroundColor Yellow
        $editorIdNormalized = Normalize-EditorId $EditorId
        $result = & bash $buildScript --editor $editorIdNormalized 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $distSource)) {
            Write-Host "      Build completed" -ForegroundColor Green
            return $distSource
        } else {
            Write-Host "      Build failed, trying source directory" -ForegroundColor Yellow
        }
    }

    # 回退到源目录
    if (Test-Path $LegacySkillsSource) {
        return $LegacySkillsSource
    }

    throw 'No available skills source directory found.'
}

function Describe-SkillsSource {
    param([string]$EditorId)

    $distSource = Get-DistSkillsSource $EditorId
    if (Test-Path $distSource) {
        return "dist/$($EditorId.ToLowerInvariant())/skills/ai-devcopilot"
    }

    if (Test-Path $LegacySkillsSource) {
        return 'skills/ai-devcopilot (legacy fallback)'
    }

    return 'missing'
}

function Show-InstallPlan {
    param([string[]]$Editors, [string]$ModeLabel)

    Write-Host "Install plan ($ModeLabel)" -ForegroundColor Yellow
    foreach ($editorId in $Editors) {
        $adapter = Get-EditorConfig $editorId
        $skillsTarget = Expand-HomePath $adapter.paths.skillsInstallDir
        $mcpTarget = Expand-HomePath $adapter.paths.mcpConfigPath

        Write-Host ''
        Write-Host "  [$($adapter.displayName)]"
        Write-Host "    - Skills source:    $(Describe-SkillsSource $editorId)"
        Write-Host "    - Skills target:    $skillsTarget"
        Write-Host "    - MCP config:       $mcpTarget"
        Write-Host "    - Scan mode:        $($adapter.install.scanMode)"
        Write-Host ("    - Top-level links:  {0}" -f $(if ($adapter.install.requiresTopLevelSymlink) { 'yes' } else { 'no' }))
    }

    Write-Host ''
    Write-Host '  [Shared config]'
    Write-Host "    - Global env:       $EnvFile"
    Write-Host "    - Project env:      $ProjectEnvFileRel"
    Write-Host "    - Project memory:   $ProjectMemoryDirRel"
    Write-Host "    - Flow state:       $ProjectStateDirRel/flow-state.json"
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -Path $Source -Force | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Test-ReparsePoint {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    $item = Get-Item $Path -Force
    return (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

function New-DirectoryLink {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    if (Test-Path $LinkPath) {
        Remove-Item -Path $LinkPath -Recurse -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
    } catch {
        New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force | Out-Null
    }
}

function Create-TopLevelLinks {
    param([pscustomobject]$Adapter)

    $skillsTarget = Expand-HomePath $Adapter.paths.skillsInstallDir
    $skillsRoot = Expand-HomePath $Adapter.paths.skillsRoot
    $recordFile = Expand-HomePath $Adapter.install.linkStrategy.recordFile
    $recordDir = Split-Path -Parent $recordFile
    $createdLinks = New-Object System.Collections.Generic.List[string]
    $linkCount = 0
    $collisionCount = 0

    New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $recordDir -Force | Out-Null

    if (Test-Path $recordFile) {
        Get-Content $recordFile | ForEach-Object {
            $oldLink = $_.Trim()
            if ($oldLink -and (Test-Path $oldLink)) {
                Remove-Item -Path $oldLink -Recurse -Force
            }
        }
        Remove-Item -Path $recordFile -Force
    }

    foreach ($rule in $Adapter.install.linkStrategy.categories) {
        $categoryPath = Join-Path $skillsTarget $rule.name
        if (-not (Test-Path $categoryPath)) {
            continue
        }

        if ([int]$rule.depth -eq 2) {
            $skillDirs = foreach ($parentDir in Get-ChildItem -Path $categoryPath -Directory) {
                Get-ChildItem -Path $parentDir.FullName -Directory
            }
        } else {
            $skillDirs = Get-ChildItem -Path $categoryPath -Directory
        }

        foreach ($skillDir in $skillDirs) {
            $linkPath = Join-Path $skillsRoot $skillDir.Name
            if ((Test-Path $linkPath) -and -not (Test-ReparsePoint $linkPath)) {
                Write-Host "      WARNING: skip existing non-link directory $($skillDir.Name)" -ForegroundColor Yellow
                $collisionCount++
                continue
            }

            New-DirectoryLink -LinkPath $linkPath -TargetPath $skillDir.FullName
            $createdLinks.Add($linkPath) | Out-Null
            $linkCount++
        }
    }

    Set-Content -Path $recordFile -Value $createdLinks -Encoding UTF8
    Write-Host "      OK: created $linkCount top-level link entries"
    if ($collisionCount -gt 0) {
        Write-Host "      WARNING: skipped $collisionCount colliding directories" -ForegroundColor Yellow
    }
}

function Get-EnvMap {
    param([string]$Path)

    $map = @{}
    if (-not (Test-Path $Path)) {
        return $map
    }

    foreach ($line in Get-Content $Path) {
        if ($line -match '^\s*#?\s*export\s+([A-Z0-9_]+)=(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $map[$key] = $value
        }
    }

    return $map
}

function Set-ExportLine {
    param(
        [string]$Content,
        [string]$Key,
        [string]$Value,
        [switch]$AllowCommented
    )

    $pattern = if ($AllowCommented) {
        "(?m)^#?\s*export\s+$([regex]::Escape($Key))=.*$"
    } else {
        "(?m)^export\s+$([regex]::Escape($Key))=.*$"
    }

    $replacement = "export $Key=`"$Value`""
    return [regex]::Replace($Content, $pattern, $replacement)
}

function Render-EnvContent {
    param(
        [hashtable]$Values,
        [switch]$IncludeLark
    )

    $content = Get-Content $TemplateFile -Raw -Encoding UTF8
    $content = Set-ExportLine -Content $content -Key 'JENKINS_URL' -Value $Values.JENKINS_URL
    $content = Set-ExportLine -Content $content -Key 'JENKINS_USERNAME' -Value $Values.JENKINS_USERNAME
    $content = Set-ExportLine -Content $content -Key 'JENKINS_API_TOKEN' -Value $Values.JENKINS_API_TOKEN
    $content = Set-ExportLine -Content $content -Key 'NACOS_SERVER_ADDR' -Value $Values.NACOS_SERVER_ADDR
    $content = Set-ExportLine -Content $content -Key 'NACOS_NAMESPACE' -Value $Values.NACOS_NAMESPACE
    $content = Set-ExportLine -Content $content -Key 'NACOS_GROUP' -Value $Values.NACOS_GROUP

    if ($IncludeLark) {
        $content = Set-ExportLine -Content $content -Key 'LARK_APP_ID' -Value $Values.LARK_APP_ID -AllowCommented
        $content = Set-ExportLine -Content $content -Key 'LARK_APP_SECRET' -Value $Values.LARK_APP_SECRET -AllowCommented
    }

    return $content
}

function Add-McpServer {
    param(
        [psobject]$Servers,
        [string]$Name,
        [pscustomobject]$Value
    )

    if ($Servers.PSObject.Properties.Name -contains $Name) {
        $Servers.$Name = $Value
    } else {
        $Servers | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Ensure-ObjectProperty {
    param(
        [psobject]$Object,
        [string]$Name,
        [object]$DefaultValue
    )

    if ($Object.PSObject.Properties.Name -notcontains $Name) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $DefaultValue
    }
}

function Update-McpConfig {
    param(
        [string]$McpConfigFile,
        [string]$LarkId,
        [string]$LarkSecret
    )

    $configDir = Split-Path -Parent $McpConfigFile
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null

    if (Test-Path $McpConfigFile) {
        $raw = Get-Content $McpConfigFile -Raw -Encoding UTF8
        $config = if ([string]::IsNullOrWhiteSpace($raw)) { [pscustomobject]@{} } else { $raw | ConvertFrom-Json }
    } else {
        $config = [pscustomobject]@{}
    }

    Ensure-ObjectProperty -Object $config -Name 'mcpServers' -DefaultValue ([pscustomobject]@{})

    if ($config.mcpServers.PSObject.Properties.Name -contains 'lark') {
        Write-Host "      OK: lark MCP already exists at $McpConfigFile"
        return
    }

    $larkConfig = [pscustomobject]@{
        command = 'npx'
        args = @('-y', '@larksuiteoapi/lark-mcp', 'mcp', '--app-id', $LarkId, '--app-secret', $LarkSecret)
    }

    Add-McpServer -Servers $config.mcpServers -Name 'lark' -Value $larkConfig
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $McpConfigFile -Encoding UTF8
    Write-Host "      OK: updated MCP config $McpConfigFile"
}

function Install-Skills {
    param([string]$EditorId)

    $adapter = Get-EditorConfig $EditorId
    $skillsSource = Resolve-SkillsSource $EditorId
    $skillsTarget = Expand-HomePath $adapter.paths.skillsInstallDir

    Copy-DirectoryContents -Source $skillsSource -Destination $skillsTarget
    Write-Host "      OK: skills installed to $skillsTarget"
    Write-Host "      OK: install source $skillsSource"

    if ($adapter.install.requiresTopLevelSymlink) {
        Create-TopLevelLinks -Adapter $adapter
    }

    return Expand-HomePath $adapter.paths.mcpConfigPath
}

Write-Host "=== AI DevCopilot installer (v$Version) ===" -ForegroundColor Green
Write-Host ''
Write-Host '[1/5] Select editor' -ForegroundColor Yellow

if ([string]::IsNullOrWhiteSpace($Editor)) {
    Write-Host 'Select editor:'
    Write-Host '1) Claude (~/.claude)'
    Write-Host '2) CodeBuddy (~/.codebuddy)'
    Write-Host '3) OpenCode (~/.opencode)'
    Write-Host '4) All editors'
    $Editor = Read-Host 'Select [1-4]'
}

switch (Normalize-EditorId $Editor) {
    '1' { $Editors = @('claude') }
    'claude' { $Editors = @('claude') }
    '2' { $Editors = @('codebuddy') }
    'codebuddy' { $Editors = @('codebuddy') }
    '3' { $Editors = @('opencode') }
    'opencode' { $Editors = @('opencode') }
    '4' { $Editors = @('claude', 'codebuddy', 'opencode') }
    'all' { $Editors = @('claude', 'codebuddy', 'opencode') }
    default { $Editors = @('claude') }
}

foreach ($editorId in $Editors) {
    $adapter = Get-EditorConfig $editorId
    Write-Host "      OK: target editor $($adapter.displayName)" -ForegroundColor Green
}
Write-Host ''

Write-Host '[2/5] Environment checks' -ForegroundColor Yellow
$checkFailed = $false
foreach ($required in @(
    @{ Name = 'git'; Desc = 'required'; Required = $true },
    @{ Name = 'curl'; Desc = 'required'; Required = $true },
    @{ Name = 'mvn'; Desc = 'optional'; Required = $false },
    @{ Name = 'npm'; Desc = 'optional'; Required = $false }
)) {
    if (Test-CommandAvailable $required.Name) {
        Write-Host "      OK: found $($required.Name)"
    } else {
        Write-Host "      WARNING: missing $($required.Name) ($($required.Desc))" -ForegroundColor $(if ($required.Required) { 'Red' } else { 'Yellow' })
        if ($required.Required) {
            $checkFailed = $true
        }
    }
}

if ($editorManifest) {
    Write-Host '      OK: adapter manifest loaded'
} else {
    Write-Host '      WARNING: adapters/editors.json not found, using legacy defaults' -ForegroundColor Yellow
}

if (Test-Path $DistDir) {
    Write-Host '      OK: dist artifacts detected; installer will prefer dist/<editor>'
} else {
    Write-Host '      WARNING: dist artifacts missing; installer will fall back to skills/ai-devcopilot' -ForegroundColor Yellow
}

if ($checkFailed) {
    throw 'Environment checks failed. Install required tools first.'
}

Write-Host ''
if ($ValidateOnly) {
    Show-InstallPlan -Editors $Editors -ModeLabel 'validate-only'
    Write-Host ''
    Write-Host 'OK: validate-only passed' -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Show-InstallPlan -Editors $Editors -ModeLabel 'dry-run'
    Write-Host ''
    Write-Host 'OK: dry-run passed with no writes' -ForegroundColor Green
    exit 0
}

Write-Host '[3/5] Install skills' -ForegroundColor Yellow
$mcpFiles = @()
foreach ($editorId in $Editors) {
    $adapter = Get-EditorConfig $editorId
    Write-Host ''
    Write-Host "  Installing to $($adapter.displayName):"
    $mcpFiles += Install-Skills -EditorId $editorId
}
Write-Host ''

$resolvedProject = (Resolve-Path -LiteralPath $TargetProject).Path
$projectName = Split-Path $resolvedProject -Leaf
$defaultJenkinsJobDev = "$projectName-dev"
$defaultJenkinsJobTest = "$projectName-test"
$projectConfigDir = Join-Path $resolvedProject $ProjectConfigDirRel
$projectEnvFile = Join-Path $resolvedProject $ProjectEnvFileRel
$projectMemoryDir = Join-Path $resolvedProject $ProjectMemoryDirRel
$projectStateDir = Join-Path $resolvedProject $ProjectStateDirRel
$projectStateFile = Join-Path $projectStateDir 'flow-state.json'

Write-Host '[4/5] Project config' -ForegroundColor Yellow
New-Item -ItemType Directory -Path $projectConfigDir -Force | Out-Null

if (Test-Path $projectEnvFile) {
    Write-Host "      OK: existing project env found at $ProjectEnvFileRel"
} else {
    @(
        '# Jenkins Job config',
        '# Project-specific job names',
        '',
        "export JENKINS_JOB_DEV=`"$defaultJenkinsJobDev`"",
        "export JENKINS_JOB_TEST=`"$defaultJenkinsJobTest`""
    ) | Set-Content -Path $projectEnvFile -Encoding UTF8

    Write-Host "      OK: created $ProjectEnvFileRel"
    Write-Host "      INFO: default JENKINS_JOB_DEV=$defaultJenkinsJobDev"
    Write-Host "      INFO: default JENKINS_JOB_TEST=$defaultJenkinsJobTest"
}

New-Item -ItemType Directory -Path $projectMemoryDir -Force | Out-Null
Write-Host "      OK: created $ProjectMemoryDirRel/"
New-Item -ItemType Directory -Path $projectStateDir -Force | Out-Null
Write-Host "      OK: created $ProjectStateDirRel/"
if ((Test-Path $FlowStateTemplate) -and -not (Test-Path $projectStateFile)) {
    Copy-Item -Path $FlowStateTemplate -Destination $projectStateFile
    Write-Host "      OK: initialized $ProjectStateDirRel/flow-state.json"
}
Write-Host ''

Write-Host '[5/5] Global env config' -ForegroundColor Yellow
New-Item -ItemType Directory -Path $GlobalConfigDir -Force | Out-Null

if ($Yes) {
    $confirmConfig = 'n'
} else {
    $confirmConfig = Read-Host "Configure env file now ($EnvFile)? [Y/n]"
}

$existingEnv = Get-EnvMap $EnvFile
$defaultValues = @{
    JENKINS_URL = if ($existingEnv.ContainsKey('JENKINS_URL')) { $existingEnv['JENKINS_URL'] } elseif ($env:JENKINS_URL) { $env:JENKINS_URL } else { 'http://your-jenkins:8080' }
    JENKINS_USERNAME = if ($existingEnv.ContainsKey('JENKINS_USERNAME')) { $existingEnv['JENKINS_USERNAME'] } elseif ($env:JENKINS_USERNAME) { $env:JENKINS_USERNAME } else { 'your_username' }
    JENKINS_API_TOKEN = if ($existingEnv.ContainsKey('JENKINS_API_TOKEN')) { $existingEnv['JENKINS_API_TOKEN'] } elseif ($env:JENKINS_API_TOKEN) { $env:JENKINS_API_TOKEN } else { 'your_token' }
    NACOS_SERVER_ADDR = if ($existingEnv.ContainsKey('NACOS_SERVER_ADDR')) { $existingEnv['NACOS_SERVER_ADDR'] } else { 'your-nacos-server:8848' }
    NACOS_NAMESPACE = if ($existingEnv.ContainsKey('NACOS_NAMESPACE')) { $existingEnv['NACOS_NAMESPACE'] } else { 'dev' }
    NACOS_GROUP = if ($existingEnv.ContainsKey('NACOS_GROUP')) { $existingEnv['NACOS_GROUP'] } else { 'DEFAULT_GROUP' }
    LARK_APP_ID = if ($existingEnv.ContainsKey('LARK_APP_ID')) { $existingEnv['LARK_APP_ID'] } elseif ($env:LARK_APP_ID) { $env:LARK_APP_ID } else { '' }
    LARK_APP_SECRET = if ($existingEnv.ContainsKey('LARK_APP_SECRET')) { $existingEnv['LARK_APP_SECRET'] } elseif ($env:LARK_APP_SECRET) { $env:LARK_APP_SECRET } else { '' }
}

if ($confirmConfig -match '^[Nn]$') {
    Write-Host '      INFO: skipped interactive env setup'
    if (-not (Test-Path $EnvFile)) {
        Render-EnvContent -Values $defaultValues | Set-Content -Path $EnvFile -Encoding UTF8
        Write-Host "      OK: created $EnvFile"
    }
    Write-Host '      INFO: configure MCP manually later if you need Lark support'
} else {
    if (Test-Path $EnvFile) {
        Write-Host "      OK: loaded defaults from $EnvFile" -ForegroundColor Green
    }

    $jenkinsUrl = Read-Host "Jenkins URL [$($defaultValues.JENKINS_URL)]"
    $jenkinsUser = Read-Host "Jenkins Username [$($defaultValues.JENKINS_USERNAME)]"
    $jenkinsToken = Read-Host "Jenkins API Token [$($defaultValues.JENKINS_API_TOKEN)]"
    $nacosAddr = Read-Host "Nacos Server Addr [$($defaultValues.NACOS_SERVER_ADDR)]"
    $nacosNs = Read-Host "Nacos Namespace [$($defaultValues.NACOS_NAMESPACE)]"
    $nacosGroup = Read-Host "Nacos Group [$($defaultValues.NACOS_GROUP)]"

    $values = @{
        JENKINS_URL = if ($jenkinsUrl) { $jenkinsUrl } else { $defaultValues.JENKINS_URL }
        JENKINS_USERNAME = if ($jenkinsUser) { $jenkinsUser } else { $defaultValues.JENKINS_USERNAME }
        JENKINS_API_TOKEN = if ($jenkinsToken) { $jenkinsToken } else { $defaultValues.JENKINS_API_TOKEN }
        NACOS_SERVER_ADDR = if ($nacosAddr) { $nacosAddr } else { $defaultValues.NACOS_SERVER_ADDR }
        NACOS_NAMESPACE = if ($nacosNs) { $nacosNs } else { $defaultValues.NACOS_NAMESPACE }
        NACOS_GROUP = if ($nacosGroup) { $nacosGroup } else { $defaultValues.NACOS_GROUP }
        LARK_APP_ID = $defaultValues.LARK_APP_ID
        LARK_APP_SECRET = $defaultValues.LARK_APP_SECRET
    }

    $configureLark = $false
    if ($defaultValues.LARK_APP_ID) {
        Write-Host "Detected existing Lark App ID: $($defaultValues.LARK_APP_ID.Substring(0, [Math]::Min(8, $defaultValues.LARK_APP_ID.Length)))..."
        $useEnvLark = Read-Host 'Use existing Lark config? [Y/n]'
        if ($useEnvLark -notmatch '^[Nn]$') {
            $configureLark = $true
        } else {
            $reconfigureLark = Read-Host 'Reconfigure Lark MCP? [y/N]'
            if ($reconfigureLark -match '^[Yy]$') {
                $values.LARK_APP_ID = Read-Host 'Lark App ID'
                $values.LARK_APP_SECRET = Read-Host 'Lark App Secret'
                $configureLark = -not [string]::IsNullOrWhiteSpace($values.LARK_APP_ID)
            }
        }
    } else {
        $newLark = Read-Host 'Configure Lark MCP? [y/N]'
        if ($newLark -match '^[Yy]$') {
            $values.LARK_APP_ID = Read-Host 'Lark App ID'
            $values.LARK_APP_SECRET = Read-Host 'Lark App Secret'
            $configureLark = -not [string]::IsNullOrWhiteSpace($values.LARK_APP_ID)
        }
    }

    Render-EnvContent -Values $values -IncludeLark:$configureLark | Set-Content -Path $EnvFile -Encoding UTF8
    if ($configureLark -and $values.LARK_APP_ID) {
        foreach ($mcpFile in $mcpFiles) {
            if ($mcpFile) {
                Update-McpConfig -McpConfigFile $mcpFile -LarkId $values.LARK_APP_ID -LarkSecret $values.LARK_APP_SECRET
            }
        }
    }

    Write-Host "      OK: wrote $EnvFile"
}

$gitignoreFile = Join-Path $resolvedProject '.gitignore'
if (Test-Path $gitignoreFile) {
    $gitignoreContent = Get-Content $gitignoreFile -Raw -Encoding UTF8
    if ($gitignoreContent -notmatch [regex]::Escape("$ProjectMemoryDirRel/")) {
        Add-Content -Path $gitignoreFile -Value "`r`n# AI DevCopilot data`r`n$ProjectMemoryDirRel/"
        Write-Host "      OK: added $ProjectMemoryDirRel/ to .gitignore"
    }
}

Write-Host ''
Write-Host '=== Install complete ===' -ForegroundColor Green
Write-Host ''
Write-Host 'Install targets:'
foreach ($editorId in $Editors) {
    $adapter = Get-EditorConfig $editorId
    $skillsTarget = Expand-HomePath $adapter.paths.skillsInstallDir
    Write-Host ("  {0,-10} {1}" -f ($adapter.displayName + ':'), $skillsTarget)
    if ($adapter.install.requiresTopLevelSymlink) {
        Write-Host '             top-level scan links created' -ForegroundColor Green
    }
}
Write-Host ''
Write-Host "Global env:   $EnvFile"
Write-Host "Project env:  $ProjectEnvFileRel"
Write-Host "Project data: $ProjectMemoryDirRel/"
Write-Host "Flow state:   $ProjectStateDirRel/flow-state.json"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Restart the AI editor'
Write-Host "  2. Run '开始开发' or /dev in the chat"
Write-Host '  3. Recommended triggers: 开始开发 / /dev, 热修复 / /hotfix, Feishu links'
