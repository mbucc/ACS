# $Id: file-delete.tcl,v 3.1.2.1 2000/04/28 15:09:00 carsten Exp $
set_the_usual_form_variables 

# file_id, object_type, return_url, maybe group_id
 

set title "Delete $object_type"
set db [ns_db gethandle ]
# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id
set exception_text ""
set exception_count 0

if { [info exists group_id] && ![empty_string_p $group_id]} {
    set group_name [database_to_tcl_string $db "
    select group_name 
    from   user_groups 
    where  group_id=$group_id"]
    
    set navbar [ad_admin_context_bar [list "index.tcl" [ad_parameter SystemName fs]] [list $return_url $group_name] $title]
} else {
    set navbar [ad_admin_context_bar [list "index.tcl" [ad_parameter SystemName fs]] $title]
}
## does the file exist?
if {(![info exists file_id])||([empty_string_p $file_id])} {
    ad_returnredirect $return_url
    return 
}

if {(![info exists object_type])||([empty_string_p $object_type])} {
    incr exception_count 
    incr exception_text "<li>This page may only be accessed from the edit page"
}
## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [database_to_tcl_string $db "select file_title from fs_files where file_id=$file_id"]

set html "[ad_admin_header $title]

<h2> $title </h2>

$navbar

<hr>"

# if this is a folder - get the number of childern
if {$object_type=="Folder"} {
    set sql_child_count "Select count(*) - 1
                         from   fs_files
                         connect by prior file_id = parent_id
                         start with file_id=$file_id "
    set number_of_children [database_to_tcl_string $db $sql_child_count]
    append html "This folder has $number_of_children sub-folders/files. <br>"
}


append html "
     Are you sure you want to delete <b>$file_title</b>?<br>
     Since you are an administrator, <b>delete will really delete from the database</b>.
     <form action=$return_url method=post>
      <input type=submit value=\"No, Don't Delete\" >
    </form>
    <form action=file-delete-2.tcl method=post >
     <input type=submit value=\"Yes, Delete!\" >
     
     [export_form_vars file_id return_url] 
    </form>
    [ad_admin_footer]
"


ns_return 200 text/html $html

