# /www/admin/display/edit-complete-css.tcl

ad_page_contract {
    setting up cascaded style sheet properties
    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    related variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)

    @author ahmeds@arsdigita.com
    @creation-date 12/27/1999

    @cvs-id edit-complete-css.tcl,v 3.2.2.7 2000/09/22 01:34:41 kevin Exp
} {
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}


ad_scope_error_check

set page_title "Edit Display Settings "

set page_content "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  $page_title]
<hr>
"

set css_string [css_generate_complete_css]

if { ![empty_string_p $css_string] } {
    # there are css information in the database

    append html "
    <form method=post action=\"edit-complete-css-2\">
    [export_form_scope_vars return_url]"

    set query_sql "select selector, property, value from css_complete where [ad_scope_sql]"
    
    set counter 0
    set last_selector ""
    db_foreach display_select_query $query_sql {
	
	if { [string compare $selector $last_selector]!=0 } {
	   
	    if { $counter == 0 } {
		append css "
		$selector 
		<ul>
		<table>"
	    } else {
		append css "
		<tr>
		<td><a href=\"add-complete-css-property?selector=$last_selector\">add new property</a>
		</tr>
		</table>
		</ul>
		$selector
		<ul>
		<table>"
	    }
	}

	append css "
	<tr>
	<td>$property 
	<td>:
	<td><input type=text name=css\_$selector\_$property size=20 value=\"[philg_quote_double_quotes $value]\">
	<td>[ad_space 10]<a href=\"delete-complete-css?[export_url_scope_vars selector property]\">remove</a>
	</tr>
	"
	incr counter
	set last_selector $selector
    } if_no_rows {
	# no css values supplied
	set css ""
    }
    
    if { $counter > 0 } {
	append css " 
	<tr>
	<td><a href=\"add-complete-css-property?[export_url_scope_vars selector]\">add new property</a>
	</tr>
	</table>
	</ul>"
    }
    append html "$css"

} else {
    # no css information in the database
    append html "No CSS currently defined. <br>"
}

db_release_unused_handles

append html "
<p>
<center>
<input type=submit value=\"Submit\">
</center>
</form>
<a href=\"add-complete-css\"><p>add new style selector</a>
"

append page_content "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content
