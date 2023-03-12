<#
FileName: GroupUserChecker.ps1
Made by: Giancarlo Barrientes
Use Case: Instead of checking users one by one very tedious. This program will check samAccountNames and various formatted Naming schemes within a csv file and export another csv file 
that has the list of users Sam that are not in the group. 

Instructions: 
1. Change line 97: To "what ever group you want" that is in our AD
2. Change line 100: Set path for csv file you are going to use. Make sure headers are |UserFirstName|UserLastName|Name|  (Name will be in the SAM format Firstname.Lastname)
3. Change line 101: Change path and name of the file you want for output of csv containing individails that are not in the group

Number of sams of common formating, This can be changed per company enviroment by string manipulation.
$user.Name = firstname.lastname
$OldSam = FirstinitialLastname ex.GBarrientes
$ThirdSam = FirstnameLastInitial ex.GiancarloB
$FourthSam = LastnameFirstnameInitial ex.BarrientesG
#>
<#
Run this segment to run on local machine must have Rsat tools and admin level permissions on AD
New-PSDrive -Name AD -PSProvider ActiveDirectory -Server "DomainController.Domain.com" -Scope Global -root "//RootDSE/"
Set-Location AD:
DIR
#>


Import-module ActiveDirectory

Function CompareGroupstoCSV ([System.String]$GroupName, [System.String] $CSVFileINPath, [System.String] $CSVFileOutPath)
{	

	#This grabs the group memebers samaccountname from the group you want
	$members = Get-ADGroupMember -Identity $GroupName | Select-Object -ExpandProperty sAMAccountName
	$UserInfoFromCsv = import-csv $CSVFilePath
	#This for loop will compare the variables with cn to members to see if user is in the 
	ForEach ($user in $UserInfoFromCsv)
	{	
		
		#Checks to see if the user is in the list of members in the group
		If ($members -contains $user.Name)
		{
			Write-Host "$($user.Name) does exists in the group"
		}
	
		#Goes to second check Converts new Sam to Old Sam and then checks to see if if the groupmember list is matched with the oldSam
		if ($members -notcontains $user.Name)
		{
			$firstInitial = $user.UserFirstName.Substring(0, 1)
			$LastName = $user.UserLastName
			$OldSam = $($firstInitial).ToLower().Replace(" ", "") + $($LastName).ToLower().Replace(" ", "")	
			#Another if to check if old school sam account is used
			if ($members -contains $OldSam)
			{
				Write-Host "$($user.Name) does exists in the group"
			}
		}
		#Goes through the third check to see another sam account name firstnameLastinitial ex. GiancarloB
		if (($members -notcontains $OldSam) -and ($members -notcontains $user.Name))
		{
			$FirstName = $user.UserFirstName
			$lastnameInitial = $user.UserLastName.Substring(0, 1)
			$ThirdSam = $($FirstName).ToLower().Replace(" ", "") + $($lastnameInitial).ToLower().Replace(" ", "")
			if ($members -contains $ThirdSam)
			{
				Write-Host "$($user.Name) does exists in the group"
			}
		}
		#Goes through the fourth check to see another sam account name LastnameFirstinitial ex. GiancarloB
		if (($members -notcontains $OldSam) -and ($members -notcontains $user.Name) -and ($members -notcontains $ThirdSam))
		{
			$LastName = $user.UserLastName
			$firstInitial = $user.UserFirstName.Substring(0, 1)
			$FourthSam = $($LastName).ToLower().Replace(" ", "") + $($firstInitial).ToLower().Replace(" ", "")
			if ($members -contains $FourthSam)
			{
				Write-Host "$($user.Name) does exists in the group"
			}
		}
	
		#Once confirmed user is not in group write them out to the output.csv file
		#if statement checke the oldsam and the new sam account names. 
		if(($members -notcontains $OldSam) -and ($members -notcontains $user.Name) -and ($members -notcontains $ThirdSam) -and ($members -notcontains $FourthSam))
		{
			Write-Host "$($user.Name) does not exists in the group"
			$user.Name | ForEach-Object { [PSCustomObject] @{ SamAccountName = $_ } } | Export-Csv -Path $CSVFileOutPath -Append
		}
	}
}#Function CompareGroupstoCSV end

#Name of group you want query 
<#
USE these attributes that the Get-ADGroupMember -Identity
A distinguished name
A GUID (objectGUID)
A security identifier (objectSid)
A Security Account Manager account name (sAMAccountName)
#>
$groupToCheck = "GroupName"
#csv file that has users you want to check make certain the 
###CSV header is as follows FirstName, LastName, Name(FirstName.LastName)####
$CSVInputPath = "C:\PathTo\Example Input.csv"
$CSVOutPutPath = "C:\PathTo\Output.csv"
CompareGroupstoCSV -GroupName $groupToCheck -CSVFilePath $CSVInputPath -CSVFileOutPath $CSVOutPutPath
