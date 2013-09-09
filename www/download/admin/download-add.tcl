# /www/download/admin/download-add.tcl
ad_page_contract {
    adds new downloadable file

    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add.tcl,v 3.8.2.6 2000/09/24 22:37:14 kevin Exp
} {
    scope:optional
    group_id:integer,optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

set page_content "
<form  method=post action=download-add-2>

[export_form_scope_vars]

<input type=hidden name=download_id
       value=[db_string next_download_id "select download_id_sequence.nextval from dual"]>

<table>

<tr>
<th align=right>Download Name:</th>
<td><input type=text size=20 name=download_name MAXLENGTH=100>[ad_space 3] e.g. Bloatware 2000
</td>
</tr>

<tr>
<th align=right>Directory Name:</th>
<td><input type=text size=20 name=directory_name MAXLENGTH=100>[ad_space 3] e.g. bw2000
</td>
</tr>

<tr>
<th align=right valign=top>&nbsp;<br>Description:</th>
<td><textarea name=description cols=60 rows=6 wrap=soft></textarea>
</td>
</tr>

<tr>
<th align=right>Text above is:
<td>
<select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} "f"]
</select>
</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>

</table>
</form>
"

# -----------------------------------------------------------------------------

set page_title "Add New Download"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	$page_title]

<hr>
[help_upper_right_menu]

<blockquote>
$page_content
</blockquote>

[ad_scope_footer]
"
