
$path = "D:\MISC\FSMB\AdminShit\screendisplaymanager\"
# \\corellia\infoscreen
$csvname = "Auslaufdatum.csv"


$oldpath = ($path + ".old\")
$csvpath = ($path+$csvname)

function initCSV{
    param ()
    #Initialises a CSV in case none exists
    if(-Not(Test-Path -Path $csvpath)) {
        Set-Content $csvpath -Value ("dateiname,auslaufdatum`n"+$csvname+",3000-01-01")
        echo "Made CSV file"
    }
}

function shadowrealm{
    #Moves files to old with respect to duplicate names
    param ($filename)
    if(Test-Path -Path ($oldpath+$filename)){
        $suffix = 1
        while(Test-Path -Path ($oldpath+$filename+"_$suffix")){ $suffix++}
    } #In case of multiple files with the same name being moved into the old dir, suffix them to avoid overwrite
    Move-Item ($path+$filename) -Destination ($oldpath+$filename+"_$suffix")
    echo ("Shadowrealmed "+$filename)
}

initCSV("")
$filesTSE = @() #ThatShouldExist

$CSV = (Import-Csv -Path $csvpath | ForEach-Object {
    #Primary Check through CSV mentioned
    if(Test-Path -Path ($path+$_.dateiname)){ #Does the file exist?
        if((Get-Date -Date $_.auslaufdatum) -lt (Get-Date)) { #Is the expiration date reached?
            shadowrealm($_.dateiname) #Move to old
        }else{$_; $filesTSE+=$_.dateiname} #Add file name to list for double checking removable files
    }}) #Note that this automatically cleans the CSV for files removed or nonexistent

Get-ChildItem -Path $path | ForEach-Object {
    #Scan for removable files
    if(-Not ($filesTSE.Contains($_.name))){ #Is existing file mentioned in CSV?
        shadowrealm($_.name) #move to old if not
    }}

$CSV | Export-Csv -Path $csvpath -Force
#Rewrite CSV to mirror changes
