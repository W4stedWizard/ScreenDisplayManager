
$path = "\\corellia\infoscreen\"
# D:\MISC\FSMB\AdminShit\screendisplaymanager\
# \\corellia\infoscreen
$csvname = "Auslaufdatum.csv"


$oldpath = ($path + ".old\")
$csvpath = ($path+$csvname)

function initCSV{
    param ()

    if(-Not(Test-Path -Path $oldpath)) {
        New-Item -Path $oldpath -Type "directory"
        echo "Made .old folder"
    }#Initialises a .old in case none exists
    if(-Not(Test-Path -Path $csvpath)) {
        Set-Content $csvpath -Value ("dateiname,auslaufdatum`n"+$csvname+",3000-01-01")
        echo "Made CSV file"
        exit
    }#Initialises a CSV in case none exists

}

function shadowrealm{
    #Moves files to old with respect to duplicate names
    param ($filename)
    if(Test-Path -Path ($oldpath+$filename)){
        $suffix = 1
        while(Test-Path -Path ($oldpath+$filename+"_$suffix")){ $suffix++}
        $suffix="_$suffix"
    } #In case of multiple files with the same name being moved into the old dir, suffix them to avoid overwrite
    Move-Item ($path+$filename) -Destination ($oldpath+$filename+$suffix)
    echo ("Shadowrealmed "+$filename)
    if($filename -eq $csvname){
        #Just shadowrealmed my anchor CSV. Very high change of something being VERY WRONG HOLY SHIT
        initCSV("") #Saved the general structure - but any data content is still lost. Notify admins.
        #TODO    INSERT WEBHOOK NOTIF HERE
        exit
    }
}

initCSV("")
$filesTSE = @() #ThatShouldExist

$CSV = (Import-Csv -Path $csvpath | ForEach-Object {
    #Primary Check through CSV mentioned
    if(Test-Path -Path ($path+$_.dateiname)){ #Does the file exist?
        try {
            if ((Get-Date -Date $_.auslaufdatum) -lt (Get-Date)) {#Is the expiration date reached?
                shadowrealm($_.dateiname) #Move to old
            }
            else {$_; $filesTSE += $_.dateiname } #Add file name to list for double checking removable files
        }
        catch{
            echo "DateParseException?"
            #Notify Webhook Service
        }
    }}) #Note that this automatically cleans the CSV for files removed or nonexistent

Get-ChildItem -Path $path -File | ForEach-Object {
    #Scan for removable files
    if(-Not ($filesTSE.Contains($_.name))){ #Is existing file mentioned in CSV?
        shadowrealm($_.name) #move to old if not
    }}

$CSV | Export-Csv -Path $csvpath -Force
#Rewrite CSV to mirror changes
