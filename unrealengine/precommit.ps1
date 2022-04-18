$title = "
# UnrealEngine-Keymap-Azerty

Qwerty shortcuts fixed for Azerty keyboard
keymap is Based on https://www.youtube.com/watch?v=jGDDEMGOk-c And some fixes are added.
Non-destructive Blender-shortcuts are added.

"

$mapping = @{
    "OpenBracket"="{";
    "CloseBracket"="}";
    "Quote"='"';
}

function ConvertFrom-IniEscaping($content){
    foreach ($map in $mapping.GetEnumerator()) {
        $content = $content.replace("~$($map.Name)~", $map.Value)
    }
    Write-output $content
}
  
function ConvertFrom-UEKeymap($File){
    get-content $File | Where { $_.StartsWith("UserDefinedChords=")} | % { $_.substring(18) } | %{
        $decoded = ConvertFrom-IniEscaping -content $_ | ConvertFrom-Json
        $shortcut = Format-Shortcut -Data $decoded
        $CanonicalName = "$($decoded.BindingContext).$($decoded.CommandName)[$($decoded.ChordIndex)]=$shortcut"
        $decoded | Add-Member -NotePropertyName "Raw" -NotePropertyValue "UserDefinedChords=$_"
        $decoded | Add-Member -NotePropertyName "CanonicalName" -NotePropertyValue $CanonicalName
        Write-Output $decoded
    }
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
        return "``undefined``"
    }
}

function ConvertTo-Markdown($data){       
    Write-Output $title
    Write-Output ""

    $data | Group-Object -Property BindingContext | Sort-Object -Property Name | % {

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

function ConvertTo-Commented($data) {
    Write-Output "[UserDefinedChords]"
    $data | Sort-Object -Property CanonicalName | % {
        Write-Output "; $($_.CanonicalName)"
        Write-Output $_.Raw
    } 
    Write-Output ""
    Write-Output ""
}

$data = ConvertFrom-UEKeymap -File ".\UnrealEngine-Keymap-Azerty.ini"
ConvertTo-Markdown -data $data | Out-File ".\README.md"
ConvertTo-Commented -data $data | Out-File ".\UnrealEngine-Keymap-Azerty.ini"

