# $Id: upload-logo.tcl,v 3.0 2000/02/06 03:16:34 ron Exp $
# File:     /admin/css/upload-logo.tcl
# Date:     12/26/99
# Contact:  tarik@arsdigita.com
# Purpose:  uploading logo to be displayed on pages
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables 0
# maybe return_url
# maybe scope, maybe scope related variables (group_id, user_id)

ad_scope_error_check

set db [ns_db gethandle]

ReturnHeaders

set page_title "Logo Settings"

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  $page_title]
<hr>
"

append html "
<table cellpadding=4>
"

set selection [ns_db 0or1row $db "select logo_id from page_logos where [ad_scope_sql]"]
if { [empty_string_p $selection] } {
    set logo_exists_p 0
} else {
    set logo_exists_p 1
    set_variables_after_query
}

if { $logo_exists_p } {
    append html "
    <tr>
    <th align=left>Current Logo
    <td><img src=\"/display/get-logo.tcl?[export_url_scope_vars]\" ALT=Logo border=1>
    </tr>
    "
} else {
    append html "
    <tr>
    <th>Currently no logo exists.
    </tr>
    <tr><td></td></tr><tr><td></td></tr><tr><td></td></tr>
    "
}

append html "
<form enctype=multipart/form-data method=post action=\"upload-logo-2.tcl\">
[export_form_scope_vars return_url]
<tr>
"

if { $logo_exists_p } {
    append html "
    <th align=left>Change Logo
    "
} else {
    append html "
    <th align=left>Upload New Logo
    "
}

append html "
<td>
<input type=file name=upload_file size=20>
</tr>
"

ns_log Notice "SCOPE: $scope"

switch $scope {
    public {
	# this may be later set using parameters file
	set logo_enabled_p 0
    }
    group {
	if { $logo_exists_p } {
	    set logo_enabled_p [database_to_tcl_string $db "
	    select decode(logo_enabled_p, 't', 1, 0)
	    from page_logos
	    where logo_id=$logo_id"]
	    ns_log Notice "LOGO EXIST"
	} else {
	    set logo_enabled_p 0
	    ns_log Notice "LOGO DOESN'T EXIST"
	}
    }
    user {
	# if we add support for logo for personal pages this can do something better
	set logo_enabled_p 0
    }
}
	
if { $logo_exists_p } {
    if { $logo_enabled_p } {
	append html "
	<tr>
	<th>Logo is enabled 
	<td><a href=\"toggle-logo-enabled.tcl?[export_url_scope_vars logo_id]\">disable</a>
	</tr>
	"
    } else {
	append html "
	<tr>
	<th>Logo is disabled
	<td><a href=\"toggle-logo-enabled.tcl?[export_url_scope_vars logo_id]\">enable</a>
	</tr>
	"
    }
}

append html "
</table>

<p>
<input type=submit value=\"Upload\">
</form>
"

ns_db releasehandle $db

if { $logo_exists_p } {
    set note_html "[ad_style_bodynote "Your browser may cache the logo, in which case you won't be able to see changed logo immediately. <br> You will be able to see the new logo once you restart your browser." ]"
} else {
    set note_html ""
}

ns_write "
<blockquote>
$html
</blockquote>
$note_html
[ad_scope_admin_footer]
"






