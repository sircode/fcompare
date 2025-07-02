<?php
if ($argc < 3) {
    echo "Usage: php make_html_report.php INPUT.txt OUTPUT.html\n";
    exit(1);
}

$inputFile = $argv[1];
$outputFile = $argv[2];

if (!file_exists($inputFile)) {
    echo "Input file does not exist.\n";
    exit(1);
}

$lines = file($inputFile);
$html = '<!DOCTYPE html><html><head><meta charset="UTF-8">
<title>fcompare Report</title>
<style>
    body { font-family: monospace; background: #f8f8f8; padding: 1em; }
    .file { margin-top: 1em; font-weight: bold; color: #333; }
    .hunk { color: #999; }
    .add { background-color: #e6ffed; color: #22863a; display: block; white-space: pre; }
    .del { background-color: #ffeef0; color: #b31d28; display: block; white-space: pre; }
     .missing { background-color:rgb(241, 241, 241); color:rgb(63, 63, 63); display: block; white-space: pre; }
    .neutral { display: block; white-space: pre; }
      .filename { font-weight: bold; color: #000; } 
</style>
</head><body>';

foreach ($lines as $line) {
    $line = rtrim($line, "\r\n");
    if (preg_match('/^=== (.+) ===$/', $line, $m)) {
        $html .= "<div class='file'>File: {$m[1]}</div>";
    } elseif (str_starts_with($line, '@@')) {
        $html .= "<div class='hunk'>" . htmlspecialchars($line) . "</div>";
    } elseif (str_starts_with($line, '+')) {
        $html .= "<span class='add'>" . htmlspecialchars($line) . "</span>";
    } elseif (str_starts_with($line, '-')) {
        $html .= "<span class='del'>" . htmlspecialchars($line) . "</span>";
    } elseif (trim($line) === '') {
        // skip blank lines
    } elseif (str_starts_with($line, '[MISSING IN TARGET]')) {
        $html .= "<span class='missing'>" . htmlspecialchars($line) . "</span>";
    } elseif (str_starts_with($line, '[MISSING IN SOURCE]')) {
        $html .= "<span class='missing'>" . htmlspecialchars($line) . "</span>";
    } else {
        $html .= "<span class='neutral'>" . htmlspecialchars($line) . "</span>";
    }
}

$html .= '</body></html>';

file_put_contents($outputFile, $html);
// echo "HTML report created: $outputFile\n";
