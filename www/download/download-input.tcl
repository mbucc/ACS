# /www/download/download-input.tcl
# 
# Display information about an item so the user can decide whether they want
# to proceed.
#
# Date:     Sun Jan 23 16:54:28 EST 2000
# Author:   ahmeds@mit.edu
# Purpose:  this page takes input from the user
#
# $Id: download-input.tcl,v 3.2.4.2 2000/05/18 00:05:14 ron Exp $
# -----------------------------------------------------------------------------

ad_page_variables {version_id}
    
set user_id [ad_verify_and_get_user_id]

# Check for scope
ad_scope_error_check 

set db [ns_db gethandle]

# Grab all the informatino we need about this download item

set selection [ns_db 1row $db "
select download_name || ' v.' || version as version_name,
       pseudo_filename,
       description, 
       html_p, 
       version_description, 
       version_html_p
from   downloads d, 
       download_versions v
where  v.version_id  = $version_id
and    v.download_id = d.download_id"]
                   
set_variables_after_query

# Check authorization status

set user_authorization_status [database_to_tcl_string $db "
select download_authorized_p($version_id, $user_id) from dual"]

switch $user_authorization_status {

    # Authorized but anonymous users are asked to sign in before downloading

    authorized {
	if {$user_id == 0} {
	    set action_string "
	    <p>
	    Please 
	    <a href=/register/index?return_url=[ns_urlencode [ns_conn url]?[export_url_scope_vars version_id]]>register first</a> 
	    so that we can notify you about future upgrades and related information.
	    <p>"
	}

	set new_log_id [database_to_tcl_string $db "select download_log_id_sequence.nextval from dual"]

	append action_string "
	<form method=post action=\"/download/files/$version_id/$pseudo_filename\">
	[util_kill_cache_form]
	[export_form_scope_vars new_log_id]
	
	<p>Reason for Download: 
	<input type=text name=download_reasons size=40>
	<input type=submit value=Submit>
	</p>"
    }

    # Download restricted to registered users

    reg_required {
	set action_string "
	<p>
	You must <a href=/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[export_url_scope_vars version_id]]>register</a> before you can download this item.
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

ns_return 200 text/html "
[ad_scope_header $title $db]
[ad_scope_page_title $title $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl" Download] "User Feedback"]

<hr>

<blockquote>
<p>
[util_maybe_convert_to_html $description $html_p] 
<p>
[util_maybe_convert_to_html $version_description $version_html_p] 
<p>

$action_string

</blockquote>

[ad_scope_footer]
"


