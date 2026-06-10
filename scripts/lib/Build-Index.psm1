function New-KeywordsIndex {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $DetailsRoot,
    [Parameter(Mandatory)][string] $OutputPath
  )

  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.AppendLine('# PowerLanguage Keywords Index')
  [void]$sb.AppendLine()
  [void]$sb.AppendLine('Index of every PowerLanguage keyword grouped by the 40 categories from MultiCharts''s help system. For full per-keyword documentation, open `details/<Category>/<Keyword>.md`.')
  [void]$sb.AppendLine()

  $categories = Get-ChildItem $DetailsRoot -Directory | Sort-Object Name
  foreach ($cat in $categories) {
    $keywords = Get-ChildItem $cat.FullName -Filter '*.md' | Sort-Object BaseName
    if ($keywords.Count -eq 0) { continue }

    [void]$sb.AppendLine("## $($cat.Name)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| Keyword | Signature |')
    [void]$sb.AppendLine('|---|---|')

    foreach ($kw in $keywords) {
      # -Encoding UTF8: detail files are written BOM-less; PS 5.1 would read them as ANSI.
      $body = Get-Content $kw.FullName -Raw -Encoding UTF8
      $sig = if ($body -match '(?m)^\*\*Signature:\*\*\s*`(.+?)`') { $Matches[1] } else { '' }
      [void]$sb.AppendLine("| ``$($kw.BaseName)`` | ``$sig`` |")
    }
    [void]$sb.AppendLine()
  }

  # Write UTF-8 without BOM (same pattern as Write-DetailFile)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($OutputPath, $sb.ToString(), $utf8NoBom)

  return $OutputPath
}

Export-ModuleMember -Function New-KeywordsIndex
