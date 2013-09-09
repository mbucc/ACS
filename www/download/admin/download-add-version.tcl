# /www/download/admin/download-add-version.tcl
ad_page_contract {
    adds a new downloadable file version

    @param download_id the file we are adding a version to
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add-version.tcl,v 3.9.2.6 2000/09/24 22:37:14 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

db_1row download_name "
select download_name from downloads 
where download_id = :download_id"

set html "
<form enctype=multipart/form-data method=post action=download-add-version-2>

[export_form_scope_vars download_id]

<input type=hidden 
       name=version_id 
       value=\"[db_string next_version_id "select download_version_id_sequence.nextval from dual"]\">

<p>

<table cellpadding=3>

<tr>
<th align=right>Upload File:</th>
<td>
<input type=file name=upload_file size=20>
</td>
</tr>

<tr>
<th align=right>Pseudo File Name:</th>
<td>
<input type=text size=20 name=pseudo_filename MAXLENGTH=100>[ad_space 3]e.g. bw2000-2.3.tar.gz
</td>
</tr>

<tr>
<th align=right>Version:</th>
<td>
<input type=text size=5 name=version MAXLENGTH=10>[ad_space 3]e.g. 2.3

</td>
</tr>

<tr>
<th align=right>Status:</th>
<td>
<select name=status>
<option value=promote>Promote
<option value=offer_if_asked>Offer If Asked
<option value=removed>Removed
</select>
</td>
</tr>

<tr>
<th align=right>Release Date:</th>
<td>[ad_dateentrywidget release_date]
</td>
</tr>

<tr>
<th align=right valign=top>&nbsp;<br>Version Description:</th>
<td><textarea name=version_description cols=40 rows=5 wrap=soft></textarea>
</td>
</tr>

<tr>
<th align=right>Text above is:</th>
<td>
<select name=version_html_p>
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
<p>
"

# -----------------------------------------------------------------------------

set page_title "Upload"

doc_return 200 text/html "
[ad_scope_header $page_title]

<h2>$page_title</h2>

[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	$page_title]

<hr>
[help_upper_right_menu]

<blockquote>
$html

<p>Note: <i>pseudo file name</i> is the name that users will see
when they try to download this item; <i>version</i> is used to
sort the versions of $download_name available to users.   They are
generally related, but the details depend on the scheme you've
chosen for naming your downloadable files.

</blockquote>

[ad_scope_footer]
"

