# /www/download/admin/download-edit.tcl
ad_page_contract {
    Edits information for a downloadable file.

    @param download_id the ID of the file to edit
    @param scope the scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-edit.tcl,v 3.9.2.6 2000/09/24 22:37:15 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none
set user_id [download_admin_authorize $download_id]

if {![db_0or1row download_info "
select download_name, 
       directory_name, 
       description, 
       html_p
from   downloads 
where  download_id = :download_id"]} {
    
    ad_scope_return_error \
	    "Error in finding the data" \
	    "We encountered an error in querying the database for
    your object. Here is the error that was returned:   
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

# -----------------------------------------------------------------------------



doc_return 200 text/html "
[ad_scope_header "Edit the entry for $download_name"]
[ad_scope_page_title "Edit the entry for $download_name"]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	"Edit"]

<hr>

<form method=POST action=download-edit-2>

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
