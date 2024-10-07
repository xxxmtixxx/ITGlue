# Export-Configurations.ps1

# Set your IT Glue API key
$api_key = ""

# Set the output directory
$output_dir = "C:\Temp\IT_Glue"

# Create output directory if it doesn't exist
if (-not (Test-Path $output_dir)) {
    New-Item -ItemType Directory -Path $output_dir
}

# Set headers for API request
$headers = @{
    "Content-Type" = "application/vnd.api+json"
    "x-api-key" = $api_key
}

# Define PSA and RMM types
$psa_types = @("manage", "autotask", "tigerpaw", "kaseya-bms", "pulseway-psa", "vorex")
$rmm_types = @("addigy", "aem", "atera", "auvik", "managed-workplace", "continuum", "jamf-pro", "kaseya-vsa", "automate", "log-me-in", "msp-rmm", "meraki", "msp-n-central", "ninja-rmm", "panorama9", "pulseway-rmm", "syncro", "watchman-monitoring", "office365", "vsa-x")

# Prompt the user to select a filter type
Write-Host "Select a filter to apply:" -ForegroundColor Green
Write-Host "1. psa_integration_type" -ForegroundColor Cyan
Write-Host "2. rmm_integration_type" -ForegroundColor Cyan
Write-Host "3. None" -ForegroundColor Cyan

$filterSelection = Read-Host "Enter the number of the filter you want to apply"
$filterSelection = [int]($filterSelection.Trim())

# Get user input for filter value
$filterValue = ""
$filterType = ""

switch ($filterSelection) {
    1 {
        $filterType = "psa_integration_type"
        Write-Host "Available PSA values:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $psa_types.Count; $i++) {
            Write-Host ("{0}. {1}" -f ($i + 1), $psa_types[$i]) -ForegroundColor Cyan
        }
        $psaSelection = Read-Host "Enter the number of the psa_integration_type you want to apply"
        $psaSelection = [int]($psaSelection.Trim())
        if ($psaSelection -ge 1 -and $psaSelection -le $psa_types.Count) {
            $filterValue = $psa_types[$psaSelection - 1]
        } else {
            Write-Host "Invalid selection. Please run the script again and choose a valid option." -ForegroundColor Red
            exit
        }
    }
    2 {
        $filterType = "rmm_integration_type"
        Write-Host "Available RMM values:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $rmm_types.Count; $i++) {
            Write-Host ("{0}. {1}" -f ($i + 1), $rmm_types[$i]) -ForegroundColor Cyan
        }
        $rmmSelection = Read-Host "Enter the number of the rmm_integration_type you want to apply"
        $rmmSelection = [int]($rmmSelection.Trim())
        if ($rmmSelection -ge 1 -and $rmmSelection -le $rmm_types.Count) {
            $filterValue = $rmm_types[$rmmSelection - 1]
        } else {
            Write-Host "Invalid selection. Please run the script again and choose a valid option." -ForegroundColor Red
            exit
        }
    }
    3 {
        Write-Host "No filter selected. Proceeding without applying any filter." -ForegroundColor Yellow
    }
    default {
        Write-Host "Invalid selection. Please run the script again and choose a valid option." -ForegroundColor Red
        exit
    }
}

# Function to fetch configurations for an organization
function Get-OrganizationConfigurations($org_id, $org_name) {
    $all_configurations = @()
    
    # Construct the URL with or without the selected filter
    if ($filterType -ne "") {
        $GetConfigurationsUrl = "https://api.itglue.com/organizations/$org_id/relationships/configurations?page[size]=1000&filter[$filterType]=$filterValue"
    } else {
        $GetConfigurationsUrl = "https://api.itglue.com/organizations/$org_id/relationships/configurations?page[size]=1000"
    }

    $next_page = $GetConfigurationsUrl

    do {
        $config_response = Invoke-RestMethod -Uri $next_page -Method 'GET' -Headers $headers

        if ($config_response.data -ne $null) {
            foreach ($config in $config_response.data) {
                $config_obj = [ordered]@{}

                # Add the 'id' field to the beginning of the configuration object
                $config_obj['id'] = $config.id

                # Add the rest of the attributes
                foreach ($attr in $config.attributes.PSObject.Properties) {
                    $config_obj[$attr.Name] = $attr.Value
                }

                $all_configurations += [PSCustomObject]$config_obj

                # Debug output
                Write-Host "Organization: $org_name (ID: $org_id), Configuration ID: $($config.id)" -ForegroundColor Cyan
            }
        }

        # Check for pagination info
        $next_page = $config_response.links.next

    } while ($next_page -ne $null)  # Continue while there's a next page

    return $all_configurations
}

# Fetch all organizations
$GetOrganizationsUrl = "https://api.itglue.com/organizations"
$org_response = Invoke-RestMethod -Uri $GetOrganizationsUrl -Method 'GET' -Headers $headers

if ($org_response.data -ne $null) {
    $organizations = $org_response.data | Sort-Object { $_.attributes.name }
    
    # Display numbered list of organizations
    Write-Host "Select an organization to process (or 0 to process all):" -ForegroundColor Green
    Write-Host "0. Process All Organizations" -ForegroundColor Yellow
    for ($i = 0; $i -lt $organizations.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $organizations[$i].attributes.name) -ForegroundColor Cyan
    }

    # Get user selection
    $selection = Read-Host "Enter your selection"
    $selection = [int]$selection

    if ($selection -eq 0) {
        # Process all organizations
        $total_orgs = $organizations.Count
        $current_org = 0
        $all_configurations = @()

        foreach ($org in $organizations) {
            $current_org++
            $org_id = $org.id
            $org_name = $org.attributes.name

            Write-Host ("Processing organization {0} of {1}: {2} (ID: {3})" -f $current_org, $total_orgs, $org_name, $org_id) -ForegroundColor Green

            # Fetch configurations for the current organization
            $org_configurations = Get-OrganizationConfigurations -org_id $org_id -org_name $org_name
            $all_configurations += $org_configurations
        }

        # Export all configurations to a single CSV
        $output_filename = "All_Organizations_Configurations"
        if ($filterType -ne "") {
            $output_filename += "_$filterValue"
        }
        $output_path = Join-Path $output_dir "$output_filename.csv"
        $all_configurations | Export-Csv -Path $output_path -NoTypeInformation

        Write-Host "All configurations exported to $output_path" -ForegroundColor Green
        Write-Host "Total configurations exported: $($all_configurations.Count)" -ForegroundColor Green
    }
    elseif ($selection -ge 1 -and $selection -le $organizations.Count) {
        # Process selected organization
        $selected_org = $organizations[$selection - 1]
        $org_id = $selected_org.id
        $org_name = $selected_org.attributes.name

        Write-Host ("Processing organization: {0} (ID: {1})" -f $org_name, $org_id) -ForegroundColor Green

        # Fetch configurations for the selected organization
        $org_configurations = Get-OrganizationConfigurations -org_id $org_id -org_name $org_name

        # Export configurations to CSV
        $safe_org_name = $org_name -replace '[^\w\-\.]', '_'  # Replace invalid filename characters
        $output_filename = "${safe_org_name}_Configurations"
        if ($filterType -ne "") {
            $output_filename += "_$filterValue"
        }
        $output_path = Join-Path $output_dir "$output_filename.csv"
        $org_configurations | Export-Csv -Path $output_path -NoTypeInformation

        Write-Host "Configurations exported to $output_path" -ForegroundColor Green
        Write-Host "Total configurations exported: $($org_configurations.Count)" -ForegroundColor Green
    }
    else {
        Write-Host "Invalid selection. Please run the script again and choose a valid option." -ForegroundColor Red
    }
}
else {
    Write-Host "No organizations returned from the API." -ForegroundColor Red
}