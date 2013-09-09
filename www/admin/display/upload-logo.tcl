# /www/admin/display/upload-logo.tcl

ad_page_contract {
    uploading logo to be displayed on pages

    @author tarik@arsdigita.com
    @creation-date 12/26/99

    @cvs-id upload-logo.tcl,v 3.3.2.8 2000/09/22 01:34:42 kevin Exp    
} {
    return_url:optional
    user_id:optional,integer
}

ad_scope_error_check

set page_title "Logo Settings"

set page_content "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  $page_title]
<hr>
"

append html "
<table cellpadding=4>
"

set logo_exists_p [db_0or1row display_select_query "
          select logo_id 
          from page_logos 
          where [ad_scope_sql]" ]

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
<form enctype=multipart/form-data method=post action=upload-logo-2>
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
	set enable_html "we don't have logos for the public right now"
	set enabled_state "disabled"
    }
    group {
	if { $logo_exists_p } {
	    if [db_string display_select_query_2 "
	                     select decode (logo_enabled_p, 't', '1', '0') 
                             from page_logos 
                             where logo_id = :logo_id"] {
		set enabled_state "enabled"
		set enable_state "disable"
	    } else {

		set enabled_state "disabled"
		set enable_state "enable"
	    }
	    
	    set enable_html "<a href=\"toggle-logo-enabled?[export_url_scope_vars logo_id]\">$enable_state</a>"
	    ns_log Notice "LOGO EXIST"
	} else {
	    ns_log Notice "LOGO DOESN'T EXIST"
	}
    }
    user {
	# if we add support for logo for personal pages this can do something better
	set enable_html "we don't have logos for users right now"
	set enabled_state "disabled"
    }
}

db_release_unused_handles
	
if { $logo_exists_p } {
    append html "
    <tr>
    <th>Logo is $enabled_state
    <td>$enable_html
    </tr>
    "
}

append html "
</table>

<p>
<input type=submit value=\"Upload\">
</form>
"

if { $logo_exists_p } {
    set note_html "[ad_style_bodynote "Your browser may cache the logo, in which case you won't be able to see changed logo immediately. <br> You will be able to see the new logo once you restart your browser." ]"
} else {
    set note_html ""
}

append page_content "
<blockquote>
$html
</blockquote>
$note_html
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content




