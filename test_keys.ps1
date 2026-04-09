$keys = @(
  'AIzaSyCitrLAFN-C6qD7rFdzpsSMaidyVtOmhuM',
  'AIzaSyAfLhtjJTs-jy--wZeYOh44QVBbY_o-Xio',
  'AIzaSyAYIgw1LvfOFrUPV3SwcA_qeBD1WqkRRRQ',
  'AIzaSyC1U_8WGv7Beq-p6XojjtRTdcF8fHvTauM',
  'AIzaSyCAhycjL6fpvIqP1RrTQ7JGUwcGhCFTKck'
)
$body = '{"contents": [{"parts": [{"text": "Reply with only the word: OK"}]}]}'
$i = 1
foreach ($key in $keys) {
  try {
    $r = Invoke-RestMethod -Uri "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key" -Method POST -ContentType 'application/json' -Body $body
    $reply = $r.candidates[0].content.parts[0].text.Trim()
    Write-Host "Key $i : SUCCESS -> $reply"
  } catch {
    Write-Host "Key $i : FAILED -> $($_.Exception.Message)"
  }
  $i++
  Start-Sleep -Seconds 2
}
