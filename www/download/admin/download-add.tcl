# /www/download/admindownload-add.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  adds new downloadable file
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: download-add.tcl,v 3.1.4.2 2000/05/18 00:05:15 ron Exp $
# -----------------------------------------------------------------------------

set_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set html "
<form  method=post action=download-add-2.tcl>

[export_form_scope_vars]

<input type=hidden name=download_id
       value=[database_to_tcl_string $db "select download_id_sequence.nextval from dual"]>

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

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/index.tcl?[export_url_scope_vars]" "Admin"] \
	$page_title]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"
