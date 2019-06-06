[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $count = 30,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $statMin = 10,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $statMax = 19,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][int] $totalAllowedPoints = 45,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $loop,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $wallpaper,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $storyTellingMode,
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][switch] $details
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
		}
		
		[void]render($game){
			
			$game.tellStory("Rendering the timeline chart.")
			
			for($i = 0; $i -lt $global:count; $i++){
				if($global:details){
					$game.tellStory("Adding $((Get-Culture).TextInfo.ToTitleCase($game.names[ $i ] ) )  battle run to the chart.")
				}
				
				$Series = New-Object -TypeName System.Windows.Forms.DataVisualization.Charting.Series
				$this.Chart.Series.Add($Series)
				$Series.ChartType = $this.ChartTypes::StackedArea

				$indexes = @()
				$credits = @()

				$this.points | ? { $_.citizen -eq $i} | sort { $_.index }  | % {
					$indexes += $_.index;
					$credits += $_.credits;
				}
				$series.Points.DataBindXY($indexes, $credits) | out-null
			}

			$this.chartarea.axisy.maximum= ( 5 * $global:count)
			$this.Chart.ChartAreas.Add($this.ChartArea)
			$filename = ( $Env:USERPROFILE + "\Pictures\ContendersChart_$( get-date -format 'MMddyyyy_hhmmss' ).png" )
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
		$contenders = @{}
		$chart = $null;
		$names = @()
		$namePool = @("Edward", "Yov", "Richard", "Nicholus", "Erica", "mario", "brendon", "charles", "Anthony", "hannah", "Jesse", "susan", "samuel", "Joseph", "john", "Matt", "brett", "Kevin", "julia", "dong", "Timothy", "Tonya", "carly", "Avery", "Shawn", "lawrence", "erik", "dianna", "thomas", "Victor", "Douglas", "elliott", "Brandon", "connie", "Lucas", "Terry", "joshua", "Kelly", "Darryl", "aaron", "Patrick", "Carlos", "ben", "ronald", "Stephen", "Zeiss", "Erika", "Spectrum", "Steven", "peter", "amanda", "momal", "Brent", "damon", "garon", "Danny", "Boliong", "Noel", "Michael", "rhiley", "David", "Marquette", "kahlil", "tyler", "jerry", "Sean", "gelsomina", "matthew", "Dwight", "nicholas", "Rachel", "Sara", "rodwin", "Shannon", "Alyssa", "Allysa", "Alan", "Bradley", "jack", "Theodore", "Chris", "Tony", "christopher", "wendy", "yohan", "phan", "alice", "Rachelle", "anja", "Evan", "Melanie", "andrew")
		Contenders(){
			$this.tellStory("Let the games begin!")
			$this.Run();
		}
		
		Initialize(){
			$this.tellStory("Initializing the contenders and the rules of the game.")
			$this.names = ($this.namePool | sort {get-random})
			$this.contenders = @{}
			$this.iterations = 0;
			$this.index = 0;
			$this.chart = [Chart]::new();
			
			$this.tellStory("Generating citizen stats.")
			for($i = 0; $i -lt $global:count; $i++){
				$totalPoints = get-random -Minimum 20 -maximum $global:totalAllowedPoints
				$str = ( get-random -Minimum $global:statMin -Maximum $global:statMax)
				$totalPoints = $totalPoints - $str
				$cons = ( get-random -Minimum $global:statMin -Maximum $global:statMax);
				$totalPoints = $totalPoints - $cons
				$dex = $totalPoints
				if($dex -lt 1){
					$dex = 1;
				}

				$this.contenders.add($i,(
					new-object PSCustomObject -prop @{
						credits = 5;
						tribe   = ( get-random -Minimum 0 -Maximum 4 );
						str     = $str;
						cons    = $cons;
						dex     = $dex;
					}
				));
				if($global:details){
					$this.tellStory("Citizen $($i), who hails from Tribe $($this.contenders[$i].tribe), has the following stats: STR( $($this.contenders[$i].str) ), CONS( $($this.contenders[$i].cons) ),  DEX( $($this.contenders[$i].dex) ).")
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
			While( ( $this.contenders.getEnumerator() | ? { $_.value.credits  -gt 0 } ).count -gt 1 ){
				$this.index++;
				$this.tellStory("")
				$this.tellStory("Preparing for battle: $($this.index)")
				$fighters = $this.getFighters();
				$results = $this.invokeBattle($fighters);
				$this.updateCredits($fighters,$results);
				$this.updateChart();
				$this.updateContenderStats();
				
				if( ($this.contenders.getEnumerator() | ? { $_.value.credits -gt 0 } | select @{n="mod"; e={ $_.value.tribe % 2 } } | sort {$_.mod} -unique).count -le 1){
					break;
				}
			}
			
			
			$this.chart.render($this)
		}

		[void]updateContenderStats(){
			if($global:details){
				$this.tellStory("Seeing if the remaining contenders are gaining stats.")
			}
			if($this.index % 100 -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0){
						$this.contenders[$i].cons++
						if($global:details){
							$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $i ] ) ) is gaining CONS points.")
						}
					}
				}
			}

			if($this.index % 250 -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0){
						$this.contenders[$i].str++
						if($global:details){
							$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $i] ) ) is gaining STR points.")
						}
					}
				}
			}

			if($this.index % 200 -eq 0){
				for($i = 0; $i -lt 30; $i++){
					if($this.contenders[$i].credits -gt 0){
						$this.contenders[$i].dex++
						if($global:details){
							$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $i ] ) ) is gaining DEX points.")
						}
					}
				}
			}
		}
		
		[void]updateChart(){
			if($global:details){
					$this.tellStory("Adding battle record to the chart.")
				}
			$this.contenders.getEnumerator() | % {
				$this.chart.points += new-object psCustomObject -prop @{
					index = [int]$this.index; #time
					citizen = [int]$_.name; #citizen
					credits = [int]$_.value.credits; #credits
				}
			}
		}
		
		[void] updateCredits($contenders,$results){
			if($results -eq 0){
				$this.contenders[ $contenders[0].key ].credits = $this.contenders[ $contenders[0].key ].credits + 1;
				$this.contenders[ $contenders[1].key ].credits = $this.contenders[ $contenders[1].key ].credits - 1;
				if($global:details){
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) ) earned a credit and $((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) lost a credit.")
				}
			}else{
				$this.contenders[ $contenders[0].key ].credits = $this.contenders[ $contenders[0].key ].credits - 1;
				$this.contenders[ $contenders[1].key ].credits = $this.contenders[ $contenders[1].key ].credits + 1;
				if($global:details){
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) earned a credit and $((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) )  lost a credit.")
				}
			}
		}
		
		[int]invokeBattle($contenders){
		
			$citizen1Hp = 10 * $contenders[0].value.cons + ( get-random -minimum 10 -maximum 20)
			$citizen2Hp = 10 * $contenders[1].value.cons + ( get-random -minimum 10 -maximum 20)

			$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) ) has $($citizen1Hp) Hit Points.")
			$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) has $($citizen2Hp) Hit Points.")
		
			while($citizen1Hp -gt 0 -and $citizen2Hp -gt 0){
				$a1 = (
						(
							( ( get-random -minimum 0 -maximum 50) / 50 * $contenders[1].value.str ) -
							( ( get-random -minimum 0 -maximum 100) / 100 * $contenders[0].value.dex )
						)
					)
				if($a1 -lt 1){ $a1 = 1 }
				$citizen1Hp = $citizen1Hp - $a1
				
				if($global:details){
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) has attacked $((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) ) and caused $($a1) points of damage.")
				}

				$a2 = (
						(
							( ( get-random -minimum 0 -maximum 50) / 50 * $contenders[0].value.str ) -
							( ( get-random -minimum 0 -maximum 100) / 100 * $contenders[1].value.dex )
						)
					)
				if($a2 -lt 1){ $a2 = 1 }
				$citizen2Hp = $citizen2Hp - $a2
				if($global:details){
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) ) has attacked $((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) and caused $($a2) points of damage.")
				}
					
				if($global:details){
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[0].name] ) ) now has $($citizen1Hp) Hit Points.")
					$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[1].name] ) ) now has $($citizen2Hp) Hit Points.")
					$this.tellStory("");
				}
				
			}
			
			$winner = ( @(1,0)[($citizen1Hp -gt 0)] )
			$this.tellStory("$((Get-Culture).TextInfo.ToTitleCase($this.names[ $contenders[$winner].name] ) ) won the battle.")
							
			return $winner
		}
		
		[object]getFighters(){
			$sameTribe = $false;
			do{
				$fighters = @()
				$this.contenders.getEnumerator() | ? { $_.value.credits -gt 0 } | sort {get-random} | select -first 2 | % {
					$fighters += $_
				}
				if( ($fighters[0].value.tribe % 2) -eq ($fighters[1].value.tribe % 2)){
					$sameTribe = $true;
				}else{
					$sameTribe = $false;
				}
			}while($sameTribe -eq $true)
			if($global:details){
				$this.tellStory( "$((Get-Culture).TextInfo.ToTitleCase($this.names[ $fighters[0].name] ) ) from Tribe $($fighters[0].value.tribe) will be battling $((Get-Culture).TextInfo.ToTitleCase($this.names[ $fighters[1].name] ) ) from Tribe $($fighters[1].value.tribe)."  );
			}
			return $fighters
		}
		
		[void]tellStory($msg){
			if($global:storyTellingMode){
				write-host $msg
			}
		}
	}
	
}
Process{
	$game = [Contenders]::new()
}
End{

}





