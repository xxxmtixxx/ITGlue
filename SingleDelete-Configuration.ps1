# SingleDelete-Configuration.ps1

# Set your IT Glue API key
$api_key = ""

# Hardcoded organization ID, configuration ID, organization name, and configuration name
$organization_id = ""
$config_id = ""
$organization_name = ""
$config_name = ""

# Set the API endpoint URL for deleting a specific configuration within an organization
$deleteUrl = "https://api.itglue.com/organizations/$organization_id/relationships/configurations"

# Create the JSON body to specify the configuration ID
$body = @(
    @{
        "type"       = "configurations"
        "attributes" = @{
            "id" = $config_id
        }
    }
) | ConvertTo-Json -Depth 4

# Create headers for the API request
$headers = @{
    "Content-Type" = "application/vnd.api+json"
    "x-api-key"    = $api_key
}

# Output message indicating the start of the DELETE request
Write-Host "Sending DELETE request for configuration ID: $config_id (Name: $config_name) in organization ID: $organization_id (Organization Name: $organization_name)"

try {
    # Send DELETE request to the API
    $response = Invoke-RestMethod -Uri $deleteUrl -Method 'DELETE' -Headers $headers -Body $body

    # Output success message
    Write-Host "Successfully deleted configuration with ID: $config_id (Name: $config_name) in organization: $organization_name"
}
catch {
    # Output error message if deletion fails
    Write-Host "Error deleting configuration with ID: $config_id (Name: $config_name) in organization: $organization_name. Error: $($_.Exception.Message)" -ForegroundColor Red
}