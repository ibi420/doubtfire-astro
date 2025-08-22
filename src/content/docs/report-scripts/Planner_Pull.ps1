# Check for Microsoft.Graph module
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module is not installed. Please install it by running: Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber -Force"
    exit
}

# --- Menu Selection ---
Write-Host "How would you like to pull the tasks? Select the relevant Option"
Write-Host "1. Pull all tasks (including unassigned)"
Write-Host "2. Pull only tasks with assigned users ONLY"
Write-Host "3. Pull tasks of assigned users based on a date range(great for progress and handover Doc)"
$selection = Read-Host -Prompt "Enter your choice (1, 2 or 3)"

if ($selection -ne '1' -and $selection -ne '2' -and $selection -ne '3') {
    Write-Host "Invalid selection. Exiting."
    exit
}

if ($selection -eq '3') {
    $startDateStr = Read-Host -Prompt "Enter the start date (YYYY-MM-DD)"
    $endDateStr = Read-Host -Prompt "Enter the end date (YYYY-MM-DD)"

    try {
        $startDate = [datetime]::ParseExact($startDateStr, 'yyyy-MM-dd', $null)
        $endDate = [datetime]::ParseExact($endDateStr, 'yyyy-MM-dd', $null).AddDays(1) # Adds one day to include the entire end day
    }
    catch {
        Write-Host "Invalid date format. Please use YYYY-MM-DD. Exiting."
        exit
    }
}

# Import required sub modules
Write-Host "Importing Required Microsoft.Graph sub modules..."
Import-Module Microsoft.Graph.Planner
Import-Module Microsoft.Graph.Users

# Authenticate to Microsoft Graph
Write-Host "Authenticating to Microsoft Graph..."
try {
    # Connect to Microsoft Graph with required permissions
    Connect-MgGraph -Scopes @(
        "Tasks.Read",
        "Tasks.ReadWrite",
        "User.ReadBasic.All"
    ) -UseDeviceCode -Audience "organizations"

    # Verify connection
    $context = Get-MgContext
    if (-not $context) {
        throw "Failed to establish connection"
    }
    Write-Host "Authentication successful as $($context.Account)"
}
catch {
    Write-Error "Authentication failed: $_"
    exit 1
}

# --- Plan ID Configuration ---
$configPath = ".\config.txt"
$planId = $null

if (Test-Path $configPath) {
    $savedPlans = @(Get-Content $configPath | Where-Object { $_ -match ".+ - .+" }) # Filter for valid entries
    if ($savedPlans) {
        Write-Host "Please choose a saved Plan ID or enter a new one:"
        for ($i = 0; $i -lt $savedPlans.Count; $i++) {
            # Display only the name part
            Write-Host ("{0}. {1}" -f ($i + 1), $savedPlans[$i].Split(' - ', 2)[1])
        }
        Write-Host "N. Enter a new Plan ID"

        $choice = Read-Host -Prompt "Select an ID"

        if ($choice -eq 'N' -or $choice -eq 'n') {
            # Flag to enter a new Plan ID
            $planId = $null
        }
        elseif ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $savedPlans.Count) {
            $selectedIndex = [int]$choice - 1
            # Extract the ID part
            $planId = $savedPlans[$selectedIndex].Split(' - ', 2)[0]
        }
        else {
            Write-Host "Invalid selection. Exiting."
            exit
        }
    }
}

# If no plan was selected from the menu, or if config is empty/doesn't exist
if (-not $planId) {
    $newPlanId = Read-Host -Prompt "Please enter the new Plan ID"
    $planName = Read-Host -Prompt "Please enter a name for this plan (for your reference)"

    if (-not $newPlanId -or -not $planName) {
        Write-Host "Plan ID and Plan Name cannot be empty. Exiting."
        exit
    }

    $newEntry = "$newPlanId - $planName"

    # Add the new entry to the config file
    Add-Content -Path $configPath -Value $newEntry
    Write-Host "New Plan ID saved: $newEntry"
    $planId = $newPlanId
}

Write-Host "Using Plan ID: $planId"

# Initialize task data array
$taskData = @()

# Retrieve and process tasks
Write-Host "Fetching tasks from plan..."
try {
    try {
        $tasks = Get-MgPlannerPlanTask -PlannerPlanId $planId -ErrorAction Stop
        if (-not $tasks) {
            Write-Error "No tasks found in the plan."
            exit
        }

        # Get all buckets in the plan to create a lookup table for bucket names
        $buckets = Get-MgPlannerPlanBucket -PlannerPlanId $planId -ErrorAction Stop
        $bucketNameLookup = @{}
        foreach ($bucket in $buckets) {
            $bucketNameLookup[$bucket.Id] = $bucket.Name
        }
    }
    catch {
        Write-Error "Failed to get tasks or buckets: $_"
        exit 1
    }

    foreach ($task in $tasks) {

        $bucketName = $bucketNameLookup[$task.BucketId]

        Write-Host "Processing task: $($task.Title)"

        # Get task details for attachments and assigned users
        try {
            if (-not $task.Assignments) {
                if ($selection -eq '1') {
                    $taskDetails = Get-MgPlannerTaskDetail -PlannerTaskId $task.Id
                    $attachments = "No references"
                    if ($taskDetails.References -and $taskDetails.References.AdditionalProperties) {
                        $foundUrls = @()
                        foreach ($key in $taskDetails.References.AdditionalProperties.Keys) {
                            $url = [System.Net.WebUtility]::UrlDecode($key)
                            $alias = $taskDetails.References.AdditionalProperties[$key].alias

                            $urlIsGithub = $url -like "*github.com*"
                            $aliasIsGithub = $alias -like "*github.com*"

                            if ($urlIsGithub -and $aliasIsGithub) {
                                if ($url -eq $alias) {
                                    $foundUrls += $url
                                }
                                else {
                                    $foundUrls += "$alias ($url)"
                                }
                            }
                            elseif ($urlIsGithub) {
                                $foundUrls += $url
                            }
                            elseif ($aliasIsGithub) {
                                $foundUrls += $alias
                            }
                        }
                        if ($foundUrls.Count -gt 0) {
                            $attachments = $foundUrls -join "; "
                        }
                        else {
                            $attachments = "No GitHub links"
                        }
                    }

                    $taskData += [PSCustomObject]@{
                        Name        = "Unassigned"
                        Role        = ""
                        Task        = $task.Title
                        Bucket      = $bucketNameLookup[$task.BucketId]
                        Attachments = $attachments
                    }
                }
                continue
            }

            $taskDetails = Get-MgPlannerTaskDetail -PlannerTaskId $task.Id

            # Check for GitHub references
            $attachments = "No references"
            if ($taskDetails.References -and $taskDetails.References.AdditionalProperties) {
                $foundUrls = @()
                foreach ($key in $taskDetails.References.AdditionalProperties.Keys) {
                    $url = [System.Net.WebUtility]::UrlDecode($key)
                    $alias = $taskDetails.References.AdditionalProperties[$key].alias

                    $urlIsGithub = $url -like "*github.com*"
                    $aliasIsGithub = $alias -like "*github.com*"

                    if ($urlIsGithub -and $aliasIsGithub) {
                        if ($url -eq $alias) {
                            $foundUrls += $url
                        }
                        else {
                            $foundUrls += "$alias ($url)"
                        }
                    }
                    elseif ($urlIsGithub) {
                        $foundUrls += $url
                    }
                    elseif ($aliasIsGithub) {
                        $foundUrls += $alias
                    }
                }
                if ($foundUrls.Count -gt 0) {
                    $attachments = $foundUrls -join "; "
                }
                else {
                    $attachments = "No GitHub links"
                }
            }
            else {
                Write-Host "No references found in task details"
            }

            # Get assigned users
            $assignmentKeys = $task.Assignments.AdditionalProperties.Keys
            $assignments = $task.Assignments.AdditionalProperties

            if ($assignmentKeys.Count -gt 0) {
                # Sort keys by assignedDateTime
                $sortedKeys = $assignmentKeys | Sort-Object { [datetime]$assignments[$_].assignedDateTime }

                $mainContributorKey = $sortedKeys[0]
                $reviewerKey = if ($sortedKeys.Count -gt 1) { $sortedKeys[-1] } else { $null }

                foreach ($userId in $assignmentKeys) {
                    $assignment = $assignments[$userId]
                    $assignedDateTime = [datetime]$assignment.assignedDateTime

                    if ($selection -eq '3' -and ($assignedDateTime -lt $startDate -or $assignedDateTime -ge $endDate)) {
                        continue
                    }

                    $role = if ($userId -eq $mainContributorKey) { "Main Contributor" } elseif ($userId -eq $reviewerKey) { "Reviewer" } else { "" }

                    try {
                        $user = Get-MgUser -UserId $userId -ErrorAction Stop
                        $userName = $user.DisplayName
                    }
                    catch {
                        Write-Host "Error getting user details: $_"
                        $userName = "$userId (Unable to get name)"
                    }

                    # Add task to collection with individual user
                    $taskData += [PSCustomObject]@{
                        Name        = $userName
                        Role        = $role
                        Task        = $task.Title
                        Bucket      = $bucketName
                        Attachments = $attachments
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to process task: $($task.Title). Error: $_"
            # Add error entry
            $taskData += [PSCustomObject]@{
                Name        = "Error Processing"
                Role        = ""
                Task        = $task.Title
                Bucket      = $bucketName
                Attachments = "Error retrieving attachments"
            }
        }
    }

    # Sort the data by Name
    $taskData = $taskData | Sort-Object Name

    # Display preview of the data
    Write-Host "`nPreview of exported data:"
    $taskData | Format-Table -AutoSize

    # Get output filename from user
    $outputFile = Read-Host -Prompt "Enter the desired name for the CSV file"
    if (-not ($outputFile.EndsWith(".csv"))) {
        $outputFile = "$outputFile.csv"
    }

    # Export to CSV
    $taskData | Export-Csv -Path $outputFile -NoTypeInformation -Force
    Write-Host "Tasks exported successfully to $outputFile"

}
catch {
    Write-Error "Failed to fetch tasks. Error: $_"
}

Write-Host "Script made by Ibitope Fatoki. Github ibi420"
Write-Host "Script completed."
Read-Host "Press Enter to exit"
