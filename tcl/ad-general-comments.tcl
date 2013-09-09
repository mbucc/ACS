# ad-general-comments.tcl

ad_library {
    procs for general comment system
  
    @author teadams@arsdigita.com 
    @cvs-id ad-general-comments.tcl,v 3.9.2.8 2000/09/22 01:33:55 kevin Exp 
}

# (cleaned up and broken by philg@mit.edu on September 5, 1999)

# this is used by www/general-comments/comment-add-3.tcl
# and analogous pages within some modules


proc_doc ad_general_comment_add {comment_id on_which_table on_what_id one_line_item_desc content user_id ip_address approved_p {html_p "f"} {one_line ""} } "Inserts a comment into the general comment system" {

    ad_scope_error_check

    # let's limit this to 200 chars so we don't blow out our column
    set complete_description [string range $one_line_item_desc 0 199]
    set sql "
	insert into general_comments
	(comment_id, on_what_id, user_id, on_which_table, one_line_item_desc, content, ip_address, 
	comment_date, approved_p, html_p, one_line, [ad_scope_cols_sql])
	values
	(:comment_id, :on_what_id, :user_id, :on_which_table, :complete_description,
	empty_clob(), :ip_address, sysdate, :approved_p, :html_p, 
	:one_line, [ad_scope_vals_sql]) returning content into :1"

    if [ad_parameter LogCLOBdmlP acs 0] {
	ns_log Notice "About to use $sql\n -- to put --  \n$content\n\n -- into the database -- \n"
    }

    db_dml comment_add $sql -clobs [list $content]
}

# this is used by www/general-comments/comment-edit-3.tcl
# and ought to be used by analogous pages within 
# submodules 

proc_doc ad_general_comment_update {comment_id content ip_address {html_p "f"} {one_line ""}} "Updates a comment in the general comment system. Inserts a row into the audit table as well." { 

    db_transaction { 
	# insert into the audit table
	db_dml comment_insert "
	    insert into general_comments_audit
	    (comment_id, user_id, ip_address, audit_entry_time, modified_date, content, one_line)
	    select comment_id, user_id, ip_address, sysdate, modified_date, content, one_line 
	    from general_comments where comment_id = :comment_id" 
	
	set sql {
	    update general_comments
	    set content    = empty_clob(),  
	        one_line   = :one_line,
	        html_p     = :html_p,
	        ip_address = :ip_address
	    where comment_id = :comment_id 
	    returning content into :1
	}	    
	if [ad_parameter LogCLOBdmlP acs 0] {
	    ns_log Notice "About to use $sql\n -- to update --  \n$content\n\n -- in the database -- \n"
	}
	db_dml comment_update $sql -clobs [list $content]
    }
}

proc_doc ad_general_comments_list { on_what_id on_which_table item {module ""} {submodule ""} {return_url ""} {show_time {}} {solicit_more_p 1}} "Generates the list of comments for this item with the appropriate add/edit links for the general comments system." {

    if [ad_parameter AdminEditingOptionsInlineP "general-comments" 0] {
	# look to see if this person is an administrator
	db_with_handle db {
	    set administrator_p [ad_permission_p $module $submodule]
	}
    } else {
	set administrator_p 0
    }

    # see if the comment system is inactivated for this module
    if ![ad_parameter SolicitCommentsP $module 1] {
	return ""
    }

    set user_id [ad_get_user_id]
    if [empty_string_p $return_url] {
	set return_url [ns_conn url]?[export_ns_set_vars "url"]
    }
    set approved_clause "and general_comments.approved_p = 't'"

    set return_string ""

    set sql "
	select general_comments.comment_id, content, comment_date, 
               first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id,
               html_p as comment_html_p, client_file_name, file_type, original_width, original_height,
               caption, one_line,
               to_char(modified_date, 'Month DD, YYYY HH:MI AM') as pretty_modified_long,
               to_char(modified_date, 'MM/DD/YY HH24:MI') as pretty_modified_time,
               to_char(modified_date, 'MM/DD/YY') as pretty_modified_date
	from general_comments, users
	where on_what_id = :on_what_id 
	and on_which_table = :on_which_table 
	$approved_clause
	and general_comments.user_id = users.user_id
	order by comment_date asc"

    set first_iteration_p 1
    db_foreach comments $sql {
	if $first_iteration_p {
	    append return_string "<h4>Comments</h4>\n"
	    set first_iteration_p 0
	}
        switch $show_time {
            modified_long {
                set extra "on $pretty_modified_long"
            } 
            modified_time {
                set extra "($pretty_modified_time)"
            } 
            modified_date {
                set extra "($pretty_modified_date)"
            } 
            default { 
                set extra {}
            }
        }
                 
	append return_string "<blockquote>\n[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $comment_html_p $one_line]"

	append return_string "<br><br>-- <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a> $extra"
	# if the user posted the comment, they are allowed to edit it
	if {$user_id == $comment_user_id} {
	    append return_string "  <A HREF=\"/general-comments/comment-edit?[export_url_vars comment_id on_which_table on_what_id item module return_url submodule]\">(edit your comment)</a>"
	} elseif { $administrator_p } {
	    append return_string " <A HREF=\"/general-comments/comment-edit?[export_url_vars comment_id on_which_table on_what_id item module submodule return_url]\">(edit)</a>"
	}

	append return_string "</blockquote>\n<br>\n"
    }
    
    if { !$first_iteration_p } {
	append return_string "</blockquote>\n"
    }
    if { $solicit_more_p } { 
        append return_string "
    <center>
    <A HREF=\"/general-comments/comment-add?[export_url_vars on_which_table on_what_id item module return_url]\">Add a comment</a>
    </center>"
    }
    
    return $return_string
}

proc_doc ad_general_comments_summary { on_what_id on_which_table item} "Generates the line item list of comments made on this item." {
    return [ad_general_comments_summary_sorted $on_what_id $on_which_table $item "" "" 1]
}

proc_doc ad_general_comments_summary_sorted { on_what_id on_which_table item { number_to_display -1 } { url_for_more_items "" } {skip_sort 0 } } "Generates the line item list of comments made on this item. Sorts entries by comment_date and allows the user to specify the max entries to return (default is all). If you specify the max entries to return, and there are more, the link (you provide) is added to see them all. This link should basically be your return_url with a flag set so you know what your next call to this procedure will show all items." {

    set user_id [ad_get_user_id]
    set approved_clause "and general_comments.approved_p = 't'"
    set return_url [ns_conn url]?[export_ns_set_vars "url"]

    # For backwards compatibility
    if { $skip_sort } {
	set sort_sql ""
    } else {
	set sort_sql "order by comment_date desc"
    }

    set sql "
	select general_comments.comment_id, content, comment_date, 
	       first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, 
	       html_p as comment_html_p, client_file_name, file_type, original_width, original_height, 
	       caption, one_line
	from general_comments, users
	where on_what_id= :on_what_id 
	and on_which_table = :on_which_table 
	$approved_clause
	and general_comments.user_id = users.user_id 
	$sort_sql"

    set counter 0
    append return_string "<ul>"
    db_foreach general_comments_one_row $sql {
	if { $number_to_display > 0 && $counter >= $number_to_display } {
	    if { ![empty_string_p $url_for_more_items] } {
		append return_string "<li>(<a href=\"$url_for_more_items\">more</a>)\n"
	    }
	    break
	} 
	# if the user posted the comment, they are allowed to edit it
	 append return_string "<li><a href=/general-comments/view-one?[export_url_vars return_url comment_id item]>$one_line ($comment_date)</a> by <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a>"
	if { ![empty_string_p $client_file_name] } {
	    append return_string " <i>Attachment: <a href=\"/general-comments/attachment/$comment_id/$client_file_name\">$client_file_name</a></i>"
	}
	incr counter
    }

    append return_string "</ul>"
}

# Helper procedure for above, to format one comment w/ appropriate 
# attachment link.
proc format_general_comment { comment_id client_file_name file_type original_width original_height caption content comment_html_p {one_line ""}} {
    set return_string ""
    set return_url "[ns_conn url]?[export_ns_set_vars url]"

    if { ![empty_string_p $client_file_name] } {
	# We have an attachment.
	if { [string match "image/*" [string tolower $file_type]] } {
	    # It was an image.
	    if { ![empty_string_p $original_width] 
		 && $original_width < [ad_parameter InlineImageMaxWidth "general-comments" 512] } {
		# It's narrow enough to display inline.
		append return_string "<center><img src=\"/general-comments/attachment/$comment_id/$client_file_name\" width=$original_width height=$original_height><p><i>$caption</i></center><br>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	    } else {
		# Send to an image display page.
		append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n<br><i>Image: <a href=\"/general-comments/image-attachment?[export_url_vars comment_id return_url]\">$client_file_name</a></i>"
	    }
	} else {
	    # Send to raw file download.
	    append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n<br><i>Attachment: <a href=\"/general-comments/attachment/$comment_id/$client_file_name\">$client_file_name</a></i>"
	}
    } else {
	# No attachment
	append return_string "<h4>$one_line</h4>
[util_maybe_convert_to_html $content $comment_html_p]\n"
    }
    return $return_string
}

# ns_register'ed to
# /general-comments/attachment/[comment_id]/[file_name] Returns a
# MIME-typed attachment based on the comment_id. We use this so that
# the user's browser shows the filename the file was uploaded with
# when prompting to save instead of the name of a Tcl file (like
# "raw-file.tcl")
proc ad_general_comments_get_attachment { ignore } {
    if { ![regexp {([^/]+)/([^/]+)$} [ns_conn url] match comment_id client_filename] } {
	ad_return_error "Malformed Attachment Request" "Your request for a file attachment was malformed."
	return
    }
    validate_integer "comment_id" $comment_id

    set file_type [db_string file_type_get {
	select file_type
	from general_comments
	where comment_id = :comment_id
    }]
    
    ReturnHeaders $file_type

    db_write_blob attachment_get "
    select attachment
    from general_comments
    where comment_id = $comment_id"
	
    db_release_unused_handles
}

ad_register_proc GET /general-comments/attachment/* ad_general_comments_get_attachment

## Add general comments to the user contributions summary.
ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "General Comments" 0] == -1 } {
    if { [ad_parameter EnabledP user-contributions 0] == 1 } {
       lappend ad_user_contributions_summary_proc_list [list "General Comments" ad_general_comments_user_contributions 1]
    }
}

proc_doc ad_general_comments_user_contributions {user_id purpose} "Returns a list of priority, title, and an unordered list HTML fragment.  All the general comments posted by a user." {
    if { $purpose == "site_admin" } {
	return [ad_general_comments_user_contributions_for_site_admin $user_id]
    } else {
	return [ad_general_comments_user_contributions_for_web_display $user_id]	
    }
}

# need to go the helper route 
proc ad_general_comments_user_contributions_for_site_admin {user_id} {
    set sql {
	select gc.*, tm.section_name, tm.module_key, tm.admin_url_stub, tm.group_admin_file, ug.short_name,
               decode(gc.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
	from general_comments gc, table_acs_properties tm, user_groups ug
	where gc.user_id = :user_id
	and gc.on_which_table = tm.table_name(+)
	and gc.group_id= ug.group_id(+)
	order by gc.on_which_table, scope_ordering, gc.comment_date desc
    }
    set return_url [ns_conn url]
    set the_comments ""
    set last_section_name ""
    set last_group_id ""
    db_foreach contributions_list $sql {	
	if { $section_name != $last_section_name } {
	    if ![empty_string_p $section_name] {
		append the_comments "<h4>Comments within $section_name</h4>\n"
	    } else {
		append the_comments "<h4>Comments on $on_which_table</h4>\n"
	    }
	    set last_section_name $section_name
	    
	    # for each section do initialization
	    set section_item_counter 0
	    set last_group_id ""
	}	
	switch $scope {
	    public {
		if { $section_item_counter==0 } {
		    set admin_url $admin_url_stub
		}
	    }
	    group { 
		if { $last_group_id!=$group_id } {
		    
		    set row_exists_p [db_0or1row check {
			select section_key
			from content_sections
			where scope='group' and group_id = :group_id
			and module_key= :module_key
		    } ]
			
		    if { $row_exists_p==0 } {
			set admin_url $admin_url_stub
		    } else {			
			set admin_url "[ug_admin_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]/${group_admin_file}"
		    }
		} 
	    } 
	}

	if { [empty_string_p $one_line_item_desc] } {
	    set best_item_description "$section_name ID#$on_what_id"
	} else {
	    set best_item_description $one_line_item_desc
	}

	append the_comments "
	<li>[util_AnsiDatetoPrettyDate $comment_date]
	<blockquote>
	[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $html_p]
	<br><br>-- ([util_AnsiDatetoPrettyDate $comment_date])
	on <a href=\"${admin_url}$on_what_id\">$best_item_description</a>
	<br>
	<br>
	\[ "

	if { $approved_p == "f" } {
	    append the_comments "<a href=\"/admin/general-comments/toggle-approved-p?comment_id=$comment_id&return_url=$return_url\">approve</a> \| "
	}
	append the_comments "
	<a href=\"/admin/general-comments/edit?comment_id=$comment_id\" target=working>edit</a> \| <a href=\"/admin/general-comments/delete?comment_id=$comment_id\" target=working>delete</a> \]
	</blockquote>
	"
	set last_group_id $group_id
	incr section_item_counter
    }

    db_release_unused_handles_sub

    if [empty_string_p $the_comments] {
	return [list]
    } else {
	return [list 1 "General Comments" "<ul>\n\n$the_comments\n\n</ul>"]
    }
}

proc ad_general_comments_user_contributions_for_web_display {user_id} {
    set sql {
	select gc.*, tm.section_name, tm.module_key, tm.user_url_stub, tm.group_public_file, ug.short_name,
	       decode(gc.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
	from general_comments gc, table_acs_properties tm, user_groups ug
	where gc.user_id = :user_id
	and gc.on_which_table = tm.table_name(+)
	and gc.group_id= ug.group_id(+)
	order by gc.on_which_table, scope_ordering, gc.comment_date desc
    }
    set the_comments ""
    set last_section_name ""
    set last_group_id ""
    set section_item_counter 0
    db_foreach unused $sql {	
	if { $section_name != $last_section_name } {
	    if ![empty_string_p $section_name] {
		append the_comments "<h4>Comments within $section_name</h4>\n"
	    } else {
		append the_comments "<h4>Comments on $on_which_table</h4>\n"
	    }
	    set last_section_name $section_name

	    # for each section do initialization
	    set section_item_counter 0
	    set last_group_id ""
	}
	switch $scope {
	    public {
		if { $section_item_counter==0 } {
		    set public_url $user_url_stub
		}
	    }
	    group { 
		if { $last_group_id!=$group_id } {
		    
		    set sub_selection [db_0or1row unused "
		    select section_key
		    from content_sections
		    where scope='group' and group_id=$group_id
		    and module_key='[DoubleApos $module_key]'"]
		    
		    if { { $row_exists_p==0 } } {
			set public_url $user_url_stub
		    } else {
			
			set public_url "[ug_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]/${group_public_file}"
		    }
		} 
	    } 
	}

	if { [empty_string_p $one_line_item_desc] } {
	    set best_item_description "$section_name ID#$on_what_id"
	} else {
	    set best_item_description $one_line_item_desc
	}

	append the_comments "
	<li>[util_AnsiDatetoPrettyDate $comment_date]
	<blockquote>
	[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $html_p]
	<br><br>-- ([util_AnsiDatetoPrettyDate $comment_date])
	on <a href=\"${public_url}$on_what_id\">$best_item_description</a>
	</blockquote>
	"

    }
    
    db_release_unused_handles_sub
    
    if [empty_string_p $the_comments] {
	return [list]
    } else {
	return [list 1 "General Comments" "<ul>\n\n$the_comments\n\n</ul>"]
    }
}

proc_doc general_comments_admin_authorize { comment_id } "given comment_id, this procedure will check whether the user has administration rights over this comment. if comment doesn't exist page is served to the user informing him that the comment doesn't exist. if successfull it will return user_id of the administrator." {

    set comment_exists_p [db_0or1row check "
    select scope, group_id
    from general_comments
    where comment_id=:comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]]

    if { !$comment_exists_p } {
	# comment doesn't exist
	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_admin_header "Comment Doesn't Exist"]
	    [ad_scope_admin_page_title "Comment Doesn't Exist"]
	    [ad_scope_admin_context_bar "No Comment"]
	    <hr>
	    <blockquote>
	    Requested comment does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	ad_script_abort
    }
 
    # faq exists
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

