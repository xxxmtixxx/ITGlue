# IT Glue Configuration Management Scripts

This repository contains five PowerShell scripts for managing configuration data in IT Glue. These scripts provide functionality for exporting configuration data (with and without relationships), bulk deleting configurations, single deletion of configurations, and downloading the latest export file.

## Scripts

1. `Export-Configurations.ps1`: Fast version that exports basic configuration data.
2. `Export-ConfigurationsWithRelationships.ps1`: Comprehensive version that includes related items and passwords.
3. `BulkDelete-Configurations.ps1`: Script for bulk deleting configurations based on a CSV input, with logging functionality.
4. `SingleDelete-Configuration.ps1`: Script for deleting a single configuration using hardcoded values.
5. `Download-LatestITGlueExport.ps1`: Script for downloading the latest export available in IT Glue.

## Features

### Export Scripts (1 and 2)

Both export scripts offer the following features:
- Fetch and display a list of all organizations in alphabetical order.
- Allow selection of a single organization or all organizations for export.
- Handle pagination for large datasets.
- Provide detailed console output for monitoring progress.
- Export data to CSV files with descriptive names.

#### Export-Configurations.ps1 (Fast Version)

- Optimized for faster execution by excluding related items and passwords.
- Reduces the number of API calls required.
- Increases the page size for configuration retrieval.

#### Export-ConfigurationsWithRelationships.ps1 (Comprehensive Version)

- Exports configuration data, including related items and passwords.
- Provides more detailed information about each configuration.
- Makes additional API calls to fetch related data.

### BulkDelete-Configurations.ps1

- Reads configuration IDs from a CSV file.
- Filters out configurations that have values in the "passwords" or "related-items" fields before processing.
- Sends DELETE requests to the IT Glue API for each configuration.
- Provides progress tracking during the deletion process.
- Logs all activities, including successful deletions and errors, to a file in `C:\\Temp\\IT_Glue`.
- Implements error handling for each deletion attempt.

### SingleDelete-Configuration.ps1

- Deletes a single configuration in IT Glue based on hardcoded organization and configuration IDs.
- Sends a DELETE request to the IT Glue API for the specified configuration.
- Logs the success or failure of the deletion attempt to the console.

### Download-LatestITGlueExport.ps1

- Fetches a list of available exports from the IT Glue API.
- Finds the latest available export and downloads it if it is ready.
- Logs progress, including information on the latest export found, and saves the downloaded file in `C:\\Temp\\IT_Glue`.

## Usage

### Export Scripts (1 and 2):

1. Ensure you have a valid IT Glue API key.
2. Set the `$api_key` variable in the script with your API key.
3. Run the script in PowerShell.
4. Choose an organization from the displayed list or select '0' to process all organizations.
5. Wait for the export process to complete.

### BulkDelete-Configurations.ps1:

1. Prepare a CSV file with a column named 'id' containing the configuration IDs to be deleted.
2. Set the `$api_key` variable in the script with your IT Glue API key.
3. Run the script in PowerShell.
4. Enter the path to your CSV file when prompted.
5. The script will process each ID, display progress in the console, and log all activities.
6. Check the log file in `C:\\Temp\\IT_Glue` for detailed information on the deletion process.

### SingleDelete-Configuration.ps1:

1. Set the `$api_key` variable in the script with your IT Glue API key.
2. Modify the hardcoded variables (`$organization_id`, `$config_id`, `$organization_name`, `$config_name`) to match the configuration you wish to delete.
3. Run the script in PowerShell.
4. The script will delete the specified configuration and output the result.

### Download-LatestITGlueExport.ps1:

1. Set the `$api_key` variable in the script with your IT Glue API key.
2. Run the script in PowerShell.
3. The script will fetch the list of exports and download the latest available one.
4. Progress and log messages are output to the console and saved to `C:\\Temp\\IT_Glue\\ExportLog.txt`.

## Output

### Export-Configurations.ps1
- For individual organizations: `{OrganizationName}_Configurations.csv`.
- For all organizations: `All_Organizations_Configurations.csv`.

### Export-ConfigurationsWithRelationships.ps1
- For individual organizations: `{OrganizationName}_Configurations_Relationships.csv`.
- For all organizations: `All_Organizations_Configurations_Relationships.csv`.

### BulkDelete-Configurations.ps1
- Log file: `BulkDelete_Configurations_Log.txt`.

### SingleDelete-Configuration.ps1
- No output file is created. The result of the deletion is logged to the console.

### Download-LatestITGlueExport.ps1
- Downloaded file: `ITGlue_Export_{exportId}.zip`.
- Log file: `ExportLog.txt`.

All files are saved in the `C:\\Temp\\IT_Glue` directory by default.

## Performance Considerations

- `Export-Configurations.ps1` is optimized for faster execution but provides less detailed information.
- `Export-ConfigurationsWithRelationships.ps1` provides more comprehensive data but may take longer to run due to additional API calls.
- `BulkDelete-Configurations.ps1` processes deletions sequentially, which may take time for large numbers of configurations. Progress is logged and displayed in real-time.
- `SingleDelete-Configuration.ps1` is used for deleting a single configuration and provides immediate feedback.
- `Download-LatestITGlueExport.ps1` requires waiting for the export to be available for download if it is not yet completed.

## Requirements

- PowerShell 5.1 or later.
- Valid IT Glue API key with appropriate permissions.
- For `BulkDelete-Configurations.ps1`: A CSV file with configuration IDs.

## Important Notes

- These scripts interact with the IT Glue API and may take some time to run, especially when processing multiple or large organizations.
- Ensure you have a stable internet connection and sufficient permissions in IT Glue before running the scripts.
- The bulk delete script and the single delete script permanently remove configurations. Use with caution and ensure you have backups if needed. Review the log file after execution to confirm all deletions were successful.

Choose the appropriate script based on your needs:
- Use `Export-Configurations.ps1` for a quick overview of configurations without related items or passwords.
- Use `Export-ConfigurationsWithRelationships.ps1` when you need comprehensive configuration data, including related items and passwords.
- Use `BulkDelete-Configurations.ps1` when you need to remove multiple configurations based on their IDs. Always review the log file after execution.
- Use `SingleDelete-Configuration.ps1` when you need to delete a specific configuration quickly.
- Use `Download-LatestITGlueExport.ps1` to retrieve the latest export from IT Glue when it becomes available.
