# $Id: version-delete.tcl,v 3.1.2.1 2000/04/28 15:09:01 carsten Exp $
# version-delete.tcl
#
# by dh@arsdigita.com, July 1999
#
# presents options to user of versions to delete

set_the_usual_form_variables 

# file_id, object_type, return_url, maybe group_id
 

set title "Delete a file version"
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
    
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" "$return_url $group_name" "$title"]
} else {
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" $title]
}
## does the file exist?
if {(![info exists file_id])||([empty_string_p $file_id])} {
    ad_returnredirect $return_url
    return 
}

## does the version exist?
if {(![info exists version_id]) || ([empty_string_p $version_id]) || ([catch {database_to_tcl_string $db "select 1 from fs_versions where version_id=$version_id"} junk]) } {
    ad_returnredirect $return_url
} 

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [database_to_tcl_string $db "select file_title from fs_files where file_id=$file_id"]
set number_of_versions [database_to_tcl_string $db "select count(version_id) from fs_versions where file_id=$file_id"]

set html "[ad_admin_header $title ]
<h2> $title </h2>
$navbar
<hr>"

set version_date [database_to_tcl_string $db " select to_char(creation_date,'MM/DD/YY HH24:MI') from fs_versions where version_id=$version_id"]

if {$number_of_versions >1 } {
append html "
     Are you sure you want to delete the version of <b>$file_title</b> dated $version_date?<br>
     Since you are an administrator, <b>delete will really delete from the database</b>.
     <form action=$return_url method=post>
      <input type=submit value=\"No, Don't Delete\" >
    </form>
    <form action=version-delete-2.tcl method=post >
     <input type=submit value=\"Yes, Delete!\" >
     
     [export_form_vars file_id version_id return_url] 
    </form>
    [ad_admin_footer]
    "
} else { 
append html "
     Are you sure you want to delete the <em>only</em> version of <b>$file_title</b>?<br>
     Since you are an administrator, <b>delete will really delete from the database</b>.
     <form action=$return_url method=post>
      <input type=submit value=\"No, Don't Delete\" >
    </form>
    <form action=file-delete-2.tcl method=post >
     <input type=submit value=\"Yes, Delete!\" >
     
     [export_form_vars file_id  return_url] 
    </form>
    [ad_admin_footer]
    "
}
    ns_return 200 text/html $html






