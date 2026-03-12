param(
    [Parameter(Mandatory=$true)][string]$LearnerId,
    [Parameter(Mandatory=$true)][string]$CourseId,
    [Parameter(Mandatory=$true)][string]$ModuleId,
    [Parameter(Mandatory=$true)][string]$ObjectiveId,
    [Parameter(Mandatory=$true)][string]$TimestampUtc
)

$payload = "$LearnerId|$CourseId|$ModuleId|$ObjectiveId|$TimestampUtc"
$sha = [System.Security.Cryptography.SHA256]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
$hash = $sha.ComputeHash($bytes)
$hex = -join ($hash | ForEach-Object { $_.ToString("x2") })

# Compact token keeps resume deterministic while remaining easy to pass around.
$token = "resume:$LearnerId:$($hex.Substring(0,24))"

[PSCustomObject]@{
    token = $token
    hash = $hex
}
