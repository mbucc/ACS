# /www/manuals/admin/section-move-2.tcl
ad_page_contract {
    Page to execute the requested move

    @param manual_id the manual being modified
    @param section_id the ID of the section being moved
    @param parent_id the new parent_id, if appropriate
    @param move the direction of the move, if appropriate

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Nov 1999
    @cvs-id section-move-2.tcl,v 1.3.2.3 2000/07/21 04:02:55 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
    {parent_id:integer ""}
    {move ""}
}

# ---------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

page_validation {
    if {![empty_string_p $move] && $move != "up" && $move != "down"} {
	error "This page was not called with the right form variables"
    }
}

# There are two things we could be doing on this page.  We might be moving
# a section to a new parent or we might be moving it up or down.

if [empty_string_p $move] {

    if [empty_string_p $parent_id] {
	set parent_key ""
    } else {
	set parent_key [db_string  parent_key "
	select sort_key from manual_sections where section_id = :parent_id"]
    }

    set parent_key_base "${parent_key}__"
    set root [db_string max_sort_key "
    select max(sort_key) from manual_sections 
    where  manual_id = :manual_id
    and    sort_key like :parent_key_base" -default ""]

    # find the proper sort_key for the next subsection to this parent

    set depth [string length $root]

    # avoid TCL's octal predilections
    set temp [string trimleft $root 0]
    if {[empty_string_p $temp]} {
	set temp 0
    }

    if { [empty_string_p $root] } {
	# first subsection
	set root "${parent_key}00"
    } elseif { [expr ${temp}%100] == 99 } {
	ad_return_complaint 1 "<li>You cannot have more than 100 subsections in any section.\n"
	return
    } else {
	incr temp
	# don't forget to pad with any zeros we chopped off
	set root [format "%0${depth}d" $temp]
    }

    # now move the section and all its children

    db_1row sort_key "
    select sort_key from manual_sections
    where  section_id = :section_id"
    set depth [string length $sort_key]
    set sort_key_base "$sort_key%"
    if { [catch { 
	db_dml section_update "
	update manual_sections
	set   sort_key  = :root || substr(sort_key, :depth + 1)
	where manual_id = :manual_id
	and   sort_key like :sort_key_base"
    } error_msg] } {
	
	ad_return_complaint 1 "<li>A database error occurred.  Make sure you
	start from the main administation page.\n$error_msg\n"
	return

    } else {

	# if we are restoring a section, we need to set active_p to t
	db_dml section_make_active "
	update manual_sections 
	set    active_p = 't' 
	where  section_id = :section_id"

	db_release_unused_handles
	ad_returnredirect "manual-view.tcl?manual_id=$manual_id"
	return
    }   

} else {
    db_transaction {

	db_1row sort_key "
	select sort_key from manual_sections where section_id = :section_id"

	regexp {(.*)[0-9][0-9]} $sort_key match prefix

	# find the right section to swap with

	set prefix_base "${prefix}__"
	switch $move {
	    "up" {
		set other_sort_key [db_string max_sort_key "
		select max(sort_key)
		from   manual_sections
		where  manual_id = :manual_id
		and    active_p  = 't' 
		and    sort_key like :prefix_base
		and    sort_key < :sort_key" -default ""]
	    }

	    "down" {
		set other_sort_key [db_string min_sort_key "
		select min(sort_key)
		from   manual_sections
		where  manual_id = :manual_id
		and    active_p  = 't' 
		and    sort_key like :prefix_base
		and    sort_key > :sort_key" -default ""]
	    }

	}

	# juggle the sort_keys to achieve the swap

	if { ![empty_string_p $other_sort_key] } {
	    set depth [string length $sort_key]
	    set sort_key_base "$sort_key%"
	    set other_sort_key_base "$other_sort_key%"
	    # length(sort_key) = length(other_sort_key)
	    db_dml juggle_1 "
	    update manual_sections
	    set    sort_key = '-1' || substr(sort_key, :depth + 1)
	    where  manual_id = :manual_id 
	    and    sort_key like :sort_key_base"

	    db_dml juggle_2 "
	    update manual_sections
	    set    sort_key = :sort_key || substr(sort_key, :depth + 1)
	    where  manual_id = :manual_id 
	    and    sort_key like :other_sort_key_base"

	    db_dml juggle_3 "
	    update manual_sections 
	    set    sort_key = :other_sort_key || substr(sort_key, 3)
	    where  manual_id = :manual_id 
	    and    sort_key like '-1%'"
	}

    }

    db_release_unused_handles
    ad_returnredirect manual-view.tcl?manual_id=$manual_id
    return
}


