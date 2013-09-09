# /www/admin/content-sections/update/add-link.tcl
ad_page_contract {
    Content Section add link page 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  tarik@arsdigita.com
    @creation-date 22/12/99
    @cvs-id add-link.tcl,v 3.3.2.7 2000/09/22 01:34:32 kevin Exp

    @param from_section_id
} {
    from_section_id:notnull
}
 
ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set from_section_key [db_string content_select_section_key "
    select section_key from content_sections 
 where section_id = :from_section_id"]

set page_title "Add link from $from_section_key"

set html "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
 
[ad_scope_admin_context_bar [list "index" "Content Sections"] [list "link" "Link Sections"] $page_title]

<hr>

[help_upper_right_menu]

<br>
"

# show existing links 
set query_sql "
select to_section_id, 
 content_section_id_to_key (to_section_id) as to_section_key 
 from content_section_links 
 where from_section_id = :from_section_id 
 and enabled_section_p(from_section_id) = 't' 
 and enabled_section_p(to_section_id) = 't' 
 order by to_section_key 
"

set link_counter 0
db_foreach content_sections_show_existing_links $query_sql  {
    append old_links "
    <tr>
    <td>$to_section_key
    </tr>
    "

    incr link_counter
}

if { $link_counter > 0 } {
    append html "
    <h3>$from_section_key</h3>
    <h4>Current Links</h4>
    <ul>
    <table>
    $old_links
    </table>
    </ul>
    <br>
    "
} else {
    append html "
    <h3>$from_section_key</h3>
    "
}

set section_link_id [db_string content_sections_get_next_section_link_id "select section_link_id_sequence.nextval from dual"]

# show all linking possibilities (all content sections for
# which links from from_section_key don't already exist)
set query_sql "
select section_id, section_id as to_section_id, section_key as link_section_key 
 from content_sections 
 where section_id not in (select to_section_id 
 from content_section_links 
 where from_section_id = :from_section_id 
 and enabled_section_p (from_section_id) = 't' 
 and enabled_section_p (to_section_id) = 't') 
 and enabled_p = 't' 
 and (not (section_type = 'admin')) 
 and not (section_id = :from_section_id) 
 order by section_key 
"

set add_link_counter 0

db_foreach content_sections_show_possible_links $query_sql  {

    set to_section_key $link_section_key
    append add_links "
    <a href=\"add-link-2?[export_url_vars from_section_id to_section_id section_link_id]\">
    $link_section_key</a>
    <br>
    "
    incr add_link_counter
}

if { $add_link_counter > 0 } {
    append html "
    <h4>Add Link to</h4>
    <ul>
    $add_links
    </ul>
    "
} else {
    append html "
    <ul>
    No link additions possible
    </ul>
    "
}



doc_return  200 text/html "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

