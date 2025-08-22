# Planner Task Puller Script

## Overview

This PowerShell script connects to Microsoft Graph to retrieve tasks from a specified Microsoft Planner plan. It allows the user to pull all tasks, only those assigned to users, or tasks assigned to users within a specific date range. The script can store connection details for multiple plans in a `config.txt` file, allowing for easy switching between them. The script fetches task details, including bucket names, attachments (specifically looking for GitHub links), and assigned users with their roles (Main Contributor, Reviewer). The collected data is then exported to a user-specified CSV file.

## Prerequisites

*   Windows operating system with PowerShell 7. You can grap powershell online at [Microsoft Page](https://learn.microsoft.com/en-gb/powershell/scripting/install/installing-powershell?view=powershell-7.5) or [Github Link](https://github.com/PowerShell/PowerShell?tab=readme-ov-file).
*   An internet connection.
*   A Microsoft 365 account with access to Microsoft Planner.
*   The `Microsoft.Graph` PowerShell module.

## Setup

Before running the script for the first time, you need to install the `Microsoft.Graph` module. Open a PowerShell terminal and run the following command:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
```

## Finding Your Plan ID

The Plan ID is required to fetch tasks from a specific plan. You can find the Plan ID in the URL of your Planner board.

1.  Go to [Microsoft Planner](https://tasks.office.com/).
2.  Open the plan you want to use.
3.  Look at the URL in your browser's address bar. It will look something like this:
    `https://planner.cloud.microsoft/webui/plan/PLANNER_ID/view/board?tid=BOARDID`
4.  The `planId` is the alphanumeric string that follows `plan/`. Copy this value when the script prompts for it.

### Video Tutorial

For a visual guide on how to find the Plan ID, please watch this video (Covers Two methods):

[Plan ID Tutorial](https://deakin365-my.sharepoint.com/:v:/g/personal/s223739207_deakin_edu_au/EeAm2dpPc3VGrh6DHzyHkOcBig0my4m3UYWG5HmGtFG09A?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=TVSwwN)

## How to Run the Script

[Script Demo](https://deakin365-my.sharepoint.com/:v:/g/personal/s223739207_deakin_edu_au/ETM6TddvX_9KhSbykjwiinMBgSIsZp8inzyoABN32SEFMg?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=7QDevO)

1.  Open a PowerShell terminal.
2.  Navigate to the directory where the script is located.
3.  Execute the script by running: `.\planner_pull.ps1`
4.  Follow the on-screen prompts:
    *   **Choose an option:** Select whether to pull all tasks, only assigned ones, or assigned tasks within a date range.
    *   **Enter Date Range (if applicable):** If you choose to filter by date, you will be prompted to enter a start and end date in `YYYY-MM-DD` format.
    *   **Authenticate:** The script uses a device code flow for authentication. You will be prompted to open a URL in a web browser and enter a code to sign in to your Microsoft account. This is required before you can select a plan.
    *   **Choose a Plan:**
        *   If you have saved plans in `config.txt`, you will see a numbered list of them. Enter the number to select a plan.
        *   To add a new plan, choose the "Enter a new Plan ID" option (N).
    *   **Enter New Plan Details (if applicable):**
        *   Enter the new Plan ID.
        *   Enter a descriptive name for the plan. This name is for your reference and will be shown in the selection menu in the future.
    *   **Enter CSV Filename:** Provide a name for the output CSV file.

## How it Works

1.  **Module Check:** The script first checks if the `Microsoft.Graph` module is installed.
2.  **User Selection:** It prompts the user to choose between pulling all tasks, only assigned tasks, or assigned tasks within a date range.
3.  **Date Range Input:** If the user chooses to filter by date, the script prompts for a start and end date.
4.  **Authentication:** It connects to the Microsoft Graph API using a device code authentication flow. This is done early to ensure the script has the necessary permissions for subsequent steps. The script uses a minimal set of permissions required to read tasks and user profiles.
5.  **Plan ID Configuration:**
    *   The script reads the `config.txt` file to find any saved plans.
    *   If saved plans are found, it displays them in a menu for the user to select.
    *   If the user opts to add a new plan, the script prompts for the new Plan ID and a descriptive name.
    *   The new plan entry is appended to `config.txt` in the format `<planid> - <plan name>`. This preserves existing entries.
6.  **Data Retrieval:**
    *   It fetches all tasks for the selected Plan ID using `Get-MgPlannerPlanTask`.
    *   It fetches all buckets in the plan using `Get-MgPlannerPlanBucket` to create a lookup map of bucket IDs to bucket names.
    *   For each task, it retrieves detailed information using `Get-MgPlannerTaskDetail`.
    *   It retrieves user information for assigned users using `Get-MgUser`.
7.  **Data Processing:**
    *   **Date Filtering:** If a date range is provided, the script filters out tasks that were not assigned within that range.
    *   **Bucket Name:** It matches the task's `bucketId` to the previously fetched list of buckets to get the bucket name.
    *   **Attachments:** It intelligently scans task references for GitHub links. It checks both the underlying URL and the display text (alias) for each reference.
    *   If a GitHub link is found in the URL, its display text is checked. If the display text is also a distinct GitHub link, both are preserved for context. Otherwise, only the clean URL is used.
    *   If a GitHub link is found only in the display text, the entire display text is captured.
    This ensures that links are found even if entered incorrectly by users.
    *   **User Roles:** It determines user roles ("Main Contributor" or "Reviewer") based on the order of assignment. The first assigned user is considered the Main Contributor, and the last is the Reviewer.
8.  **Output:**
    *   The script prompts the user for a desired output CSV filename.
    *   It compiles all the processed data.
    *   It displays a preview of the data in the console.
    *   It exports the final data to the specified CSV file.

## Output CSV Columns

*   **Name:** The display name of the user assigned to the task.
*   **Role:** The role of the user for that task (Main Contributor, Reviewer, or blank).
*   **Task:** The title of the Planner task.
*   **Bucket:** The name of the bucket the task belongs to.
*   **Attachments:** A semicolon-separated list of GitHub URLs found in the task's references. If a reference has a descriptive name that is also a distinct GitHub link, it will be formatted as `DisplayText (URL)`. Otherwise, only the clean URL is shown. This column may also contain a message indicating if no GitHub links were found.

**Date of Creation:** 22/08/2025
**Author:** Ibitope Fatoki

