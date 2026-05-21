function Write-KeywordDetailFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable] $Parsed,
    [Parameter(Mandatory)][string]    $Description,
    [Parameter(Mandatory)][string]    $Example,
    [Parameter(Mandatory)][string]    $OutputRoot
  )

  $catDir = Join-Path $OutputRoot $Parsed.Category
  if (-not (Test-Path $catDir)) {
    New-Item -ItemType Directory -Path $catDir -Force | Out-Null
  }
  $outPath = Join-Path $catDir "$($Parsed.Name).md"

  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.AppendLine("# $($Parsed.Name)")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("**Category:** $($Parsed.Category)")
  [void]$sb.AppendLine("**Signature:** ``$($Parsed.Usage)``")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine($Description)

  $hasParams = $Parsed.Parameters -and $Parsed.Parameters.Count -gt 0
  if ($hasParams) {
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('**Parameters**')
    foreach ($p in $Parsed.Parameters) {
      $req = if ($p.Required) { 'required' } else { 'optional' }
      [void]$sb.AppendLine("- ``$($p.Name)`` *($($p.Type), $req)* — $($p.Description)")
    }
  }

  [void]$sb.AppendLine()
  [void]$sb.AppendLine('**Example (illustrative)**')
  [void]$sb.AppendLine('```')
  [void]$sb.AppendLine($Example)
  [void]$sb.AppendLine('```')
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("*Official docs:* https://www.multicharts.com/trading-software/index.php?title=$($Parsed.Name)")

  # Write UTF-8 WITHOUT BOM (Set-Content -Encoding UTF8 in PS 5.1 writes WITH BOM,
  # so use .NET API directly to avoid the BOM bytes)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)

  # Return a path whose prefix matches $OutputRoot exactly (preserving whatever
  # slash style the caller used), then append category/name with forward slashes.
  # This matches the test expectation: "$script:tmp/Category/Name.md"
  return "$OutputRoot/$($Parsed.Category)/$($Parsed.Name).md"
}

Export-ModuleMember -Function Write-KeywordDetailFile
