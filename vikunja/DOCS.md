# Vikunja Add-on

Self-hosted task management for your household, running directly on Home Assistant.

## How it works

This add-on runs [Vikunja](https://vikunja.io), an open-source task manager, as a Home Assistant add-on.
It appears in your HA sidebar and can also be accessed externally from your phone.

## First-time setup

1. Start the add-on
2. Open Vikunja from the sidebar
3. Register your account
4. Have your household members register their accounts
5. Go to add-on configuration and disable **Enable Registration**
6. Create a shared project and invite your household members

## Shared tasks

Vikunja supports multiple users with shared projects:

- Create a project (e.g., "Family Tasks")
- Open the project, click the share icon
- Invite other users by username
- Both users can now add, complete, and manage tasks in the shared project
- Each user also has their own private task lists

## External access

To access Vikunja from your phone outside your home network:

1. Set up a reverse proxy (see the README for examples)
2. Configure the **External URL** option in the add-on settings
3. Restart the add-on

## Data storage

All data is stored locally on your Home Assistant system:

- **Database:** SQLite at `/data/vikunja.db`
- **File attachments:** `/data/files/`

Data persists across add-on restarts and updates.
