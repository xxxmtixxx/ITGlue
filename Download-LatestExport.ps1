# Download-LatestITGlueExport.ps1

# Set your IT Glue API key
$api_key = ""

# Set the output directory for downloading the export file
$output_dir = "C:\Temp\IT_Glue"
if (-not (Test-Path $output_dir)) {
    New-Item -ItemType Directory -Path $output_dir
}

# Log function
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath "$output_dir\ExportLog.txt" -Append
}

# Set headers for API requests
$headers = @{
    "Content-Type" = "application/vnd.api+json"
    "x-api-key"    = $api_key
}

# Get the list of exports from the IT Glue API
$exportsUrl = "https://api.itglue.com/exports"
Write-Log "Fetching list of available exports from IT Glue..."

try {
    $exportsResponse = Invoke-RestMethod -Uri $exportsUrl -Method 'GET' -Headers $headers

    if ($exportsResponse.data -ne $null -and $exportsResponse.data.Count -gt 0) {
        # Sort exports by 'created_at' field in descending order to get the latest export first
        $latestExport = $exportsResponse.data | Sort-Object { $_.attributes.'created-at' } -Descending | Select-Object -First 1

        # Extract necessary information from the latest export
        $exportId = $latestExport.id
        $createdAt = $latestExport.attributes.'created-at'
        $downloadUrl = $latestExport.attributes.'download-url'

        Write-Log "Latest export found: ID = $exportId, Created At = $createdAt"

        if ($downloadUrl -ne $null) {
            # Define the output file path for the download
            $outputFilePath = Join-Path $output_dir "ITGlue_Export_$exportId.zip"

            # Download the export file
            Write-Log "Downloading the latest export to: $outputFilePath"
            Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $outputFilePath

            Write-Log "Download completed successfully."
        }
        else {
            Write-Log "The latest export does not have a valid download URL."
        }
    }
    else {
        Write-Log "No exports are currently available for download."
    }
}
catch {
    Write-Log "An error occurred while fetching or downloading the export. Error: $($_.Exception.Message)"
}

Write-Log "Script execution completed."