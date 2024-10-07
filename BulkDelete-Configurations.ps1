# BulkDelete-Configurations.ps1

# Set your IT Glue API key
$api_key = ""

# Prompt the user for the CSV file path
$csvPath = Read-Host "Enter the CSV file path"

# Normalize the path (remove any surrounding quotes)
$csvPath = $csvPath -replace '^"|"$', ''

# Check if the file exists
if (-not (Test-Path -Path $csvPath)) {
    Write-Host "The file path provided does not exist: $csvPath" -ForegroundColor Red
    exit
}

# Set the output directory and log file path
$output_dir = "C:\Temp\IT_Glue"
$log_file = Join-Path $output_dir "BulkDelete_Configurations_Log.txt"

# Create output directory if it doesn't exist
if (-not (Test-Path $output_dir)) {
    New-Item -ItemType Directory -Path $output_dir
}

# Function to write to log file
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $log_file -Append
}

# Import CSV data
try {
    $CSVData = Import-Csv -Path $csvPath
}
catch {
    Write-Host "Error importing CSV file. Please check the file path and format." -ForegroundColor Red
    Write-Log "Error importing CSV file: $($_.Exception.Message)"
    exit
}

# Log the start of the process
Write-Log "Starting bulk delete process"
Write-Log "CSV file path: $csvPath"

# Initialize an array to store skipped configurations
$skippedConfigurations = @()

# Filter out rows that have values in the "passwords" or "related-items" fields
$filteredCSVData = $CSVData | Where-Object {
    # Check for values in "passwords" and "related-items" fields
    $passwordsArray = ($_."passwords" -match "ID: \d+, Type: passwords")
    $relatedItemsArray = ($_."related-items" -match "ID: \d+, Type: ")

    if ($passwordsArray) {
        $skippedConfigurations += [PSCustomObject]@{
            ID          = $_.id
            Name        = $_.name
            Organization = $_.'organization-name'
            Reason      = "Has passwords"
        }
        return $false
    }
    elseif ($relatedItemsArray) {
        $skippedConfigurations += [PSCustomObject]@{
            ID          = $_.id
            Name        = $_.name
            Organization = $_.'organization-name'
            Reason      = "Has related items"
        }
        return $false
    }
    else {
        return $true
    }
}

# Log the number of configurations that are being processed
Write-Log "Total configurations to process after filtering: $($filteredCSVData.Count)"

# Loop through each row in the filtered CSV to delete configurations
foreach ($row in $filteredCSVData) {
    # Extract organization ID, configuration ID, organization name, and name from CSV
    $organization_id = $row.'organization-id'
    $config_id = $row.id
    $organization_name = $row.'organization-name'
    $config_name = $row.name

    # Check if the IDs are valid
    if (-not $organization_id -or -not $config_id) {
        $errorMessage = "Missing organization ID or configuration ID for row: $($row | Out-String)"
        Write-Host $errorMessage -ForegroundColor Yellow
        Write-Log $errorMessage
        continue
    }

    # Set the API endpoint URL for deleting a specific configuration within an organization
    $deleteUrl = "https://api.itglue.com/organizations/$organization_id/relationships/configurations"

    # Create the JSON body to specify the configuration ID
    $body = @"
{
    "data": [
        {
            "type": "configurations",
            "attributes": {
                "id": "$config_id"
            }
        }
    ]
}
"@

    # Create headers for the API request
    $headers = @{
        "Content-Type" = "application/vnd.api+json"
        "x-api-key"    = $api_key
    }

    # Log request details for debugging, including organization name and configuration name
    $logMessage = "Sending DELETE request for configuration ID: $config_id (Name: $config_name) in organization ID: $organization_id (Organization Name: $organization_name)"
    Write-Host $logMessage
    Write-Log $logMessage

    try {
        # Send DELETE request to the API
        $response = Invoke-RestMethod -Uri $deleteUrl -Method 'DELETE' -Headers $headers -Body $body

        # Log successful deletion
        $successMessage = "Successfully deleted configuration with ID: $config_id (Name: $config_name) in organization: $organization_name"
        Write-Host $successMessage
        Write-Log $successMessage
    }
    catch {
        # Log error if deletion fails
        $errorMessage = "Error deleting configuration with ID: $config_id (Name: $config_name) in organization: $organization_name. Error: $($_.Exception.Message)"
        Write-Host $errorMessage
        Write-Log $errorMessage
    }
}

# Log the completion of the process
Write-Log "Bulk delete process completed."
Write-Host "Bulk delete process completed. See log file for details: $log_file"

# Log and display skipped configurations
if ($skippedConfigurations.Count -gt 0) {
    Write-Log "Total configurations skipped: $($skippedConfigurations.Count)"
    Write-Host "Total configurations skipped: $($skippedConfigurations.Count)" -ForegroundColor Yellow

    foreach ($skippedConfig in $skippedConfigurations) {
        $skippedMessage = "Skipped configuration ID: $($skippedConfig.ID) (Name: $($skippedConfig.Name)) in organization: $($skippedConfig.Organization). Reason: $($skippedConfig.Reason)"
        Write-Host $skippedMessage -ForegroundColor Yellow
        Write-Log $skippedMessage
    }
}