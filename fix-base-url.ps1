$files = Get-ChildItem lib\services\*.dart

foreach ($f in $files) {
    $text = Get-Content $f.FullName -Raw

    if ($text -notmatch "127\.0\.0\.1:8000") { continue }

    # point the default at the shared config
    $text = $text -replace "'http://127\.0\.0\.1:8000'", "Api.base"

    # add the import if it isn't already there
    if ($text -notmatch "import '\.\./config\.dart';") {
        # after the last import line, so it lands in the right block
        $text = [regex]::Replace(
            $text,
            "(?s)^(.*?import [^\n]+;\r?\n)",
            "`$1import '../config.dart';`n",
            1
        )
    }

    Set-Content $f.FullName $text -NoNewline
    Write-Host "fixed $($f.Name)"
}