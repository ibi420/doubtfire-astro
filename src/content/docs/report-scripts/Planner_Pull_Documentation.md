# Planner Task Puller Script Documentation

## Overview

This PowerShell script connects to Microsoft Graph to retrieve tasks from a specified Microsoft Planner plan. It is a flexible, menu-driven tool that allows for powerful filtering and multiple export formats.

The script can store connection details for multiple plans in a `config.json` file, allowing for easy switching between them. It fetches task details, including bucket names, completion status, attachments (specifically looking for GitHub links), and assigned users with their roles (Main Contributor, Reviewer). The collected data can then be exported to a **CSV**, **JSON**, or **Markdown** file.

For CSV and Markdown exports, the script allows you to interactively select which data columns to include, making it ideal for generating custom reports.

## Key Features

*   **Multiple Filtering Options:** Pull tasks by assignment, date range, completion status, or specific bucket.
*   **Multiple Export Formats:** Export your data to CSV, JSON, or a report-ready Markdown table.
*   **Customizable Columns:** For CSV and Markdown exports, you can choose exactly which columns to include.
*   **Plan Management:** An interactive utility to add, delete, and view your saved Planner plans.
*   **Robust Logging:** Creates a detailed log file in the `\logs` directory, with a configurable log level for easier debugging.
*   **Environment Checks:** Automatically checks for the required PowerShell version (7+) and `Microsoft.Graph` module to prevent errors.

## Prerequisites

*   **PowerShell 7 or higher.** The script will not run on older versions like Windows PowerShell 5.1. You can get PowerShell 7 from the [Microsoft Page](https://learn.microsoft.com/en-gb/powershell/scripting/install/installing-powershell?view=powershell-7.5) or [GitHub](https://github.com/PowerShell/PowerShell).
*   An internet connection.
*   A Microsoft 365 account with access to Microsoft Planner.
*   The `Microsoft.Graph` PowerShell module.

## Setup

Before running the script for the first time, you need to install the `Microsoft.Graph` module. Open a PowerShell 7 terminal and run the following command:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
```

## Finding Your Plan ID

The Plan ID is required to fetch tasks from a specific plan. You can find the Plan ID in the URL of your Planner board.

1.  Go to [Microsoft Planner](https://tasks.office.com/).
2.  Open the plan you want to use.
3.  Look at the URL in your browser's address bar. It will look something like this:
    `https://tasks.office.com/your-tenant.com/en-US/Home/Plan?planId=YOUR_PLAN_ID&ownerId=...`
4.  The `planId` is the alphanumeric string that follows `planId=`. Copy this value.

### Video Tutorial

For a visual guide on how to find the Plan ID, please watch this video (Covers Two methods):

[Plan ID Tutorial](https://deakin365-my.sharepoint.com/:v:/g/personal/s223739207_deakin_edu_au/EeAm2dpPc3VGrh6DHzyHkOcBig0my4m3UYWG5HmGtFG09A?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=TVSwwN)

## How to Run the Script

[Script Demo](https://deakin365-my.sharepoint.com/:v:/g/personal/s223739207_deakin_edu_au/ETM6TddvX_9KhSbykjwiinMBgSIsZp8inzyoABN32SEFMg?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=7QDevO)

1.  Open a **PowerShell 7** terminal (`pwsh.exe`).
2.  Navigate to the directory where the script is located.
3.  Execute the script by running: `.\Planner_pull.ps1`
4.  Follow the on-screen prompts.

### Main Menu

The script presents a main menu with the following options:

*   **1-5 (Data Pulling Options):** Choose how you want to filter the tasks you retrieve.
    *   1. Pull all tasks (including unassigned)
    *   2. Pull only tasks with assigned users
    *   3. Pull tasks of assigned users based on a date range
    *   4. Pull tasks from a specific bucket
    *   5. Pull tasks by completion status (Not Started, In Progress, Completed)
*   **6. Manage saved plans:** Enter a utility menu to add or delete plans from your `config.json` file.
*   **Q. Quit:** Exit the script.

### Data Export Workflow

After you select a data pulling option (1-5) and retrieve the tasks:

1.  **Data Preview:** A preview of the data is shown in the console.
2.  **Choose Export Format:** You will be prompted to choose an export format: **CSV**, **JSON**, or **Markdown**.
3.  **Select Columns (for CSV/Markdown):** If you choose CSV or Markdown, a menu will appear listing all available data columns. You can then enter the numbers of the columns you wish to keep in your report (e.g., `1,3,5`).
4.  **Enter Filename:** Provide a name for the output file.

## How it Works

1.  **Pre-flight Checks:** The script first checks for two things:
    *   That it is being run in **PowerShell 7 or higher**.
    *   That the `Microsoft.Graph` module is installed.
2.  **User Selection:** It prompts the user to choose a filtering method from the main menu.
3.  **Authentication:** It connects to the Microsoft Graph API using a device code authentication flow.
4.  **Plan ID Configuration (`config.json`):**
    *   The script reads the `config.json` file to find any saved plans. This file is created automatically.
    *   If saved plans are found, it displays them in a menu for the user to select.
    *   The **Manage saved plans** option provides a dedicated utility for adding and deleting plans from this file.
5.  **Data Retrieval & Processing:**
    *   It fetches tasks, buckets, and user details from the Graph API based on the user's filter selections.
    *   **Attachments:** It intelligently scans task references for GitHub links.
    *   **User Roles:** It determines user roles ("Main Contributor" or "Reviewer") based on the order of assignment.
6.  **Output:**
    *   The script prompts the user for an export format and an output filename.
    *   For CSV and Markdown, it allows the user to select specific columns.
    *   It compiles all the processed data and exports it to the specified file.
7.  **Logging:** All operations, user choices, and errors are logged to a file in the `.\logs` directory for easy debugging.

## Output Columns

The following data columns are available for export:

*   **Name:** The display name of the user assigned to the task.
*   **Role:** The role of the user for that task (Main Contributor, Reviewer, or blank).
*   **Task:** The title of the Planner task.
*   **Bucket:** The name of the bucket the task belongs to.
*   **Attachments:** A semicolon-separated list of GitHub URLs found in the task's references.
*   **Status:** The completion status of the task (Not Started, In Progress, or Completed).

**Date of Creation:** 22/08/2025
**Author:** Ibitope Fatoki
