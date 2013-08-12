# Copyright 2002-2013 Rally Software Development Corp. All Rights Reserved.

require 'rally_api'

$my_base_url       = "https://rally1.rallydev.com/slm"
$my_username       = "user@company.com"
$my_password       = "password"
$my_workspace      = "My Workspace"
$my_project        = "My Project"
$wsapi_version     = "1.43"

# Source Test Folder
$source_test_folder_formatted_id = "TF8"
$target_project_name             = "My Project 2"

# Make no edits below this line!!
# =================================

#Setting custom headers
$headers                            = RallyAPI::CustomHttpHeader.new()
$headers.name                       = "Test Folder Deep Move"
$headers.vendor                     = "Rally Labs"
$headers.version                    = "0.50"

# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

def move_test_folder(source_test_folder, target_project, parent_of_target_folder)

	# Source Test Folder Info
	# Populate full object for Source Test Folder
	full_source_test_folder = source_test_folder.read

	# Create Target Test Folders
	target_test_folder_fields = {}

	# Only set parent folder if we have a parent
	if parent_of_target_folder != nil then
		target_test_folder_fields["Parent"]  = parent_of_target_folder		
	end
	target_test_folder_fields["Name"]    = source_test_folder["Name"]
	target_test_folder_fields["Project"]   = target_project

	# Call Rally to Create Target Test Folder
	target_test_folder = @rally.create(:testfolder, target_test_folder_fields)
	target_test_folder.read
	target_test_folder_formatted_id	= target_test_folder["FormattedID"]

	if parent_of_target_folder == nil then
		puts "Created new top-level Test Folder: " + target_test_folder["FormattedID"] + ": " + target_test_folder["Name"]
	else
		puts "Created new child Test Folder: " + target_test_folder["FormattedID"] + ": " + target_test_folder["Name"]
	end

	# Grab collection of Source Test Cases
	source_test_cases = source_test_folder["TestCases"]

	# Loop through Source Test Cases and Move to Target
	source_test_cases.each do |source_test_case|
	
		test_case_to_update = source_test_case.read
		source_test_case_formatted_id = test_case_to_update["FormattedID"]

		target_project_full_object = target_project.read
		target_project_name = target_project_full_object["Name"]

		source_project = full_source_test_folder["Project"]
		source_project_full_object = source_project.read
		source_project_name = source_project_full_object["Name"]

		puts "Source Project Name: #{source_project_name}"
		puts "Target Project Name: #{target_project_name}"

		# Test if the source project and target project are the same
		source_target_proj_match = source_project_name.eql?(target_project_name)

		begin
			# If the target Test Folder is in a different Project, we have to do some homework first:
			# "un-Test Folder" the project
			# Assign the Test Case to the Target Project
			# Assign the Test Case to the Target Test Folder
			if !source_target_proj_match then
				fields = {}
				fields["TestFolder"] = ""
				test_case_updated = @rally.update(:testcase, test_case_to_update.ObjectID, fields) #by ObjectID
				puts "Test Case #{source_test_case_formatted_id} successfully dissociated from: #{$source_test_folder_formatted_id}"

				# Get full object on Target Project and assign Test Case to Target Project
				fields = {}
				fields["Project"] = target_project_full_object
				test_case_updated = @rally.update(:testcase, test_case_to_update.ObjectID, fields) #by ObjectID
				puts "Test Case #{source_test_case_formatted_id} successfully assigned to Project: #{target_project_name}"
			end

			# Change the Test Folder attribute on the Test Case
			fields = {}
			fields["TestFolder"] = target_test_folder
			test_case_updated = @rally.update(:testcase, test_case_to_update.ObjectID, fields) #by ObjectID
			puts "Test Case #{source_test_case_formatted_id} successfully moved to #{target_test_folder_formatted_id}"
		rescue => ex
			puts "Test Case #{source_test_case_formatted_id} not updated due to error"
			puts ex
		end		
	end
	
	# Proceed on to child Test Folders, if applicable
	child_folders = source_test_folder["Children"]

	# Loop through children and call self recursively to walk folder tree and move fully
	unless child_folders.nil? then
		child_folders.each do | this_child_folder |
			this_child_folder.read
			move_test_folder(this_child_folder, target_project, target_test_folder)
		end
	end
end

begin

	#==================== Make a connection to Rally ====================
	config                  = {:base_url => $my_base_url}
	config[:username]       = $my_username
	config[:password]       = $my_password
	config[:workspace]      = $my_workspace
	config[:project]        = $my_project
	config[:version]        = $wsapi_version

	@rally = RallyAPI::RallyRestJson.new(config)
	# Lookup source Test Folder
	source_test_folder_query = RallyAPI::RallyQuery.new()
	source_test_folder_query.type = :testfolder
	source_test_folder_query.fetch = true
	source_test_folder_query.query_string = "(FormattedID = \"" + $source_test_folder_formatted_id + "\")"

	source_test_folder_result = @rally.find(source_test_folder_query)

	# Lookup Target Project
	target_project_query = RallyAPI::RallyQuery.new()
	target_project_query.type = :project
	target_project_query.fetch = true
	target_project_query.query_string = "(Name = \"" + $target_project_name + "\")"

	target_project_result = @rally.find(target_project_query)

	if source_test_folder_result.total_result_count == 0
		puts "Source Test Folder: " + $source_test_folder_formatted_id + "not found. Exiting."
		exit
	end

	if target_project_result.total_result_count == 0
		puts "Target Project: " + $target_project + "not found. Target must exist before moving."
		exit
	end

	source_test_folder = source_test_folder_result.first()
	target_project = target_project_result.first()
	
	# Proceed to recursively move the Test Folder
	move_test_folder(source_test_folder, target_project, nil)	

	puts "Move completed!"
end