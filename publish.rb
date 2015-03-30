#!/usr/bin/env ruby

#change those according to your project settings

$workspaceName = 'camera.xcworkspace'
$schemeName = 'camera'
$releaseProvisioningProfileName = 'XC Ad Hoc: com.imaginarycloud.*'
$nameOfTheSimulatorToTest = 'iPad Retina'
	

#you can create API key here: https://rink.hockeyapp.net/manage/auth_tokens

$hockeyAppApiKey = '7d8cbb78027a4263b6bb7644a33a9491'





# The rest will just do the magic for you :-)

def build()
 	putStatusInBlue('BUILDING')

	removeOldFiles
	if buildFromIpaBuild then
    	putStatusInGreen('SUCESS')
	else
		putStatusInRed('FAILED, TRYING XCODEBUILD')

		if buildFromXcodeBuild then
    		putStatusInGreen('SUCESS')

 			putStatusInBlue('UPLOADING TO HOCKEYAPP')

			system('ipa distribute:hockeyapp -a ' + $hockeyAppApiKey + ' -d ' + $dsymZippedName)
		else
			putStatusInRed('EVERYTHING FAILED')
		end
	end
end
 	
def buildFromIpaBuild()
 	putStatusInBlue('BUILDING WITH IPA BUILD')

	if system('ipa build -m "' + $releaseProvisioningProfileName + '" --workspace ' + $workspaceName + '" --scheme ' + $schemeName) then
		system('ipa distribute:hockeyapp -a ' + $hockeyAppApiKey)
		return true
	else
		return false
	end
end

def buildFromXcodeBuild()

 	putStatusInBlue('BUILDING WITH XCODEBUILD')

 	if system('xcodebuild clean archive -workspace ' + $workspaceName + ' -scheme ' + $schemeName + ' -archivePath ' + $archivePath) then
 		putStatusInBlue('EXPORTING IPA')
 		
 		if system('xcodebuild -exportArchive -archivePath ' + $archivePath + ' -exportPath ' + $schemeName + ' -exportFormat ipa -exportProvisioningProfile "' + $releaseProvisioningProfileName + '"') then

			system('zip -r ' + $dsymZippedName + ' ' + $dsymPath)
			return true
		else
			return false
		end
	else
		return false
	end
end

def removeOldFiles()
	if system('test -d ' + $archivePath) then 
	 	putStatusInBlue('REMOVING OLD ARCHIVE FILE')
		system('rm -R' + $archivePath)
	end
	if system('test -f ' + $schemeName + '.ipa') then 
	 	putStatusInBlue('REMOVING OLD IPA FILE')
		system('rm ' + $schemeName + '.ipa')
	end
	if system('test -f ' + $dsymZippedName) then 
	 	putStatusInBlue('REMOVING OLD DSYM FILE')
		system('rm ' + $dsymZippedName)
	end
end

def putStatusInRed(status)
	puts " "
	puts ">>>>>>>>  ".red + status.red + "  <<<<<<<<".red
	puts " "
end

def putStatusInBlue(status)
	puts " "
	puts ">>>>>>>>  ".blue + status.blue + "  <<<<<<<<".blue
	puts " "
end

def putStatusInGreen(status)
	puts " "
	puts ">>>>>>>>  ".green + status.green + "  <<<<<<<<".green
	puts " "
end

class String
	def red;            "\033[31m#{self}\033[0m" end
	def green;          "\033[32m#{self}\033[0m" end
	def blue;           "\033[34m#{self}\033[0m" end
end


$archivePath = $schemeName + '.xcarchive'
$dsymZippedName = $schemeName + '.app.dSYM.zip'
$dsymPath = $archivePath + '/dSYMs/' + $schemeName + '.app.dSYM'

putStatusInBlue('TESTING')

if system('xctool -workspace ' + $workspaceName + ' -scheme ' + $schemeName + ' -sdk iphonesimulator test') then
	build
else
	putStatusInRed('XCTOOL FAILED - TRYING XCODEBUILD')

	if system('xcodebuild clean test -scheme ' + $schemeName + ' -workspace ' + $workspaceName + ' -destination \'platform=iOS Simulator,name=' + $nameOfTheSimulatorToTest + '\'') then
		build
	else
		putStatusInRed('XCODEBUILD TEST FAILED')
	end
end




