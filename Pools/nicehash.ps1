if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

try {
    $Request = Invoke-ProxiedWebRequest "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" | ConvertFrom-Json 
    $RequestAlgodetails = Invoke-ProxiedWebRequest "https://api2.nicehash.com/main/api/v2/mining/algorithms/" | ConvertFrom-Json 
}
catch { return }

if (-not $Request -or -not $RequestAlgodetails) {return}

$Request.miningAlgorithms | foreach {$Algo = $_.Algorithm ; $_ | Add-Member -force @{algodetails = $RequestAlgodetails.miningAlgorithms | ? {$_.Algorithm -eq $Algo}}}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Fees = 5

# Placed here for Perf (Disk reads)
    $ConfName = if ($Config.PoolsConfig.$Name -ne $Null){$Name}else{"default"}
    $PoolConf = $Config.PoolsConfig.$ConfName


    $Request.miningAlgorithms| ? { [Double]$_.paying -gt 0 } | ForEach-Object {
        $Algo = $_.Algorithm
        $NiceHash_Port = $_.algodetails.port
        $NiceHash_Algorithm = Get-Algorithm $_.Algorithm
        $NiceHash_Coin = ""

        $DivisorMultiplier = 100000
        $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.marketFactor
        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($Name)_$($NiceHash_Algorithm)_Profit" -Value ([Double]$_.paying  / $Divisor * (1 - ($Fees / 100)))

$Locations = "eu", "usa", "hk", "jp", "in", "br"
$Locations | ForEach-Object {
        $NiceHash_Location = $_
        
        switch ($NiceHash_Location) {
            "eu"    {$Location = "EU"}
            "usa"   {$Location = "US"}
            "jp"    {$Location = "JP"}
            "hk"    {$Location = "JP"}
            "in"    {$Location = "JP"}
            # "br"    {$Location = "US"}
        }
        $NiceHash_Host = "$($Algo).$($NiceHash_Location).nicehash.com"

        if ($PoolConf.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat."Minute_5"*$PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $false
            }

            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat."Minute_5"*$PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+ssl"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $true
            }
        }
    }
}
