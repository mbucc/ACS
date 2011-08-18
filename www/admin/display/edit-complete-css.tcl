# $Id: edit-complete-css.tcl,v 3.0 2000/02/06 03:16:27 ron Exp $
# File:     /admin/css/edit-complete-css.tcl
# Date:     12/27/99
# Author:   ahmeds@arsdigita.com
# Purpose:  setting up cascaded style sheet properties
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

set page_title "Edit Display Settings "

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  $page_title]
<hr>
"

set css_string [css_generate_complete_css $db]

if { ![empty_string_p $css_string] } {
    # there are css information in the database

    append html "
    <form method=post action=\"edit-complete-css-2.tcl\">
    [export_form_scope_vars return_url]
    "

    set selection [ns_db select $db "
    select selector, property, value
    from css_complete
    where [ad_scope_sql]"]

    set_variables_after_query
    
    set counter 0
    set last_selector ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	
	if { [string compare $selector $last_selector]!=0 } {
	   
	    if { $counter == 0 } {
		append css "
		$selector 
		<ul>
		<table>
		"
	    } else {
		append css "
		<tr>
		<td><a href=\"add-complete-css-property.tcl?selector=$last_selector\">add new property</a>
		</tr>
		</table>
		</ul>
		$selector
		<ul>
		<table>
		"
	    }
	}

	append css "
	<tr>
	<td>$property 
	<td>:
	<td><input type=text name=css\_$selector\_$property size=20 value=\"[philg_quote_double_quotes $value]\">
	<td>[ad_space 10]<a href=\"delete-complete-css.tcl?[export_url_scope_vars selector property]\">remove</a>
	</tr>
	"
	incr counter
	set last_selector $selector
    }
    
    if { $counter > 0 } {
	append css " 
	<tr>
	<td><a href=\"add-complete-css-property.tcl?[export_url_scope_vars selector]\">add new property</a>
	</tr>
	</table>
	</ul>"
    } else {
	# no css values supplied
	set css ""
    }
    append html "
    $css
    "
} else {
    # no css information in the database
    append html "No CSS currently defined. <br>"
}

ns_db releasehandle $db

append html "
<p>
<center>
<input type=submit value=\"Submit\">
</center>
</form>
<a href=\"add-complete-css.tcl\"><p>add new style selector</a>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"


