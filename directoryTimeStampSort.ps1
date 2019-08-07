# Sort Directory By Timestamp by Matthew Relph
# v 1.01
# Powershell Script Version
#
#
# Taking a directory full of files, and putting them in folders based on the date of their last modification
# Works good for lots of things, logs, pictures, piles of HL7 pharmacy requests, you name it!
# 
#
# Some error checking. Should stop and report to shell on any error
# As always, use at your own risk
# 
# 1st Argument = Source Path
# 2nd Argument = Destination Path
# 3rd Argument = Option Flags (-xxxx)
#
# Example use (In Powershell):
# scriptName Source Destination -xxxx
# &'C:\Users\MyUser\Documents\Projects\powershell scripts\directory sort\directoryTimeStampSort.ps1' 'C:\Users\MyUser\Documents\Projects\powershell scripts\directory sort\test\input' 'C:\Users\MyUser\Documents\Projects\powershell scripts\directory sort\test\output' -cnyo
#
# Possible future additions: Filter by extension



# Begin Functions
function PrintArgs($argsList)
{

    Write-Host "We are looking for 3 parameters. `n Argument #1 = Source Directory `n Argument #2 = Destination Directory `n Argument #3 = Options Flags"
    Write-Host "   -c = Copy to new directory only (Leaves Originals) `n   -v = Move to new directory"
    Write-Host "   -n = No prompts (overrides other options) `n   -p = Prompt at conflicts"
    Write-Host "   -y = Split By Year  `n   -m = Split By Month `n   -d = Split By Day "
    Write-Host "   -o = Default action is to overwrite on conflict `n   -x = Default action is to make a copy on conflict"
    Write-Host "   While you must pick options, combinations can include -cnyo, -vpdn, etc."
    Write-Host "`nThe correct syntax is `"scriptName Source Destination -xxxx`" `n"

    Write-Host "You passed $($argsList.length) arguments."
    for ($i=0; $i -lt $($argsList.length); $i++)
    {
        Write-Host "Arg#" ($i+1) ": $($argsList[$i])"
    }
}



function checkArgs($argsList,[REF]$promptFlag,[REF]$moveFlag,[REF]$sortBy, [REF]$continue, [REF]$overwriteFlag)
{
    
    
    #Need 3 arguments

    if ( $($argsList.length) -ne 3)
    {
        PrintArgs($argsList)
        $continue.Value = $FALSE
    }
    else
    {
        #Check options list
        $options = $($argsList[2])

        if (($options[0] -eq "-"))
        {
            #Write-Host "Options String init"
            $optionsFlag = $TRUE
            if 	(($options).Contains("c") -or ($options).Contains("C"))
            {
                $moveFlag.Value = $FALSE
            }
            if 	(($options).Contains("v") -or ($options).Contains("V"))
            {
                $moveFlag.Value = $TRUE
            }

            if 	(($options).Contains("n") -or ($options).Contains("N"))
            {
                $promptFlag.Value = $FALSE
            }

            if 	(($options).Contains("p") -or ($options).Contains("P"))
            {
                $promptFlag.Value = $TRUE
            }

            if 	(($options).Contains("d") -or ($options).Contains("D"))
            {
                $sortBy.Value = "d"
            }
            if 	(($options).Contains("m") -or ($options).Contains("M"))
            {
                $sortBy.Value = "m"
            }
            if 	(($options).Contains("y") -or ($options).Contains("Y"))
            {
                $sortBy.Value = "Y"
            }
            if 	(($options).Contains("y") -or ($options).Contains("Y"))
            {
                $sortBy.Value = "Y"
            }
            if 	(($options).Contains("o") -or ($options).Contains("O"))
            {
                $overwriteFlag.Value = $TRUE
            }
            if 	(($options).Contains("x") -or ($options).Contains("X"))
            {
                $overwriteFlag.Value = $FALSE
            }
        }
        else
        {
            #Write-Host "Options String fail" $options[0] $options.Length
            $optionsFlag = $FALSE
            $continue.Value = $FALSE
        }
        
        #Check Source Directory
        Write-Host "Source Directory: " $argsList[0]
        try 
        {
            if (Test-Path -Path $argsList[0] -PathType container)
            {
                Write-Host "    Source Path exists"
            }
            else
            {
                Write-Host "    Source Path does not exist - Cannot Continue"

                $continue.Value = $FALSE
            }
        }
        catch
        {
            Write-Host "ERROR: Reading source directory path " $argsList[0] 
            $Error[0].Exception
            Exit
			
        }
        
        #Check Destination Directory
        Write-Host "Destination Directory: " $argsList[1]
        try 
        {
            if (Test-Path -Path $argsList[1] -PathType container)
            {
                Write-Host "    Destination Path exists"
            }
            else
            {
                Write-Host "    Destination Path does not exist"
                if (-not (Test-Path -Path $argsList[1] -IsValid))
                {
                    Write-Host "    Destination Path is not valid - Cannot Continue"
                    $continue.Value = $FALSE
                }
                elseif ($continue.Value)
                {
                    $makeDir = "n"
                    if ($promptFlag.Value)
                    {
                        #Prompt to make the directory
                        $makeDir = Read-Host "    Attempt to make new directory `'" $argsList[1] "`'? (y/n)"
                    }
                    else
                    {
                        #Make the directory without the prompt, if prompts are turned off
                        $makeDir = "y"
                    }

                    if (($makeDir -eq "y") -or ($makeDir -eq "Y"))
                    {
                        Write-Host "    Making directory..."   
                        try
                        {
                            New-Item -ItemType directory -Path $argsList[1]                 
                        }
                        catch
                        {
                            Write-Host "ERROR: Creating new directory " $argsList[1] 
                        }
                    }
                    else
                    {
                        Write-Host "    Destination Path is not valid - Cannot Continue"
                        $continue.Value = $FALSE
                    }
                }
            }
        }
        catch
        {
            Write-Host "ERROR: Reading destination directory path " $argsList[1] 
            $Error[0].Exception
            Exit
        }
        Write-Host "Options: " $argsList[2]
        if (-not ($optionsFlag))
        {
            Write-Host "    Options not detected - Using Defaults"
        }
        Write-Host "    Move = " $moveFlag.Value
        Write-Host "    Prompt = " $promptFlag.Value
        Switch ($sortBy.Value)
        {
            "d" {Write-Host "    Sort By = Day"}
            "m" {Write-Host "    Sort By = Month"}
            "y" {Write-Host "    Sort By = Year"}
        }
        if ($overwriteFlag.Value)
        {
            Write-Host "    Default Action = Overwrite`n" 
        }
        else
        {
            Write-Host "    Default Action = Make Copy`n" 
        }
                
    }

}


function mainTask($sourcePath, $destinationPath, $promptFlag, $moveFlag, $sortBy, $overwriteFlag)
{
    Write-Host "Preparing to Copy..."
    #Get List of Files
    $fileCopyList = Get-ChildItem -Path $sourcePath -Force
   
    foreach ($copyFile in $fileCopyList)
    {
        #Get File Modified Date
        $fileDate = $copyFile.LastWriteTime | Get-Date -f "yyyy-MM-dd hh:mm"
        #Get year string and append to path
        $extendedDestinationPath = $destinationPath + "\" + $fileDate.substring(0, 4)

        if (($sortBy -eq "d") -or ($sortBy -eq "m"))
        {
           #Get month string and append to path
           $extendedDestinationPath = $extendedDestinationPath + "\" + $fileDate.substring(5, 2) 
        }
        if ($sortBy -eq "d")
        {
           #Get day string and append to path
           $extendedDestinationPath = $extendedDestinationPath + "\" + $fileDate.substring(8, 2) 
        }
        #Write-Host $extendedDestinationPath"\"$copyFile $copyFile.LastWriteTime
        
        $source = $sourcePath + "\" + $copyFile
        $destination = $extendedDestinationPath + "\" + $copyFile
        try
        {
            if (-not (Test-Path -Path $extendedDestinationPath -PathType container))
            {
                try
                {
                    New-Item -ItemType directory -Path $extendedDestinationPath
                }
                catch
                {
                    Write-Host "ERROR: Creating destination directory path " $extendedDestinationPath 
                    $Error[0].Exception
                    Exit
                }
            }  
        }
        catch
        {
            Write-Host "ERROR: Reading destination directory path " $extendedDestinationPath
            $Error[0].Exception
            Exit             
        }


        # Now we check if the file exists, and determine what we need to do on conflict
        $conflictFlag = $FALSE
        try 
        {
            if (Test-Path -Path $destination -PathType Leaf)
            {
                $conflictFlag = $TRUE
                # File already exists, we need to refer to the options to see what we do next
            }
        }
        catch
        {
             Write-Host "ERROR: Checking if destination file exists " $destination
            $Error[0].Exception
            Exit
        }

        # If prompts are on, we check with the user
        $overwriteNext = $overwriteFlag
        if ($conflictFlag -and $promptFlag)
        {
            $conflictAction = Read-Host "`"$destination`" already exists `nOverwrite or Make New Copy? (o/c)"
            if (($conflictAction -eq "o") -or ($conflictAction -eq "O"))
            {
                $overwriteNext = $TRUE
            }
            elseif (($conflictAction -eq "c") -or ($conflictAction -eq "C"))
            {
                $overwriteNext = $FALSE
            }
        }

        # During conflict If we choose to copy, we make a new copy with a unique file name, otherwise we continue on and overwrite the file
        if ($conflictFlag -and (-not $overwriteNext))
        {
            
            try
            {
                #Check if file already exists . We will keep up to 255 copies of files of the same name in the same directory. Beyond that, it is just ridiculous
                $fileVersion = 0
                while ((Test-Path -Path $destination -PathType Leaf) -and ($fileVersion -lt 255))
                {     
                    $destination = $extendedDestinationPath + "\" + "(" + $fileVersion  +")" + $copyFile 
                    $fileVersion = $fileVersion +1  
                } 
            }
            catch
            {
                Write-Host "ERROR: Checking if destination file exists " $destination 
                $Error[0].Exception
                Exit
            }
        }

        # Final file copy
        try
        {
            Copy-Item -Path $source  -Destination $destination
        }
        catch
        {
            Write-Host "ERROR: Copying file to destination directory " $destination 
            $Error[0].Exception
            Exit
        }


    }
    Write-Host "Copy Complete"

    # Remove source files if we are setup to move instead of just copy. 
    # Only remove files from the list we copied (Some files may have been added since we started)
    if ($moveFlag)
    {
        Write-Host "Removing Originals from Source Directory..."
        foreach ($removeFile in $fileCopyList)
        {
            $removeFilePath = $sourcePath + "\" + $removeFile
            try
            {
                Remove-Item -Path $removeFilePath
            }
            catch
            {
                Write-Host "ERROR: Removing Source File " $removeFilePath 
                $Error[0].Exception
                Exit
            }
        }
        Write-Host "Removals Complete"
    }
    Write-Host "Sorting Complete`nEnd Script`n"


}
# End functions

# Begin program
Clear-Host
Write-Host "This script organizes a directory of files into subdirectories by date. `nIt will move your files, if you have the proper permissions, so be careful!`n`n"

#Options Defaults - Least destructive options
$promptFlag = $TRUE
$moveFlag = $FALSE
$overwriteFlag = $FALSE
$sortBy = "d"

$continue = $TRUE



checkArgs $args ([REF]$promptFlag) ([REF]$moveFlag) ([REF]$sortBy) ([REF]$continue) ([REF]$overwriteFlag)

$startMove = ""

if ($promptFlag -and $continue)
{
    while (($startMove -ne "y") -and ($startMove -ne "Y") -and ($startMove -ne "n") -and ($startMove -ne "N"))
    {
        $startMove = Read-Host "Do you wish to continue? (y/n)"
    }

    if (($startMove -eq "n") -or ($startMove -eq "N"))
    {
        $continue = $FALSE
    }
}

if ($continue)
{
    mainTask $args[0] $args[1] $promptFlag $moveFlag $sortBy $overwriteFlag
}
else
{
    Write-Host "`n Cannot Continue`nEnd Script`n"
}

# End program
# End script
