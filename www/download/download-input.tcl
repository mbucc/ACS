# /www/download/download-info.tcl

ad_page_contract {
    Display information about an item so the user can decide whether they want
    to proceed.

    @param version_id the version in question
    
    @author Ron Henderson (ron@arsdigita.com)
    @cvs-id download-input.tcl,v 3.12.2.7 2000/10/06 22:53:42 ron Exp
} {
    version_id:integer
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

# Check for scope
ad_scope_error_check 


# Grab all the information we need about this download item

db_1row info_for_one_version "
select download_name,
       version,
       pseudo_filename,
       description, 
       html_p, 
       version_description,
       d.scope as file_scope, 
       d.group_id as gid, 
       d.directory_name as directory,
       version_html_p
from   downloads d, 
       download_versions v
where  v.version_id  = :version_id
and    v.download_id = d.download_id"
                   
set version_name $download_name

if { ![empty_string_p $version] } {
    append version_name  " v." $version
}
 
if {$file_scope == "public"} {
    set full_filename "[ad_parameter DownloadRoot download]$directory/$version_id.file"
} else {
    # scope is group
    # download_authorize $did
    set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
}
    
# Check authorization status

set user_authorization_status [db_string user_state "
select download_authorized_p(:version_id, :user_id) from dual"]

switch $user_authorization_status {

    # Authorized but anonymous users are asked to sign in before downloading

    authorized {
	if {$user_id == 0} {
	    set action_string "
	    <p>
	    Please 
	    <a href=/register/?return_url=[ns_urlencode [ns_conn url]?[export_url_scope_vars version_id]]>register first</a> 
	    so that we can notify you about future upgrades and related information.
	    <p>"
	}

	set new_log_id [db_string next_log_id "
	select download_log_id_sequence.nextval from dual"]

	append action_string "
	<form method=post action=\"/download/files/$version_id/$pseudo_filename\">
	[util_kill_cache_form]
	[export_form_scope_vars new_log_id]
	
	<p>Reason for Download: 
	[ad_space 3]<input type=text name=download_reasons size=40>
	[ad_space 3]<input type=submit value=\"Submit and download\">
	</p>"
    }

    # Download restricted to registered users

    reg_required {
	set action_string "
	<p>
	You must <a href=/register/?return_url=[ns_urlencode [ns_conn url]?[export_url_scope_vars version_id]]>register</a> before you can download this item.
	"
    }

    # Otherwise the user isn't authorized, so just reject them

    default {
	ad_return_warning "Not authorized" "You are not authorized to see this page"
	return
    }
}

set title "Information about $version_name"

# -----------------------------------------------------------------------------

doc_return 200 text/html "
[ad_scope_header $title]
[ad_scope_page_title $title]
[ad_scope_context_bar_ws_or_index [list "?[export_url_scope_vars]" Download] "User Feedback"]

<hr>

<blockquote>
<p>
[util_maybe_convert_to_html $description $html_p] 
<p>
[util_maybe_convert_to_html $version_description $version_html_p] 
<p>
Filesize : [expr [file size $full_filename] / 1000]k

$action_string

</blockquote>

[ad_scope_footer]
"

