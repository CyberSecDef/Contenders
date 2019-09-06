[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $count = 30,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $statMin = 10,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $statMax = 19,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $totalAllowedPoints = 45,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $tax,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $loop,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $wallpaper,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $storyTellingMode,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $details,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $career
)
Begin{
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Windows.Forms.DataVisualization
	
	$global:count = $count
	$global:statMin = $statMin
	$global:statMax = $statMax
	$global:totalAllowedPoints = $totalAllowedPoints
	$global:loop = $loop
	$global:wallpaper = $wallpaper
	$global:storyTellingMode = $storyTellingMode
	$global:details = $details
	$global:tax = $tax;
	$global:career = $career;
	clear

	Class Chart{
		$Chart 		= (New-object System.Windows.Forms.DataVisualization.Charting.Chart);
		$ChartArea 	= (New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea);
		$ChartTypes = (new-object System.Windows.Forms.DataVisualization.Charting.SeriesChartType);
		$points 	= @()
		$game		= $null;
		
		Chart(){
			$this.points = @();
			$this.Chart.Width = 1920
			$this.Chart.Height = 1080
			$this.Chart.Left = 10
			$this.Chart.Top = 10
			$this.Chart.BackColor = iex "[System.Drawing.Color]::White"
			$this.Chart.BorderColor = 'Black'
			$this.Chart.BorderDashStyle = 'Solid'
			$this.Chart.Titles.Add( "PowerShell Battle Arena" )
			$this.chart.Titles[0].Font = "Arial,16pt"
			$this.chart.Titles[0].Alignment = "topCenter"
		}
		
		[void]render($game){
			
			$game.tellStory("Rendering the timeline chart.")
			
			$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
			$legend.name = "Contenders"
			$legend.font = "Courier New, 8pt"
			$legend.TextWrapThreshold = 100;
			$this.chart.Legends.Add($legend)
			   
			for($i = 0; $i -lt $global:count; $i++){
				if($global:details){
					$game.tellStory("Adding $($game.contenders[$i].name)  battle run to the chart.")
				}
				
				$Series = New-Object -TypeName System.Windows.Forms.DataVisualization.Charting.Series
				
				$cName = ""
				if($game.contenders[$i].credits -gt 0){
					$cName = "* "
				}
				$cName += $game.contenders[$i].name
				
				$Series.name = "{0,13} - [Wins: {1,5}, Tribe: {2,2}, Credits: {3,2}, STR: {4,2}, CONS: {5,2}, DEX: {6,2}]" -f $cName, $($game.contenders[$i].wins), $($game.contenders[$i].tribe), $($game.contenders[$i].credits), $($game.contenders[$i].str), $($game.contenders[$i].cons), $($game.contenders[$i].dex) 				
				
				
				$this.Chart.Series.Add($Series)
				$Series.ChartType = $this.ChartTypes::StackedArea


				$indexes = @()
				$credits = @()

				$this.points | ? { $_.citizen -eq $game.contenders[$i].name} | sort { $_.index }  | % {
					$indexes += $_.index;
					$credits += $_.credits;
				}
				$series.Points.DataBindXY($indexes, $credits) | out-null
			}

			$this.chartarea.axisy.maximum= ( 5 * $global:count)
			$this.chartarea.axisy.Title = "Credits"
			$this.chartarea.axisx.Title = "Battles"
			
			
			$this.Chart.ChartAreas.Add($this.ChartArea)
			$filename = ( "$($pwd)\ContendersChart_$( $game.startTime ).png" )
			$this.Chart.SaveImage($fileName, "PNG")
			if($global:wallpaper){
				if($global:details){
					$game.tellStory("Updating the desktop background.")
				}
				[UI]::updateWallpaper($filename)
			}
		}
		
	}
	
	Class UI{
		
		UI(){
			
		}
		
		
		
		static [void] updateWallpaper( [String]$path){
			Try {
				if (-not ([System.Management.Automation.PSTypeName]'Wallpaper.Setter').Type) {
					Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper {
	public enum Style : int {
		Center, Stretch, Fill, Fit, Tile
	}
	public class Setter {
		public const int SetDesktopWallpaper = 20;
		public const int UpdateIniFile = 0x01;
		public const int SendWinIniChange = 0x02;
		[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
		private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
		public static void SetWallpaper ( string path ) {
			SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
			RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
			
			key.SetValue(@"WallpaperStyle", "6") ; 
			key.SetValue(@"TileWallpaper", "0") ; 
			key.Close();
		}
	}
}
"@ -ErrorAction Stop 
				} 
			}Catch {
				Write-Warning -Message "Wallpaper not changed because $($_.Exception.Message)"
			}
			iex "[Wallpaper.Setter]::SetWallpaper( '$($Path)' )"
		}
	}
	
	Class Contenders{
		[int]$index = 0;
		[int]$iterations = 0;
		$contenders = @()
		$chart = $null;
		$names = @()
		$namePool = @("Edward", "Yov", "Richard", "Nicholus", "Erica", "mario", "brendon", "charles", "Anthony", "hannah", "Jesse", "susan", "samuel", "Joseph", "john", "Matt", "brett", "Kevin", "julia", "dong", "Timothy", "Tonya", "carly", "Avery", "Shawn", "lawrence", "erik", "dianna", "thomas", "Victor", "Douglas", "elliott", "Brandon", "connie", "Lucas", "Terry", "joshua", "Kelly", "Darryl", "aaron", "Patrick", "Carlos", "ben", "ronald", "Stephen", "Zeiss", "Erika", "Spectrum", "Steven", "peter", "amanda", "momal", "Brent", "damon", "garon", "Danny", "Boliong", "Noel", "Michael", "rhiley", "David", "Marquette", "kahlil", "tyler", "jerry", "Sean", "gelsomina", "matthew", "Dwight", "nicholas", "Rachel", "Sara", "rodwin", "Shannon", "Alyssa", "Allysa", "Alan", "Bradley", "jack", "Theodore", "Chris", "Tony", "christopher", "wendy", "yohan", "phan", "alice", "Rachelle", "anja", "Evan", "Melanie", "andrew")
		
		$winners = @();
		
		Contenders(){
			$this.tellStory("Let the games begin!")
			$this.Run();
		}
		
		$startTime = (get-date -format 'MMddyyyy_hhmmss');
		
		
		Initialize(){
			$this.tellStory("Initializing the contenders and the rules of the game.")
			$this.names = ($this.namePool | sort {get-random})
			$this.contenders = @()
			$this.iterations = 0;
			$this.index = 0;
			$this.chart = [Chart]::new();
			
			$this.tellStory("Generating citizen stats.")
			
			$i = 0;
			if($global:career){
				$this.winners.getEnumerator() | sort -descending wins | % {
					if($i -lt $global:count){
						$i++;
						$_.credits = 5;
						$_.tribe = (get-random -Minimum 0 -Maximum 8 );
						$this.contenders += $_
					}
				}
			}
			
			for($i = $this.contenders.count; $i -lt $global:count; $i++){
				$totalPoints = get-random -Minimum 30 -maximum $global:totalAllowedPoints
				$str = ( get-random -Minimum $global:statMin -Maximum $global:statMax)
				$totalPoints = $totalPoints - $str
				$cons = ( get-random -Minimum $global:statMin -Maximum $global:statMax);
				$totalPoints = $totalPoints - $cons
				$dex = $totalPoints
				if($dex -lt 1){
					$dex = 1;
				}

				$name = (Get-Culture).TextInfo.ToTitleCase($this.names[ $i ] );
				while( ($this.contenders | select -expand name ) -contains $name){
					$name = (Get-Culture).TextInfo.ToTitleCase($this.names[ ( get-random -minimum 0 -maximum 90) ] );
				}
			
				$this.contenders += ((
					new-object PSCustomObject -prop @{
						credits = 5;
						tribe   = ( get-random -Minimum 0 -Maximum 8 );
						str     = $str;
						cons    = $cons;
						dex     = $dex;
						name	= $name
						wins 	= 0;
					}
				));
				
				if($global:details){
					$this.tellStory("Contender $($this.contenders[$i].name), who hails from Tribe $($this.contenders[$i].tribe), has the following stats: STR( $($this.contenders[$i].str) ), CONS( $($this.contenders[$i].cons) ),  DEX( $($this.contenders[$i].dex) ).")
				}
			}
		}
		
		Run(){
			if($global:loop){
				$this.iterations++;
				while($true){
					$this.Initialize();
					$this.Loop();
				}
			}else{
				$this.Initialize();
				$this.Loop();
			}
		}
		
		Loop(){
			While( ( $this.contenders | ? { $_.credits  -gt 0 } ).count -gt 1 ){
				$this.index++;
				$this.tellStory("")
				$this.tellStory("Preparing for battle: $($this.index)")
				$fighters = $this.getFighters();
				$results = $this.invokeBattle($fighters);
				$this.updateCredits($fighters,$results);
				$this.updateChart();
				$this.updateContenderStats();
				
				if( ($this.contenders.getEnumerator() | ? { $_.credits -gt 0 } | select @{n="mod"; e={ $_.tribe % 4 } } | sort {$_.mod} -unique).count -le 1){
					break;
				}
			}
			
			$this.contenders.getEnumerator() | ? { $_.credits -gt 0 } | % {
				$name = $_.name
				
				for($i = 0; $i -lt $this.winners.count; $i++){
					if($this.winners[$i].name -eq $name){
						$this.winners[$i] = $null
					}
				}

				$_.wins++
				$this.winners += $_;
			}	
			
			if($global:details){
				$this.tellStory("Current Winning Gladiators")
				$this.winners  | sort -descending wins  | select Name, Tribe, Wins, Credits, Str, Cons, Dex | ft| out-string | write-host
			}
			
			$this.chart.render($this)
		}

		[void]updateContenderStats(){
			if($global:details){
				$this.tellStory("Seeing if the remaining contenders are gaining stats.")
			}
			
			
			if($this.index % 50 -eq 0 -and $global:tax){
				$taxRevenue = 0;
				$stillAlive = 0
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0){
						$this.contenders[$i].credits--
						$taxRevenue++;
						if($global:details){
							$this.tellStory("$($this.contenders[$i].name) pays a tax.")
						}
					}
				}
				
				$taxRecipient = ($this.contenders.getEnumerator() | ? { $_.credits -gt 0 } | sort { $_.credits } | select -first 1)
				$taxRecipient.credits += $taxRevenue
				
				if($global:details){
					$this.tellStory("$($this.contenders[$i].name) recieved a tax repayment.")
				}
				
				
			}
			
			if($this.index % $($this.contenders.count * 10 + 125) -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0 -and $this.contenders[$i].cons -lt 50){
						$this.contenders[$i].cons++
						if($global:details){
							$this.tellStory("$($this.contenders[$i].name) is gaining CONS points.")
						}
					}
				}
			}
			

			if($this.index % $($this.contenders.count * 10 + 75) -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0  -and $this.contenders[$i].dex -lt 50){
						$this.contenders[$i].dex++
						if($global:details){
							$this.tellStory("$($this.contenders[$i].name) is gaining DEX points.")
						}
					}
				}
			}
			
			if($this.index % $($this.contenders.count * 10 + 100) -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0  -and $this.contenders[$i].str -lt 50){
						$this.contenders[$i].str++
						if($global:details){
							$this.tellStory("$($this.contenders[$i].name) is gaining STR points.")
						}
					}
				}
			}
		}
		
		[void]updateChart(){
			if($global:details){
				$this.tellStory("Adding battle record to the point collection.")
			}
			$this.contenders | % {
				$this.chart.points += new-object psCustomObject -prop @{
					index = [int]$this.index; #time
					citizen = [string]$_.name; #citizen
					credits = [int]$_.credits; #credits
				}
			}
		}
		
		[void] updateCredits($contenders,$results){
			if($results -eq 0){
				$contenders[0].credits++
				$contenders[1].credits--
				if($global:details){
					$this.tellStory("$($contenders[0].name) earned a credit and now has `$$($contenders[0].credits).")
					$this.tellStory("$($contenders[1].name) lost a credit and now has `$$($contenders[1].credits).")
				}
			}else{
				$contenders[0].credits--
				$contenders[1].credits++
				if($global:details){
					$this.tellStory("$($contenders[1].name) earned a credit and now has `$$($contenders[1].credits).")
					$this.tellStory("$($contenders[0].name) lost a credit and now has `$$($contenders[0].credits).")

				}
			}
		}
		
		[int]invokeBattle($contenders){
		
			$citizen0Hp = 10 * $contenders[0].cons + ( get-random -minimum 10 -maximum 20)
			$citizen1Hp = 10 * $contenders[1].cons + ( get-random -minimum 10 -maximum 20)

			$this.tellStory("$($contenders[0].name ) has $($citizen0Hp) Hit Points.")
			$this.tellStory("$($contenders[1].name ) has $($citizen1Hp) Hit Points.")
		
			while($citizen0Hp -gt 0 -and $citizen1Hp -gt 0){
				
				$bonus = $contenders[0].str - 15
				if($bonus -lt 0){
					$bonus = 0
				}
				$attack = (get-random -minimum 1 -maximum 21) + $bonus
				if($attack -gt $contenders[0].dex -or (get-random -Minimum 0 -maximum 100) -gt 70){
					$a1 = (get-random -minimum 1 -maximum 12) + $bonus
					$citizen0Hp -= $a1
					
					if($global:details){
						$this.tellStory("$($contenders[1].name) has attacked $($contenders[0].name) and caused $($a1) points of damage.")
					}
				}else{
					if($global:details){
						$this.tellStory("$($contenders[1].name) has missed $($contenders[0].name).")
					}
				}
				


				$bonus = $contenders[1].str - 15
				if($bonus -lt 0){
					$bonus = 0
				}
				$attack = (get-random -minimum 1 -maximum 21) + $bonus
				if($attack -gt $contenders[1].dex  -or (get-random -Minimum 0 -maximum 100) -gt 70){
					$a1 = (get-random -minimum 1 -maximum 12) + $bonus
					$citizen1Hp -= $a1
					
					if($global:details){
						$this.tellStory("$($contenders[0].name) has attacked $($contenders[1].name) and caused $($a1) points of damage.")
					}
				}else{
					if($global:details){
						$this.tellStory("$($contenders[0].name) has missed $($contenders[1].name).")
					}
				}
					
				if($global:details){
					$this.tellStory("$($contenders[0].name) now has $($citizen0Hp) Hit Points.")
					$this.tellStory("$($contenders[1].name) now has $($citizen1Hp) Hit Points.")
					$this.tellStory("");
				}
				
			}
			
			$winner = ( @(1,0)[($citizen0Hp -gt 0)] )
			$this.tellStory("$($contenders[$winner].name) won the battle.")
							
			return $winner
		}
		
		[object]getFighters(){
			$sameTribe = $false;
			$loops = 0
			do{
				$loops++
				$fighters = @()
				$this.contenders.getEnumerator() | ? { $_.credits -gt 0 } | sort {get-random} | select -first 2 | % {
					$fighters += $_
				}
				if( ($fighters[0].tribe % 4) -eq ($fighters[1].tribe % 4)){
					$sameTribe = $true;
				}else{
					$sameTribe = $false;
				}
			}while($sameTribe -eq $true -and $loops -lt 100)
			
			if($global:details){
				$this.tellStory( "$($fighters[0].name) from Tribe $($fighters[0].tribe) will be battling $($fighters[1].name ) from Tribe $($fighters[1].tribe)."  );
			}
			return $fighters
		}
		
		[void]tellStory($msg){
			if($global:storyTellingMode){
				write-host $msg
				$msg | Add-Content "$($pwd)\ContendersChart_$( $this.startTime ).log"
			}
		}
	}
	
}
Process{
	$game = [Contenders]::new()
}
End{

}





