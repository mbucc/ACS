# /www/download/admin/download-edit.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  edits downloadable file iformation
#
# $Id: download-edit.tcl,v 3.1.6.2 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id)
# download_id

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none
set user_id [download_admin_authorize $db $download_id]

if {[catch {set selection [ns_db 1row $db "
select download_name, 
       directory_name, 
       description, 
       html_p
from   downloads 
where  download_id = $download_id"]} errmsg]} {
    
    ad_scope_return_error \
	    "Error in finding the data" \
	    "We encountered an error in querying the database for
    your object. Here is the error that was returned:   
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>" $db
    return
}

set_variables_after_query

# -----------------------------------------------------------------------------

ns_return 200 text/html "
[ad_scope_header "Edit the entry for $download_name" $db]
[ad_scope_page_title "Edit the entry for $download_name" $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	"Edit"]

<hr>

<form method=POST action=download-edit-2.tcl>

[export_form_scope_vars download_id]

<table>
<tr>
<th align=right>Download Name:</th>
<td>
<input type=text size=40 MAXLENGTH=100 name=download_name [export_form_value download_name]>
</td>
</tr>

<tr>
<th align=right valign=top>&nbsp;<br>Description:</th>
<td>
<textarea name=description cols=60 rows=8 wrap=soft>[ns_quotehtml $description]
</textarea>
</td>
</tr>

<tr>
<th align=right>Text above is:</th>
<td>
<select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select>
</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>
</table>
</form>

[ad_scope_footer]
"
