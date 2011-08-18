# File: /general-links/index.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Displays a hierarchy of the links
#  the variable  "category_select" determines if all the
#  the links are displayed or just a subset
#
# $Id: index.tcl,v 3.2 2000/03/09 00:23:08 tzumainn Exp $
#--------------------------------------------------------

ad_page_variables {{category_select "all"} {search_query ""}}

set db [ns_db gethandle]

if { $category_select == "all" } {

    set start_with_clause "start with parent_category_id is null"

    ad_return_top_of_page "
    [ad_header "General Links"]
    
    <h2>General Links</h2>
    
    [ad_context_bar_ws "General Links"]
    
    <hr>
    "
} else {
    set category_select_name [database_to_tcl_string_or_null $db "select 
    category as category_select_name 
    from  categories c 
    where c.category_id = '$category_select'"]
    set start_with_clause "start with child_category_id = $category_select"

    ad_return_top_of_page "
    [ad_header "$category_select_name"]
    
    <h2>$category_select_name</h2>
    
    [ad_context_bar_ws [list "" "General Links"] $category_select_name]
    
    <hr>
    "

}

if { $category_select == "all" } {
    set where_clause_for_section ""
} else {
    set category_select_name [database_to_tcl_string_or_null $db "
    select category 
    from categories 
    where category_id = '$category_select'"]
   
    set where_clause_for_section "and c.category_id = $category_select"
}

if { [empty_string_p $search_query] } {
    set where_clause_for_search_query ""
} else {
    set QQsearch_query [DoubleApos $search_query]
    set where_clause_for_search_query " 
    and (
           upper(meta_keywords) like '%[string toupper $QQsearch_query]%' 
         or upper(meta_description) like '%[string toupper $QQsearch_query]%' 
         or upper(link_description) like '%[string toupper $QQsearch_query]%' 
         or upper(link_title) like '%[string toupper $QQsearch_query]%'
        )"
}

set individual_section_options [ad_db_optionlist $db "
select category, category_id 
from categories
order by upper(category)" $category_select]

if { $category_select == "all" } {
    set all_sections_option "<option value=\"all\" SELECTED>All Categories</option>\n"
} else {
    set all_sections_option "<option value=\"all\">All Categories</option>\n"
}

set n_links 0
set link_list "<ul>"

### category hierarchy

set selection [ns_db select $db "select c.category_id, ch.tree_level - 1 as indent, 
c.category, c.category_type, link_id, url, link_title, n_ratings, avg_rating
from categories c, general_links gl,
(select child_category_id, rownum as tree_rownum, level as tree_level
   from category_hierarchy
   $start_with_clause
   connect by prior child_category_id = parent_category_id) ch
where c.category_id = ch.child_category_id
and gl.approved_p = 't'
and exists (select 1 from site_wide_category_map swm
            where gl.link_id = swm.on_what_id
            and swm.on_which_table = 'general_links'
            and swm.category_id = c.category_id)
$where_clause_for_search_query
order by ch.tree_rownum, link_title"]

set current_category_name ""
set current_indent 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr n_links
    set category_name $category
    if {![empty_string_p $category_type]} {
	append category_name " ($category_type)"
    }

    if { $current_category_name != $category_name } {
	# new category
	
	if {![empty_string_p $current_category_name]} {
	    # close the ul for the old category
	    append link_list "</ul>"

	    for {set i 1} {$i <= $current_indent} {incr i} {
		append link_list "\n</ul>"
	    }
	}

	set current_category_name $category_name
	set current_indent $indent

	for {set i 1} {$i <= $current_indent} {incr i} {
	    append link_list "\n<ul>"
	}

	append link_list "<li><a href=\"index.tcl?category_select=$category_id&search_query=[ns_urlencode $search_query]\"><b>$current_category_name</b></a>\n<ul>"
    }

    if {[ad_parameter ClickthroughP general-links] == 1} {
	# use the clickthroughs
	set exact_link "/ct/ad_link_${link_id}?send_to=$url"
    } else {
	# don't use clickthoughs
	set exact_link "$url"
    }

    append link_list "\n<li><a href=\"$exact_link\">$link_title</a> - Average Rating: $avg_rating; Number of Ratings: $n_ratings - <a href=\"one-link.tcl?[export_url_vars link_id]\">more</a>"
}

### wrap up last ul/blockquote
if { $n_links > 0 } {
    append link_list "</ul>"
}

for {set i 1} {$i <= $current_indent} {incr i} {
    append link_list "\n</ul>"
}

### deal with uncategorized links - maybe
set uncategorized_link_list ""
if { $category_select == "all" } {
    
    set n_uncategorized 0
    set selection [ns_db select $db "select link_id, url, link_title, n_ratings, avg_rating from general_links gl
    where not exists (select 1 from site_wide_category_map swm
                     where gl.link_id = swm.on_what_id
                     and swm.on_which_table = 'general_links')
          and gl.approved_p = 't'
    "]
    
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	incr n_links
	incr n_uncategorized

	if {[ad_parameter ClickthroughP general-links] == 1} {
	    # use clickthroughs
	    set exact_link "/ct/ad_link_${link_id}?send_to=$url"
	} else {
	    # don't use clickthroughs
	    set exact_link "$url"
	}

	append uncategorized_link_list "<li> <a href=\"$exact_link\">$link_title</a> - Average Rating: $avg_rating; Number of Ratings: $n_ratings - <a href=\"one-link.tcl?[export_url_vars link_id]\">more</a>"
    }
    
    if { $n_uncategorized != 0 } {
	set uncategorized_link_list "<li><b>Uncategorized Links</b><ul>$uncategorized_link_list</ul>"
    }
}

if { $n_links == 0 } {
    # no links
    append link_list "<li>No links available."
}

ns_db releasehandle $db

append link_list $uncategorized_link_list

append link_list "</ul>"

set suggest_link ""

if {[ad_parameter AllowSuggestionsP general-links] == 1} {
    # users can suggest links to the hotlist
    set suggest_link "<ul><li><p><a href=\"link-add-without-assoc.tcl\">suggest a link</a></ul>"
}

ns_write "
<form method=post action=\"index.tcl\">
<input type=text size=40 name=search_query value=\"$search_query\">
<input type=submit value=\"Search\">
</form>
$link_list
$suggest_link

[ad_footer]
"

