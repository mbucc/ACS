ad_page_contract {
    presents options to user of versions to delete

    @author dh@arsdigita.com
    @creation-date July 1999
    @cvs-id $Id
} {
    file_id:integer
    version_id:integer
    return_url
    {group_id ""}
}

set title "Delete a file version"

# Determine if we are working in a Group, or our personal space
# this is based if no group_id was sent - then we are in
# our personal area - otherwise the group defined by group_id
set exception_text ""
set exception_count 0

if { [info exists group_id] && ![empty_string_p $group_id]} {
    set group_name [db_string unused "
    select group_name 
    from   user_groups 
    where  group_id=:group_id"]
    
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" "$return_url $group_name" "$title"]
} else {
    set navbar [ad_admin_context_bar "index.tcl {[ad_parameter SystemName fs]}" $title]
}

## does the file exist?
if { [empty_string_p $file_id] } {
    ad_returnredirect $return_url
    return 
}

## does the version exist?
if { [empty_string_p $version_id] || [db_0or1row version_id_exists_p "select version_id from fs_versions where version_id=:version_id"]==0 } {
    ad_returnredirect $return_url
} 

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_title [db_string unused "select file_title from fs_files where file_id=:file_id"]
set number_of_versions [db_string unused "select count(version_id) from fs_versions where file_id=:file_id"]

set html "[ad_admin_header $title ]
<h2> $title </h2>
$navbar
<hr>"

set version_date [db_string unused "select to_char(creation_date,'MM/DD/YY HH24:MI') from fs_versions 
                                    where version_id=:version_id"]

if {$number_of_versions >1 } {
append html "
     Are you sure you want to delete the version of <b>$file_title</b> dated $version_date?<br>
     Since you are an administrator, <b>delete will really delete from the database</b>.
     <form action=$return_url method=post>
      <input type=submit value=\"No, Don't Delete\" >
    </form>
    <form action=version-delete-2 method=post >
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
    <form action=file-delete-2 method=post >
     <input type=submit value=\"Yes, Delete!\" >
     
     [export_form_vars file_id  return_url] 
    </form>
    [ad_admin_footer]
    "
}

doc_return  200 text/html $html


