#
# /www/education/class/admin/syllabus-edit.tcl
#
# by randy@arsdigita.com, aileen@mit.edu, January 2000
#
# this allows you to select a file to be uploaded as the syllabus
#
# $Id: syllabus-edit.tcl,v 1.1.2.2 2000/03/16 06:20:32 aure Exp $

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set selection [ns_db 0or1row $db "
                   select version_id, 
                          file_extension,
                          file_id,
                          url
                     from fs_versions_latest, 
                          edu_classes 
                    where file_id = syllabus_id 
                      and class_id = $class_id"] 

if {$selection != ""} {
    set_variables_after_query
    set current_syllabus_string "View the <a href=\"/file-storage/download/syllabus.$file_extension?version_id=$version_id\">Current Syllabus</a><Br><Br>"
    set target_url "upload-version.tcl"
} else {
    set current_syllabus_string ""
    # since there is not already a file_id for the syllabus, generate one
    set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]
    set target_url "upload-new.tcl"
}


set return_url "syllabus-edit-2.tcl?file_id=$file_id"
set read_permission ""
set write_permission ta
set file_title Syllabus


# lets get the version_id

set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]

set parent_id [database_to_tcl_string $db "select handouts_folder_id from edu_classes where class_id = $class_id"]

ns_db releasehandle $db

set version_description ""

set return_string "
[ad_header "Class Syllabus @ [ad_system_name]"]

<h2>Upload Class Syllabus</h2>

[ad_context_bar_ws [list "../one.tcl" "$class_name"] [list "" "Administration"] "Upload Class Syllabus"]

<hr>
<blockquote>
$current_syllabus_string

<form enctype=multipart/form-data method=POST action=\"$target_url\">

[export_form_vars file_id version_id read_permission write_permission return_url file_title parent_id version_description]

Upload a New Syllabus:
<br><br>

URL: &nbsp &nbsp <input type=input name=url size=40>
<Br><br>
 - <i>or</i> -
<br><Br>
File Name:

[ad_space]

<input type=file name=upload_file size=20>
<Br><FONT SIZE=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".
</FONT>

<br><Br>

<input type=submit value=\"Upload\">

</blockquote>
[ad_footer]
"


ns_return 200 text/html $return_string






