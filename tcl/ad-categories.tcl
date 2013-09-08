# /tcl/ad-categories.tcl
ad_library {

  Provides utility procs for category management.

  @author teadams@mit.edu
  @author michael@arsdigita.com
  @cvs-id ad-categories.tcl,v 3.4.2.4 2000/07/16 22:29:10 ryanlee Exp

}

proc_doc ad_category_parentage_list {category_id} {

  Returns a list of lists, where each sublist is one line of parentage up
  from the specified category to the hierarchy root. In turn, each parentage
  line list consists of two-item lists: category_id and category. A list
  of lists is needed since a category can have multiple parents. If this
  category has no parents, then return the empty list.

} {

    set n_parents [db_string n_parents_for_category {
	select count(*) from category_hierarchy where child_category_id = :category_id and parent_category_id is not null
    }]

    if { $n_parents == 0 } {
	return [list]
    }

    # (2000-04-05 Seb) Note that we have one big problem:  suppose that
    # we have 1 parent for this category.  But its parent has 2 parents.
    # That leads us to question: how many parentage lines does this
    # category actually have?  My vote is 1.  But then the UI is
    # misleading, because we don't know which parentage line to
    # display ... but what if we replace all above ill-behaving parent
    # with ellipsis?

    #   OK, seems like a good idea.  So, we should build parentage tree
    # for category and follow the changes of LEVEL.  If equal to 1, we
    # have direct parent.  Check if the LEVEL is increasing until it
    # drops to 1 again.  If it was increasing all the time until next
    # level==1 is reached, we have 'direct' parentage line (no-problem).
    # Otherwise, print only the portion up to the line with the highest
    # non-repeating value of LEVEL.

    set category_name [db_string get_category_name "select c.category from categories c where c.category_id=:category_id" ]

    set parentage_list [list]
    set parentage_line [list [list $category_id $category_name]]
    set prior_level 0
    set forking_level 9999

    db_foreach category_parentage_tree "
SELECT c.category_id AS parent_id, c.category AS parent_category, hc.level_col
FROM categories c,
(SELECT h.parent_category_id, LEVEL AS level_col, ROWNUM AS row_col
 FROM category_hierarchy h
 START WITH h.child_category_id = :category_id
 CONNECT BY h.child_category_id = PRIOR h.parent_category_id) hc
WHERE c.category_id = hc.parent_category_id
ORDER BY hc.row_col" {

	if {$level_col <= $prior_level} {
	    if {$level_col == 1} {
		# Parent line is now completed, flush it:
		# Take only up to the last non-forking parent
		#   (level increases from right to left)
		lappend parentage_list [lrange $parentage_line [expr \
		    [llength $parentage_line] - $forking_level] end]
		set parentage_line [list [list $category_id $category_name]]
		set forking_level 9999
	    } else {
		# We have problematic parent (i.e. that is itself
		# multi-parented)
		if {$level_col < $forking_level} {
		    set forking_level $level_col
		    #  Add (...) in front of category name at $level_col - 1
		    set last_nonforking_level [expr \
			    [llength $parentage_line] - $forking_level]
		    set problematic_category [lindex $parentage_line \
			    $last_nonforking_level]
		    set probl_cat_id [lindex $problematic_category 0]
		    set probl_cat_name "(...) [lindex $problematic_category 1]"
		    #  Put it back
		    set parentage_line [lreplace $parentage_line \
			$last_nonforking_level $last_nonforking_level \
			[list $probl_cat_id $probl_cat_name]]
		}
	    }
	}

	set prior_level $level_col

	# We're moving up the hierarchy so put this category at
	# the beginning of the parentage line.
	#
	set parentage_line [concat [list [list $parent_id $parent_category]] $parentage_line]
    }

    # Don't forget the last parentage line
    lappend parentage_list [lrange $parentage_line [expr \
	[llength $parentage_line] - $forking_level] end]
}



ad_proc ad_categorization_widget {
  {
      -which_table ""
      -what_id 0
      -name "category_id_list"
      -multiple_p 1
      -size 0
      -category_id ""
      -type ""
  }
} {
  
  Given a specific row in the database, return a select widget that
  contains the entire category hierarchy. Categories already mapped to
  the database row will be pre-selected.
  
} {

    # Validate that all mandatory arguments have been supplied.
    #
    set missing_args [list]

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
    set mapped_categories [db_list mapped_categories "select category_id
    from site_wide_category_map
    where on_which_table = :which_table
    and on_what_id = :what_id" ]

    # If its not mapped to anything, but a new category id is specified,
    # pre-select that

    if { [empty_string_p $mapped_categories] && ![empty_string_p $category_id] } {
	set mapped_categories [list $category_id]
    }
    set type_clause ""
    if { ![empty_string_p $type] } {
	set type_clause "AND category_type = :type"
    }

    # Fetch the entire category hierarchy.
    #
    db_foreach categorization_widget "
select c.category_id, lpad(' ', 12*(ch.tree_level - 1),'&nbsp;') as indent, c.category, c.category_type
from categories c,
(select child_category_id, rownum as tree_rownum, level as tree_level
 from category_hierarchy
 start with parent_category_id is null
 connect by prior child_category_id = parent_category_id) ch
 where c.category_id = ch.child_category_id
 $type_clause
 order by ch.tree_rownum" {

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



ad_proc ad_categorize_row {
  {
    -which_table ""
    -what_id 0
    -category_id_list ""
    -mapping_weight ""
    -one_line_item_desc ""
    -mapping_comment ""
  }
} {

  Maps a specific row in the database to the specified categories.
  
} {

    # Validate that all mandatory arguments have been supplied.
    #
    set missing_args [list]

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

    set bind_var_list [list]
    for {set i 0} {$i < [llength $category_id_list]} {incr i} {
	set category_id_$i [lindex $category_id_list $i]
	lappend bind_var_list ":category_id_$i"
    }

    db_transaction {

	if { [llength $category_id_list] == 0 } {
	    db_dml delete_all_mappings "delete from site_wide_category_map
where on_which_table = :which_table
and on_what_id = :what_id" 

	} else {

	    # Purge any existing mappings that have been removed.
	    #
	    db_dml delete_removed_mappings "delete from site_wide_category_map
where on_which_table = :which_table
and on_what_id = :what_id
and category_id not in ([join $bind_var_list ", "])" 

	    # Update mapping_weight, one_line_item_desc, and mapping_comment
	    # for any remaining mappings.
	    #
	    db_dml update_remaining_mappings {
update site_wide_category_map
set one_line_item_desc = :one_line_item_desc,
mapping_weight = :mapping_weight,
mapping_comment = :mapping_comment
where on_which_table = :which_table
and on_what_id = :what_id
}

	    # Insert all mappings that do not already exist.
	    #

	    db_dml insert_new_mappings "insert into site_wide_category_map
(map_id, category_id, on_which_table, on_what_id, mapping_date, mapping_weight, one_line_item_desc, mapping_comment)
select site_wide_cat_map_id_seq.nextval, category_id, :which_table, :what_id, sysdate, :mapping_weight, :one_line_item_desc, :mapping_comment
from categories
where category_id in ([join $bind_var_list ", "])
and not exists (
 select category_id
 from site_wide_category_map
 where on_which_table = :which_table
 and on_what_id = :what_id
 and categories.category_id = site_wide_category_map.category_id)
"
	}
    } on_error {
	error $errmsg
    }
}
