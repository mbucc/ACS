# /www/download/admin/download-add-2.tcl
ad_page_contract {
    target page to add new downloadable file

    @param download_name the name for the file
    @param directory_name the directory the file goes in
    @param description description of the file
    @param html_p is the description in html?
    @param download_id the new ID for the download
    @param scope
    @param group_id
    @param return_url where to go when done

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add-2.tcl,v 3.11.2.6 2000/09/24 22:37:13 kevin Exp
} {
    download_name:trim,notnull
    directory_name:trim,notnull
    description:html
    html_p
    download_id:integer,notnull
    group_id:integer,optional
    scope:optional
    {return_url ""}
}

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

set user_id [ad_verify_and_get_user_id]
set creation_ip_address [ns_conn peeraddr]

# Now check to see if the input is good as directed by the page designer

# can't set this as a default in ad_page_contract because scope, etc
# aren't set yet

if { ![info exists return_url] } {
    set return_url "index?[export_url_scope_vars ]"
}

page_validation {
    if {[string length $description] > 4000} {
	error "\"description\" is too long\n"
    }
}


# -----------------------------------------------------------------------------

set bind_vars [ad_tcl_vars_to_ns_set download_id download_name \
	directory_name description html_p user_id creation_ip_address]

set double_click_p [db_string dbl_click_check "
select count(*) from downloads 
where download_id = :download_id" -bind $bind_vars]

if {$double_click_p} {
    # a double click
    ad_returnredirect index?[export_url_scope_vars]
}

if {$scope == "public"} {
    set dir_full_name "[ad_parameter DownloadRoot download]$directory_name"
} else {
    # scope is group
    set dir_full_name "[ad_parameter DownloadRoot download]groups/$group_id/$directory_name"
}

set aol_version [ns_info version]

if { $aol_version < 3.0 } {
    set mkdir_command "download_mkdir $dir_full_name"  
} else {
    set mkdir_command "file mkdir $dir_full_name"
}

if [catch {eval $mkdir_command } errmsg] {
    # mkdir command failed for some reason

    ad_return_complaint 1 "
    <li>Folder $dir_full_name could not be created because of the following error:
    <blockquote>$errmsg</blockquote>
    If this is the first download for this system, then one possibility
    is that nsadmin doesn't have write privileges for the directory,
    in which case you should check with your system administrator."

    return
}

# Insert the new item into the downloads table

db_dml download_insert "
insert into downloads
 (download_id, 
  download_name, 
  directory_name, 
  description, 
  html_p, 
  creation_date, 
  creation_user, 
  creation_ip_address, 
  [ad_scope_cols_sql]) 
values 
 (:download_id, 
  :download_name, 
  :directory_name, 
  :description, 
  :html_p, 
  sysdate, 
  :user_id, 
  :creation_ip_address, 
  [ad_scope_vals_sql])"

ad_returnredirect index?[export_url_scope_vars]

