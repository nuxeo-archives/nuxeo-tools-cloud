$RegKey = ([Microsoft.Win32.Registry]::LocalMachine).OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $True) 
$PathValue = $RegKey.GetValue("Path", $Null, "DoNotExpandEnvironmentNames") 
Write-host "Original path :" + $PathValue  
$PathValues = $PathValue.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries) 
$IsDuplicate = $False 
$NewValues = @() 
  
ForEach ($Value in $PathValues) 
{ 
    if ($NewValues -notcontains $Value) 
    { 
        $NewValues += $Value 
    } 
    else 
    { 
        $IsDuplicate = $True 
    } 
} 
  
if ($IsDuplicate) 
{ 
    $NewValue = $NewValues -join ";" 
    $RegKey.SetValue("Path", $NewValue, [Microsoft.Win32.RegistryValueKind]::ExpandString) 
    Write-Host "Duplicate PATH entry found and new PATH built removing all duplicates. New Path :" + $NewValue 
} 
else 
{ 
    Write-Host "No Duplicate PATH entries found. The PATH will remain the same." 
} 
  
$RegKey.Close() 
