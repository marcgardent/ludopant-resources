$mapping = @{
    "OpenBracket"="{";
    "CloseBracket"="}";
    "Quote"='"';
}

function Decode-Ini($content){
    foreach ($map in $mapping.GetEnumerator()) {
        $content = $content.replace("~$($map.Name)~", $map.Value)
    }
    Write-output $content
}
 
function Decode-Keymap-To-Json-Format($File){
    $Items = get-content $File | Where { $_.StartsWith("UserDefinedChords=")} | % { $_.substring(18) }
    $Total = $Items.count
    $Counter = 0
    Write-Output "["
    foreach ($Item in $Items) {
        $Counter += 1
        $decoded = Decode-Ini -content $Item
        if($Counter -ne $Total) {
            Write-Output "$decoded,"
        }else{
            Write-Output "$decoded"
        }
    }
    Write-Output "]"
}

function Format-Shortcut($Data){
    # "Control=True; Alt=False; Shift=False; Command=False; Key=C_Cedille};"
    $ret = ""
    if ($Data.Control) {$ret += "CTRL+"}
    if ($Data.Alt) {$ret += "ALT+"}
    if ($Data.Shift) {$ret += "SHIFT+"}
    if ($Data.Command) {$ret += "CMD+"}
    if ($Data.Key -ne "None") {$ret += $Data.Key}
    if ($ret -ne ""){
        return "``" + $ret+"``"
    } else {
        return ""
    }
}

function ConvertTo-Markdown($data){       
    Write-Output "# Keymap"
    Write-Output ""

    $data | Group-Object -Property BindingContext | Sort-Object -Property Name| % {

        $group = $_.Group
        $name = $_.Name
        Write-Output "## $name"
        Write-Output ""
        Write-Output "Name | main shortcut | secondary shortcut"
        Write-Output "--- | --- | ---"
        $group | Group-Object -Property CommandName | Sort-Object -Property Name | % {
            $group = $_.Group
            $name = $_.Name
            $mainShortcut = Format-Shortcut -Data $group[0]
            $altShortcut = Format-Shortcut -Data $group[1]
            Write-Output "$name | $mainShortcut | $altShortcut"
        }
        Write-Output ""
    }
}

$data = Decode-Keymap-To-Json-Format -File ".\UnrealEngine-Keymap-Azerty.ini" | ConvertFrom-Json
ConvertTo-Markdown -data $data | Out-File ".\UnrealEngine-Keymap-Azerty.md"