# /www/admin/content-sections/update/link.tcl

ad_page_contract {
    Content Section link main page 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @creation-date 29/12/99
    @author ahmeds@mit.edu

    @cvs-id link.tcl,v 3.2.2.7 2000/09/22 01:34:34 kevin Exp
} { }

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set page_title "Section Navigation"

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
 
[ad_scope_admin_context_bar [list "index" "Content Sections"] $page_title ]

<hr>
[help_upper_right_menu]
<br>
"

# show all the links in the tree structure
# notice the use of outer join to show content
# sections for which no from_to links were defined

set ad_scope_sql_bv [ad_scope_sql cs]
set sql_query "
select cs.section_id as from_section_id, cs.group_id,
 csl.to_section_id as to_section_id, 
 content_section_id_to_key (cs.section_id) as from_section_key, 
 content_section_id_to_key (to_section_id) as to_section_key 
 from content_sections cs, content_section_links csl 
 where [ad_scope_sql cs]
 and cs.group_id=:group_id
 and cs.section_id = csl.from_section_id (+) 
 and cs.enabled_p = 't' 
 and (((csl.from_section_id is null) and (csl.to_section_id is null)) or 
 ((enabled_section_p (csl.from_section_id) = 't') and enabled_section_p (csl.to_section_id) = 't')) 
 and (not ((cs.section_type = 'admin') or (cs.section_type = 'static'))) 
 order by from_section_key, to_section_key 
"

set link_counter 0
set last_from_section_id 0

db_foreach content_sections_get_all_links $sql_query  {

    if { $from_section_id!=$last_from_section_id } {

	if { $link_counter > 0 } {
	    append links "
	    </table>
	    <a href=\"add-link?from_section_id=$last_from_section_id\">
	    \[add link\]</a>
	    <br><br><br><br>
	    </ul>
	    "
	}

	append links "
	$from_section_key
	<ul>
	<table>
	"

    }

    if { ![empty_string_p $to_section_key] } {
	append links "
	<tr>
	<td>
	$to_section_key
	<td><a href=\"delete-link?[export_url_vars from_section_id to_section_id]\">
            delete</a>
	</tr>
	"
    }

    incr link_counter
    set last_from_section_id $from_section_id
}

if { $link_counter > 0 } {
    append links "
    </table>
    <a href=\"add-link?from_section_id=$last_from_section_id\">
    \[add link\]</a>
    <br>
    </ul>
    "

    append html "
    <ul>
    $links
    </ul>
    "
} else {
    append html "
    No content sections defined in the database.
    "
}

db_release_unused_handles

append page_body "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html "$page_body"


