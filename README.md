Rally-TestFolder-DeepMove
=========================

Usage: ruby test_folder_deep_move.rb

Requirements:

- Ruby 1.9.3 (not yet compatible with Ruby 2.0)
- rally_api 0.9.20 (tested with)
- Instructions for installing and configuring Ruby and the rally_api gem on Windows are included in the README

Edit / update the following variables located in my_vars.rb to suit your environment:

<pre>
$my_base_url                     = "https://rally1.rallydev.com/slm"
$my_username                     = "user@company.com"
$my_password                     = "topsecret"
$wsapi_version                   = "1.43"
$my_workspace                    = "My Workspace"
$my_project                      = "My Project 1"

# Target project:
$target_project_name             = "My Project 2"

# Source Test Folder
$source_test_folder_formatted_id = "TF5"
</pre>

Specify the User-Defined variables above. Script will move an entire
Test Folder hierarchy, including child Folders, Test Cases, and their
Test Steps and Attachments and Tags, to a Test Folder hierarchy that
the script will create in the target project. The Target Project must
reside in the same Rally Workspace.

The script does not delete the Test Folder containers themselves from
the Source Project. The Test Cases will be moved into a new Test
Folder hierarchy in the Target Project. The Source Test Folders will
remain in the Source Project, but they will be empty of Test Cases.