ad_library {
    Procedures to support static page comments.

    @author Jin Choi [jsc@arsdigita.com]
    @author Philip Greenspun [philg@mit.edu]
    @author Bryan Quinn [bquinn@arsdigita.com]
    @creation-date July 16, 2000
    @cvs-id static-procs.tcl,v 1.1.2.5 2000/09/19 03:34:52 lars Exp
}

ad_proc ad_running_on_wimpy_machine_p {} {} {
    return 0
}

ad_proc ad_debug_static_page_syncer_p {} {} {
    return 0
}

ad_proc ad_check_file_for_sync {f} {} {
    set page_content ""
    set url_stub [string range $f [string length [ns_info pageroot]] [expr [string length $f] -1]]
    append page_content "<li>$url_stub \n"
    set stream [open $f]
    set content [read $stream]
    close $stream
    # we don't want to mess with zero length files, esp. since they 
    # cause the Oracle driver to cough up an error
    if { [string length $content] == 0 } {
	append page_content " ... is zero length; not touching database."
	return $page_content
    }
    set page_title [grep_for_title $content $url_stub]
    append page_content "([ns_quotehtml $page_title])\n"
    set n_rows_already [db_string static_syncer_get_count {
	select count(*) as n_rows_already 
	from static_pages 
	where url_stub = :url_stub
    }]
    if { $n_rows_already == 0 } {
	append page_content "... not in database.  Preparing to stuff..."
	db_dml static_syncer_insert_page {
	    insert into static_pages 
	    (page_id, url_stub, page_title, page_body)
	    values
	    (page_id_sequence.nextval, :url_stub, :page_title, empty_clob())
	    returning page_body into :1
	} -clobs [list $content]
        append page_content "done!"
    } else {
	append page_content "... already in database."

	# remove this later: need update to title?
	if {[regexp {.adp$} $url_stub match]} {
	    set existing_title [db_string static_syncer_select_page_info {
		select page_title 
		from static_pages 
		where url_stub = :url_stub
	    }]
	    if { [string compare $page_title $existing_title] != 0 } {
		db_dml static_syncer_update_static_pages {
		    update static_pages 
		    set page_title= :page_title 
		    where url_stub = :url_stub
		}
		append page_content " (updated page title)"
	    }
	}
    }
    db_release_unused_handles
    return $page_content
}

# we'll have an include pattern that is a REGEXP (single) 
# and an exclude_patterns which is a Tcl list of GLOB patterns

# the procedure must take two arguments, a filename and a database connection

# seen_already_cache is an ns_set

ad_proc walk_tree {dir procedure seen_already_cache {include_pattern {.*}} {exclude_patterns ""}} {} {
    set page_content ""
    # do this so that pwd works (so that we can avoid infinite loops)
    cd $dir

    set canonical_dirname [pwd]
    if { [ns_set find $seen_already_cache $canonical_dirname] != -1 } {
	# already exists
	if [ad_debug_static_page_syncer_p] {
	    append page_content "walk_tree: skipping directory $canonical_dirname (already seen)<br>"
	}
	return $page_content
    }

    # mark this directory as having been seen
    ns_set cput $seen_already_cache $canonical_dirname 1
    
    if [ad_debug_static_page_syncer_p] {
	append page_content "walk_tree: checking out directory $dir<br>\n"
    }
    foreach f [glob -nocomplain $dir/*] {
	if [file readable $f] {
	    if [file isdirectory $f] {
		if [ad_running_on_wimpy_machine_p] {
		    # we sleep for one second in order to not trash Web service
		    ns_sleep 1
		}
		append page_content [walk_tree $f $procedure $seen_already_cache $include_pattern $exclude_patterns]
	    } elseif [file isfile $f] {
		# the file is not a symlink
		set match [regexp $include_pattern $f]
		set excluded_p 0
		foreach pattern $exclude_patterns {
		    if { [string match $pattern $f] } {
			set excluded_p 1
			break
		    }
		}
		if { $match && !$excluded_p } {
		    append page_content [$procedure $f]
		}
	    }
	}
    }
    return $page_content
}

ad_proc grep_for_title { content url_stub } {
    set patterns [list \
	    {<title>(.+)</title>} \
	    {<asj_header[^>]*>([^<]+)</asj_header>} \
	    {set page_title \"([^"]+)\"}]

    foreach pattern $patterns {
	if [regexp -nocase $pattern $content match page_title] {
	    return $page_title
	}
    }
    
    return  "untitled document at $url_stub"
}




