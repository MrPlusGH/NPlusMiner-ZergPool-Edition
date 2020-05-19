<#
This file is part of NPlusMiner
Copyright (c) 2018-2019 MrPlus

NPlusMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NPlusMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NPlusMiner
File:           Charting.ps1
version:        5.4.1
version date:   20190809
#>


param(
    [Parameter(Mandatory=$True)]
    [String]$Chart = "", 
    [Parameter(Mandatory=$true)]
    [String]$Width = 700, 
    [Parameter(Mandatory = $true)]
    [String]$Height = 85, 
    [Parameter(Mandatory = $false)]
    [String]$Currency = "BTC" 
)

Function GetNextColor {
    param(
        [Parameter(Mandatory = $true)]
        [String]$BaseColorHex,
        [Parameter(Mandatory = $true)]
        [Int]$Factor
    )
    # Convert to RGB
    $R = [convert]::ToInt32($BaseColorHex.Substring(0,2),16)
    $G = [convert]::ToInt32($BaseColorHex.Substring(2,2),16)
    $B = [convert]::ToInt32($BaseColorHex.Substring(4,2),16)
    # Apply change Factor
    $R = $R + $Factor
    $G = $G + $Factor
    $B = $B + $Factor
    # Convert to Hex
    $R = If (([convert]::Tostring($R,16)).Length -eq 1) {"0$([convert]::Tostring($R,16))"} else {[convert]::Tostring($R,16)}
    $G = If (([convert]::Tostring($G,16)).Length -eq 1) {"0$([convert]::Tostring($R,16))"} else {[convert]::Tostring($G,16)}
    $B = If (([convert]::Tostring($B,16)).Length -eq 1) {"0$([convert]::Tostring($R,16))"} else {[convert]::Tostring($B,16)}
    $R+$G+$B
}

function Get-ColorPalette {
    param($StartColor,$EndColor,$n)$x=$StartColor -split '(..)' -ne '' 
    $StartColor
    ++$n..1|%{
        $j=$_
        -join($x=$x|%{
            "{0:x2}"-f(+"0x$_"-[int]((+"0x$_"-"0x$(($EndColor -split '(..)' -ne '')[$i++%3])")/$j))
        })
    }
}

[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition

# Defined Charts list
    # Front7DaysEarnings
    # FrontDayEarningsPoolSplit
    # DayPoolSplit

Switch ($Chart) {
    "Front7DaysEarnings" {
           $datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) {Import-Csv ".\logs\DailyEarnings.csv" | ? {[DateTime]$_.date -ge (Get-Date).AddDays(-7)}}
           $datasource = $datasource | select *,@{Name="DaySum";Expression={$Date = $_.date;(($datasource | ? {$_.date -eq $Date}).DailyEarnings | measure -sum).sum }}
         
           $chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
           $chart1.Width = $Width
           $chart1.Height = $Height
          
           # $chart1.BackColor = [System.Drawing.Color]::White
           $chart1.BackColor = "#F0F0F0"
         
        # title 
           # [void]$chart1.Titles.Add("This is the Chart Title")
           # $chart1.Titles[0].Font = "Arial,13pt"
           # $chart1.Titles[0].Alignment = "topLeft"
         
           $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
           $chartarea.Name = "ChartArea1"
           $chartarea.BackColor = "#2B3232"
           # $chartarea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
           $chartarea.BackSecondaryColor = "#777E7E"
           $chartarea.BackGradientStyle  = 3
           $chartarea.AxisX.labelStyle.Enabled = $False
           $chartarea.AxisX.Enabled = 2
           $chartarea.AxisX.MajorGrid.Enabled = $False
           $chartarea.AxisY.MajorGrid.Enabled = $True
           $chartarea.AxisY.MajorGrid.LineColor = "#FFFFFF"
           $chartarea.AxisY.MajorGrid.LineColor = "#777E7E"
           $chartarea.AxisY.labelAutoFitStyle = $chartarea.AxisY.labelAutoFitStyle - 4
           # $chartarea.AxisY.IntervalAutoMode = 0
           $chartarea.AxisY.Interval = [math]::Round(($datasource | group date | % {($_.group.DailyEarnings | measure -sum).sum} | measure -maximum).maximum *1000 / 4, 1)
           $chart1.ChartAreas.Add($chartarea)
         
           $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
           $legend.name = "Legend1"
           # $chart1.Legends.Add($legend)
         
        # $BaseColor = "424B54"
        $BaseColor = "FFFFFF"
        # $BaseColor = "F7931A"
        $StartColor = "FFFFFF"
        $EndColor = "f2a900"
        $i=0
        # $Colors = Get-ColorPalette $StartColor $EndColor (($datasource | sort DaySum -Unique).DaySum | % {[math]::Round($_*1000, 3)} | sort -Unique).count
        $Colors = Get-ColorPalette $StartColor $EndColor 100

           [void]$chart1.Series.Add("Total")
           $chart1.Series["Total"].ChartType = "Column"
           $chart1.Series["Total"].BorderWidth  = 3
           # $chart1.Series[$Pool].IsVisibleInLegend = $true
           $chart1.Series["Total"].chartarea = "ChartArea1"
           # $chart1.Series[$Pool].Legend = "Legend1"
           # $chart1.Series[$Pool].color = "#E3B64C"
           $chart1.Series["Total"].color = "#f2a900"
           # $chart1.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
           $chart1.Series["Total"].label = "#VALY{N3}"
           $chart1.Series["Total"].LabelForeColor = "#FFFFFF"
           $chart1.Series["Total"].ToolTip = "#VALX: #VALY" # - Total: #TOTAL mBTC";
           # $datasource | select Date,DaySum -Unique | ForEach-Object {$chart1.Series["Total"].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DaySUm*1000))) | Out-Null }
           $datasource | select Date,DaySum -Unique | ForEach-Object {$chart1.Series["Total"].Points.addxy( $_.Date , (([Decimal](Get-DisplayCurrency $_.DaySum).Value))) | Out-Null }

           $Chart1.Series | foreach {$_.CustomProperties = "DrawSideBySide=True"}
           Try{
               $Chart1.Series["Total"].Points | ForEach-Object {
                    # $PSItem.Color = "#$($Colors[((($datasource | sort DaySum -Unique).DaySum | % {[math]::Round($_*1000, 3)} | sort -Unique)).IndexOf([math]::Round(($PSItem.YValues[0]), 3))])"
                    $PSItem.Color = "#$($Colors[[Int](100 * ($PSItem.YValues[0]) / (($datasource | group date | % {($_.group.DailyEarnings | measure -sum).sum} | measure -maximum).maximum * 1000))])"
                }
            } Catch {}
    }
    "Front7DaysEarningsWithPoolSplit" {
           $datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) {Import-Csv ".\logs\DailyEarnings.csv" | ? {[DateTime]$_.date -ge (Get-Date).AddDays(-7)}}
           $datasource = $datasource | select *,@{Name="DaySum";Expression={$Date = $_.date;(($datasource | ? {$_.date -eq $Date}).DailyEarnings | measure -sum).sum }}
         
           $chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
           $chart1.Width = $Width
           $chart1.Height = $Height
          
           # $chart1.BackColor = [System.Drawing.Color]::White
           $chart1.BackColor = "#F0F0F0"
         
           $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
           $chartarea.Name = "ChartArea1"
           $chartarea.BackColor = "#2B3232"
           # $chartarea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
           $chartarea.BackSecondaryColor = "#777E7E"
           $chartarea.BackGradientStyle  = 3
           $chartarea.AxisX.labelStyle.Enabled = $False
           $chartarea.AxisX.Enabled = 2
           $chartarea.AxisX.MajorGrid.Enabled = $False
           $chartarea.AxisY.MajorGrid.Enabled = $True
           $chartarea.AxisY.MajorGrid.LineColor = "#FFFFFF"
           $chartarea.AxisY.labelAutoFitStyle = $chartarea.AxisY.labelAutoFitStyle - 4
           # $chartarea.AxisY.IntervalAutoMode = 0
           $chartarea.AxisY.Interval = [math]::Round(($datasource | group date | % {($_.group.DailyEarnings | measure -sum).sum} | measure -maximum).maximum *1000 / 4, 3)
           $chart1.ChartAreas.Add($chartarea)
         
        # legend 
           $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
           $legend.name = "Legend1"
           # $chart1.Legends.Add($legend)
         
        # $BaseColor = "424B54"
        $BaseColor = "FFFFFF"
        # $BaseColor = "F7931A"
        $Color = $BaseColor
        $A=255
        Foreach ($Pool in ($datasource.Pool | sort -unique)) {
            $A=$A-20
            $Color = GetNextColor -BaseColorHex $Color -Factor -10

           [void]$chart1.Series.Add($Pool)
           $chart1.Series[$Pool].ChartType = "StackedColumn"
           $chart1.Series[$Pool].BorderWidth  = 3
           # $chart1.Series[$Pool].IsVisibleInLegend = $true
           $chart1.Series[$Pool].chartarea = "ChartArea1"
           # $chart1.Series[$Pool].Legend = "Legend1"
           # $chart1.Series[$Pool].color = "#E3B64C"
           $chart1.Series[$Pool].color = "#$($Color)"
           # $chart1.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
           # $chart1.Series[$Pool].label = "#VALY"
           $chart1.Series[$Pool].ToolTip = "#SERIESNAME: #VALY" # - Total: #TOTAL mBTC";
           $datasource | ? {$_.Pool -eq $Pool} | ForEach-Object {$chart1.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f (([Decimal](Get-DisplayCurrency $_.DailyEarnings).Value)))) | Out-Null }
        }

           [void]$chart1.Series.Add("Total")
           $chart1.Series["Total"].ChartType = "Column"
           $chart1.Series["Total"].BorderWidth  = 3
           # $chart1.Series[$Pool].IsVisibleInLegend = $true
           $chart1.Series["Total"].chartarea = "ChartArea1"
           # $chart1.Series[$Pool].Legend = "Legend1"
           # $chart1.Series[$Pool].color = "#E3B64C"
           $chart1.Series["Total"].color = "#FFFFFF"
           # $chart1.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
           # $chart1.Series[$Pool].label = "#VALY"
           $chart1.Series["Total"].ToolTip = "#SERIESNAME: #VALY" # - Total: #TOTAL mBTC";
           $datasource | select Date,DaySum -Unique | ForEach-Object {$chart1.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f (([Decimal](Get-DisplayCurrency $_.DailyEarnings).Value)))) | Out-Null }

            $Chart1.Series | foreach {$_.CustomProperties = "DrawSideBySide=True"}
    }
    "DayPoolSplit" {
           $datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) {Import-Csv ".\logs\DailyEarnings.csv" | ? {[datetime]$_.date -ge [datetime](Get-Date).date.AddDays(-1).ToString("MM/dd/yyyy")}}
           # $datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) {Import-Csv ".\logs\DailyEarnings.csv" }
           $dataSource | % {$_.DailyEarnings = [Decimal]$_.DailyEarnings}
           $datasource = $dataSource | ? {$_.DailyEarnings -gt 0} | sort DailyEarnings #-Descending
         
           $chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
           $chart1.Width = $Width
           $chart1.Height = $Height
          
           # $chart1.BackColor = [System.Drawing.Color]::White
           $chart1.BackColor = "#F0F0F0"
         
           $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
           $chartarea.Name = "ChartArea1"
           $chartarea.BackColor = "#2B3232"
           # $chartarea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
           $chartarea.BackSecondaryColor = "#777E7E"
           $chartarea.BackGradientStyle  = 3
           $chartarea.AxisX.labelStyle.Enabled = $False
           $chartarea.AxisX.Enabled = 2
           $chartarea.AxisX.MajorGrid.Enabled = $False
           $chartarea.AxisY.MajorGrid.Enabled = $True
           $chartarea.AxisY.MajorGrid.LineColor = "#FFFFFF"
           $chartarea.AxisY.MajorGrid.LineColor = "#777E7E"
           $chartarea.AxisY.labelAutoFitStyle = $chartarea.AxisY.labelAutoFitStyle - 4
           # $chartarea.AxisY.IntervalAutoMode = 0
           $chartarea.AxisY.Interval = [math]::Round(($datasource | group date | % {($_.group.DailyEarnings | measure -sum).sum} | measure -maximum).maximum *1000 / 4, 1)
           $chart1.ChartAreas.Add($chartarea)
         
        # legend 
           $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
           $legend.name = "Legend1"
           # $chart1.Legends.Add($legend)
         
        # $BaseColor = "424B54"
        $BaseColor = "FFFFFF"
        # $BaseColor = "F7931A"
        # $StartColor = "FFFFFF"
        $StartColor = "FFFFFF"
        $EndColor = "f2a900"
        $i=0
        $Colors = Get-ColorPalette $StartColor $EndColor ($datasource.Pool | select -Unique).count
        Foreach ($Pool in ($datasource.Pool | select -Unique)) {
           $i++

           [void]$chart1.Series.Add($Pool)
           $chart1.Series[$Pool].ChartType = "StackedColumn"
           $chart1.Series[$Pool].BorderWidth  = 1
           # $chart1.Series[$Pool].BorderColor  = "#2B3232"
           $chart1.Series[$Pool].BorderColor  = [System.Drawing.Color]::Transparent
           # $chart1.Series[$Pool].IsVisibleInLegend = $true
           $chart1.Series[$Pool].chartarea = "ChartArea1"
           # $chart1.Series[$Pool].Legend = "Legend1"
           # $chart1.Series[$Pool].color = "#E3B64C"
           $chart1.Series[$Pool].color = "#$($Colors[$i])"
           # $chart1.Series[$Pool].color = "#FFFFFF"
           # $chart1.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
           # $chart1.Series[$Pool].label = "#SERIESNAME: #VALY mBTC"
           $chart1.Series[$Pool].ToolTip = "#VALX - #SERIESNAME: #VALY" # - Total: #TOTAL mBTC";
           $datasource | ? {$_.Pool -eq $Pool} | Sort date | ForEach-Object {$chart1.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f (([Decimal](Get-DisplayCurrency $_.DailyEarnings).Value)))) | Out-Null }
           # $Chart1.Series["Data"].Points.DataBindXY($datasource.pool, $datasource.DailyEarnings)
        }
    }
}

# save chart
   $chart1.SaveImage(".\Logs\$($chart).png","png") | Out-Null
   $chart1
