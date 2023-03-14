# Gets Currency rate for a given date from BNB website
# If there is no info for the date probably it's a holiday day 
# then it searches back for the most recent date
#
# Tested on PowerShell 5.1
param(
[Parameter(Mandatory=$true)]
[ValidateRange(0, 31)]
[int]$day, 

[Parameter(Mandatory=$true)]
[ValidateRange(0, 12)]
[int]$month, 

[Parameter(Mandatory=$true)]
[ValidateRange(1990, 2099)]
[int]$year, 

[string]$currency = "USD")

$result = $null

$date = Get-Date -Day $day -Month $month -Year $year
$daysBack = 0
do {
	$r = Invoke-WebRequest "https://www.bnb.bg/Statistics/StExternalSector/StExchangeRates/StERForeignCurrencies/index.htm?downloadOper=&group1=second&periodStartDays=$($date.Day)&periodStartMonths=$($date.Month)&periodStartYear=$($date.Year)&periodEndDays=$($date.Day)&periodEndMonths=$($date.Month)&periodEndYear=$($date.Year)&valutes=$($currency)&search=true"
	$result = $r.RawContent.Split([environment]::newline) | ?{$_.contains('<td class="first center">') -or $_.contains('<td class="last center">')}
	$date -= new-object timespan -ArgumentList @(1,0,0,0)
	$daysBack++
} while (!$result -and $daysBack -lt 10)

[PSCustomObject]@{
	Date = $result[0].trimstart('<td class="first center">').trimend('</td>')
	Rate = $result[1].trimstart('<td class="last center">').trimend('</td>')
}