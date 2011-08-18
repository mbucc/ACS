# $Id: ad-categories.tcl,v 3.0 2000/02/06 03:12:13 ron Exp $
#
# ad-categories.tcl
#
# created by teadams@mit.edu on 1999/10/06 
# extensively modified by michael@arsdigita.com on November 7, 1999
#
#
# for category management
#

util_report_library_entry

proc_doc ad_category_parentage_list {db category_id} {Returns a list of lists, where each sublist is one line of parentage up from the specified category to the hierarchy root. In turn, each parentage line list consists of two-item lists: category_id and category. A list of lists is needed since a category can have multiple parents. If this category has no parents, then return the empty list.} {

    set n_parents [database_to_tcl_string $db "select count(*) from category_hierarchy where child_category_id = $category_id"]

    if { $n_parents == 0 } {
	return [list]
    }

    set selection [ns_db select $db "SELECT c.category_id AS parent_id, c.category AS parent_category, hc.level_col
FROM categories c,
(SELECT h.child_category_id, LEVEL AS level_col, ROWNUM AS row_col
 FROM category_hierarchy h
 START WITH h.child_category_id = $category_id
 CONNECT BY h.child_category_id = PRIOR h.parent_category_id) hc
WHERE c.category_id = hc.child_category_id
ORDER BY hc.row_col"]

    set parentage_list [list]
    set parentage_line [list]
    set prior_level 0
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$level_col < $prior_level} {
	    # Parent line is now completed, flush it
	    lappend parentage_list $parentage_line
	    set parentage_line [list]
	}

	set prior_level $level_col

	# We're moving up the hierarchy so put this category at
	# the beginning of the parentage line.
	#
	set parentage_line [concat [list [list $parent_id $parent_category]] $parentage_line]
    }

    # Don't forget the last parentage line
    lappend parentage_list $parentage_line
}

ad_proc ad_categorization_widget {{-db 0 -which_table "" -what_id 0 -name "category_id_list" -multiple_p 1 -size 0}} {Given a specific row in the database, return a select widget that contains the entire category hierarchy. Categories already mapped to the database row will be pre-selected.} {

    # Validate that all mandatory arguments have been supplied.
    #
    set missing_args [list]

    if { $db == 0 } {
	lappend missing_args "db"
    }

    if { [empty_string_p $which_table] } {
	lappend missing_args "which_table"
    }

    if { $what_id == 0 } {
	lappend missing_args "what_id"
    }

    set n_missing_args [llength $missing_args]

    if { $n_missing_args > 0 } {
	error "missing $n_missing_args arg(s): [join $missing_args ", "]"
    }

    # Format the <select> tag.
    #
    set widget "<select name=\"$name\""

    if { $multiple_p } {
	append widget " multiple"
    }

    if { $size > 0 } {
	append widget " size=$size"
    }

    append widget ">\n"

    # Fetch the list of categories to which this table row is already mapped.
    #
    set mapped_categories [database_to_tcl_list $db "select category_id
    from site_wide_category_map
    where on_which_table = '$which_table'
    and on_what_id = '$what_id'"]

    # Fetch the entire category hierarchy.
    #
    set selection [ns_db select $db "select c.category_id, lpad(' ', 12*(ch.tree_level - 1),'&nbsp;') as indent, c.category, c.category_type
from categories c,
(select child_category_id, rownum as tree_rownum, level as tree_level
 from category_hierarchy
 start with parent_category_id is null
 connect by prior child_category_id = parent_category_id) ch
 where c.category_id = ch.child_category_id
 order by ch.tree_rownum"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	append widget "<option value=$category_id"

	# If the category is already mapped to this database row, then
	# pre-select it.
	#
	# lsearch is slow for long lists so we may want to store
	# mapped categories as array keys.
	#
	if { [lsearch $mapped_categories $category_id] != -1 } {
	    append widget " selected"
	}

	append widget ">${indent}${category}"

	if { ![empty_string_p $category_type] } {
	    append widget " ($category_type)"
	}

	append widget "\n"
    }

    append widget "</select>"

    return $widget
}

ad_proc ad_categorize_row {{-db 0 -which_table "" -what_id 0 -category_id_list "" -mapping_weight "null" -one_line_item_desc "" -mapping_comment ""}} {Maps a specific row in the database to the specified categories.} {

    # Validate that all mandatory arguments have been supplied.
    #
    set missing_args [list]

    if { $db == 0 } {
	lappend missing_args "db"
    }

    if { [empty_string_p $which_table] } {
	lappend missing_args "which_table"
    }

    if { $what_id == 0 } {
	lappend missing_args "what_id"
    }

    if { [empty_string_p $one_line_item_desc] } {
	lappend missing_args "one_line_item_desc"
    }

    set n_missing_args [llength $missing_args]

    if { $n_missing_args > 0 } {
	error "missing $n_missing_args arg(s): [join $missing_args ", "]"
    }

    with_transaction $db {

	if { [llength $category_id_list] == 0 } {
	    ns_db dml $db "delete from site_wide_category_map
where on_which_table = '$which_table'
and on_what_id = '$what_id'"

	} else {
	    # Purge any existing mappings that have been removed.
	    #
	    ns_db dml $db "delete from site_wide_category_map
where on_which_table = '$which_table'
and on_what_id = '$what_id'
and category_id not in ([join $category_id_list ", "])"

	    # Update mapping_weight, one_line_item_desc, and mapping_comment
	    # for any remaining mappings.
	    #
	    ns_db dml $db "update site_wide_category_map
set one_line_item_desc = '$one_line_item_desc',
mapping_weight = $mapping_weight,
mapping_comment = '$mapping_comment'
where on_which_table = '$which_table'
and on_what_id = '$what_id'"

	    # Insert all mappings that do not already exist.
	    #
	    ns_db dml $db "insert into site_wide_category_map
(map_id, category_id, on_which_table, on_what_id, mapping_date, mapping_weight, one_line_item_desc, mapping_comment)
select site_wide_cat_map_id_seq.nextval, category_id, '$which_table', '$what_id', sysdate, $mapping_weight, '$one_line_item_desc', '$mapping_comment'
from categories
where category_id in ('[join $category_id_list "', '"]')
and not exists (
 select category_id
 from site_wide_category_map
 where on_which_table = '$which_table'
 and on_what_id = '$what_id'
 and categories.category_id = site_wide_category_map.category_id)"
	}
    } {
	error $errmsg
    }
}

util_report_successful_library_load
