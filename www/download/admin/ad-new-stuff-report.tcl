# /www/download/admin/ad-new-stuff-report.tcl
ad_page_contract {
    displays summary of this download ( who downloaded for what reason) 
    for ad_new_stuff

    @param download_id the file of interest
    @param since_when how recently we are interested
    @param users_table which table.  Either <code>users</code> or
           <code>users_new</code>

    @author ahmeds@mit.edu
    @creation-date 22 April 2000
    @cvs-id ad-new-stuff-report.tcl,v 3.6.2.6 2000/09/24 22:37:13 kevin Exp
} {
    download_id:integer
    since_when
    users_table
}

# -----------------------------------------------------------------------------

page_validation {
    switch $users_table {
	users -
	users_new {}

	default {
	    error "You are a bad, bad man for trying to access
	    a table you aren't supposed"
	}
    }
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

db_1row download_name "
select download_name
from downloads  
where download_id = :download_id"

append html "

<p>
<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 1] User Name [ad_space 1]  </th>
<th  align=center>[ad_space 1] Email [ad_space 1]  </th>
<th  align=center>[ad_space 1] Download Reason[ad_space 1] </th>
</tr>
"

db_foreach user_download_info "
select dl.user_id as user_id, entry_date, version, 
log_id , download_reasons, dl.version_id as version_id
from  download_versions dv, download_log dl, $users_table
where dl.version_id = dv.version_id
and dv.download_id = :download_id
and dl.entry_date > :since_when
and dl.user_id = $users_table.user_id
order by entry_date desc" {

    if { [empty_string_p $user_id] } {
	set email_string "Unavailable"
	set name_string "Anonymous"	
    } else {
	db_1row user_info "
	select email, first_names, last_name
	from users
	where user_id = :user_id "
	
	set email_string "<a href=\"mailto:$email\"><address>$email</address></a>"
	set name_string "$first_names $last_name"	
    }
    

    set dl_reason_html [ad_decode $download_reasons "" None "<a href=download-reason-view?[export_url_scope_vars log_id version_id]>view</a>"]

    set return_url "view-versions-report?[export_url_scope_vars download_id]"

    append html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=left>$email_string</td>
    <td  align=left>[ad_decode $download_reasons "" "none" $download_reasons]</td>
    </tr>
    "

} if_no_rows {
    append html "
    <i>There is no log information in the database about this 
    particular download.</i>
    "
}

append html "
</table>
</center>
<p>
"

# -----------------------------------------------------------------------------

set page_title "Download Report of $download_name since [util_AnsiDatetoPrettyDate $since_when]"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]/" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"]  \
	"View Report"]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
