# $Id: ad-general-comments.tcl,v 3.1.4.1 2000/03/14 07:36:35 jkoontz Exp $
# ad-general-comments.tcl
#
# procs for general comment system
# 
# by teadams@arsdigita.com 
# (cleaned up and broken by philg@mit.edu on September 5, 1999)

# this used by www/general-comments/comment-add-3.tcl
# and analogous pages within some modules
proc_doc ad_general_comment_add {db comment_id on_which_table on_what_id one_line_item_desc content user_id ip_address approved_p {html_p "f"} {one_line ""} } "Inserts a comment into the general comment system" {

    ad_scope_error_check

    # let's limit this to 200 chars so we don't blow out our column
    set complete_description '[DoubleApos [string range $one_line_item_desc 0 199]]'
    set sql "
    insert into general_comments
    (comment_id, on_what_id, user_id, on_which_table, one_line_item_desc, content, ip_address, 
     comment_date, approved_p, html_p, one_line, [ad_scope_cols_sql])
    values
    ($comment_id, $on_what_id, $user_id, '[DoubleApos $on_which_table]', $complete_description,
     empty_clob(), '[DoubleApos $ip_address]', sysdate, '$approved_p', '$html_p', 
    [ns_dbquotevalue $one_line], [ad_scope_vals_sql]) returning content into :1"

    if [ad_parameter LogCLOBdmlP acs 0] {
	ns_log Notice "About to use $sql\n -- to put --  \n$content\n\n -- into the database -- \n"
    }

    ns_ora clob_dml $db $sql $content
} 

# this is used by www/general-comments/comment-edit-3.tcl
# and ought to be used by analogous pages within 
# submodules 
proc_doc ad_general_comment_update {db comment_id content ip_address {html_p "f"} {one_line ""}} "Updates a comment in the general comment system. Inserts a row into the audit table as well." { 

    ns_db dml $db "begin transaction" 
    # insert into the audit table

    ns_db dml $db "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content, one_line)
select comment_id, user_id, ip_address, sysdate, modified_date, content, one_line from general_comments where comment_id = $comment_id"

    set sql "update general_comments
set content = empty_clob(),  one_line = [ns_dbquotevalue $one_line],
html_p = '$html_p',
ip_address = '[DoubleApos $ip_address]'
where comment_id = $comment_id returning content into :1"

    if [ad_parameter LogCLOBdmlP acs 0] {
	ns_log Notice "About to use $sql\n -- to update --  \n$content\n\n -- in the database -- \n"
    }

    ns_ora clob_dml $db $sql $content

    ns_db dml $db "end transaction"
}


proc_doc ad_general_comments_list { db on_what_id on_which_table item {module ""} {submodule ""} {return_url ""} {show_time {}} {solicit_more_p 1}} "Generates the list of comments for this item with the appropriate add/edit links for the general comments system." {


    if [ad_parameter AdminEditingOptionsInlineP "general-comments" 0] {
	# look to see if this person is an administrator
	set administrator_p [ad_permission_p $db $module $submodule]
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

    set selection [ns_db select $db "
    select general_comments.comment_id, content, comment_date, 
           first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id,
           html_p as comment_html_p, client_file_name, file_type, original_width, original_height,
           caption, one_line,
           to_char(modified_date, 'Month DD, YYYY HH:MI AM') as pretty_modified_long,
           to_char(modified_date, 'MM/DD/YY HH24:MI') as pretty_modified_time,
           to_char(modified_date, 'MM/DD/YY') as pretty_modified_date
    from general_comments, users
    where on_what_id = $on_what_id 
    and on_which_table = '[DoubleApos $on_which_table]' $approved_clause
    and general_comments.user_id = users.user_id
    order by comment_date asc"]

    set first_iteration_p 1
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
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

	append return_string "<br><br>-- <a href=\"/shared/community-member.tcl?user_id=$comment_user_id\">$commenter_name</a> $extra"
	# if the user posted the comment, they are allowed to edit it
	if {$user_id == $comment_user_id} {
	    append return_string "  <A HREF=\"/general-comments/comment-edit.tcl?[export_url_vars comment_id on_which_table on_what_id item module return_url submodule]\">(edit your comment)</a>"
	} elseif { $administrator_p } {
	    append return_string " <A HREF=\"/general-comments/comment-edit.tcl?[export_url_vars comment_id on_which_table on_what_id item module submodule return_url]\">(edit)</a>"
	}

	append return_string "</blockquote>\n<br>\n"
    }
    
    if { !$first_iteration_p } {
	append return_string "</blockquote>\n"
    }
    if { $solicit_more_p } { 
        append return_string "
    <center>
    <A HREF=\"/general-comments/comment-add.tcl?[export_url_vars on_which_table on_what_id item module return_url]\">Add a comment</a>
    </center>"
    }
    
    return $return_string
}


proc_doc ad_general_comments_summary { db on_what_id on_which_table item} "Generates the line item list of comments made on this item." {
    return [ad_general_comments_summary_sorted $db $on_what_id $on_which_table $item "" "" 1]
}


proc_doc ad_general_comments_summary_sorted { db on_what_id on_which_table item { number_to_display -1 } { url_for_more_items "" } {skip_sort 0 } } "Generates the line item list of comments made on this item. Sorts entries by comment_date and allows the user to specify the max entries to return (default is all). If you specify the max entries to return, and there are more, the link (you provide) is added to see them all. This link should basically be your return_url with a flag set so you know what your next call to this procedure will show all items." {
    set user_id [ad_get_user_id]

    set approved_clause "and general_comments.approved_p = 't'"

    set return_url [ns_conn url]?[export_ns_set_vars "url"]

    # For backwards compatibility
    if { $skip_sort } {
	set sort_sql ""
    } else {
	set sort_sql "order by comment_date desc"
    }

    set selection [ns_db select $db "
    select general_comments.comment_id, content, comment_date, 
    first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, 
    html_p as comment_html_p, client_file_name, file_type, original_width, original_height, 
    caption, one_line
    from general_comments, users
    where on_what_id= $on_what_id 
    and on_which_table = '[DoubleApos $on_which_table]' $approved_clause
    and general_comments.user_id = users.user_id $sort_sql"]

    set counter 0
    append return_string "<ul>"
    while {[ns_db getrow $db $selection]} {
	if { $number_to_display > 0 && $counter >= $number_to_display } {
	    if { ![empty_string_p $url_for_more_items] } {
		append return_string "<li>(<a href=\"$url_for_more_items\">more</a>)\n"
	    }
	    ns_db flush $db
	    break
	} 
	set_variables_after_query
	# if the user posted the comment, they are allowed to edit it
	 append return_string "<li><a href=/general-comments/view-one.tcl?[export_url_vars return_url comment_id item]>$one_line ($comment_date)</a> by <a href=\"/shared/community-member.tcl?user_id=$comment_user_id\">$commenter_name</a>"
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
		append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n<br><i>Image: <a href=\"/general-comments/image-attachment.tcl?[export_url_vars comment_id return_url]\">$client_file_name</a></i>"
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
    set db [ns_db gethandle subquery]

    set file_type [database_to_tcl_string $db "select file_type
from general_comments
where comment_id = $comment_id"]

    ReturnHeaders $file_type

    ns_ora write_blob $db "select attachment
from general_comments
where comment_id = $comment_id"
    
    ns_db releasehandle $db
}

ns_register_proc GET /general-comments/attachment/* ad_general_comments_get_attachment


## Add general comments to the user contributions summary.
ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "General Comments" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "General Comments" ad_general_comments_user_contributions 1]
}


proc_doc ad_general_comments_user_contributions {db user_id purpose} "Returns a list of priority, title, and an unordered list HTML fragment.  All the general comments posted by a user." {
    if { $purpose == "site_admin" } {
	return [ad_general_comments_user_contributions_for_site_admin $db $user_id]
    } else {
	return [ad_general_comments_user_contributions_for_web_display $db $user_id]	
    }
	
}


# need to go the helper route 
proc ad_general_comments_user_contributions_for_site_admin {db user_id} {
    set selection [ns_db select $db "
    select gc.*, tm.section_name, tm.module_key, tm.admin_url_stub, tm.group_admin_file, ug.short_name,
           decode(gc.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
    from general_comments gc, table_acs_properties tm, user_groups ug
    where gc.user_id = $user_id
    and gc.on_which_table = tm.table_name(+)
    and gc.group_id= ug.group_id(+)
    order by gc.on_which_table, scope_ordering, gc.comment_date desc"]

    set return_url [ns_conn url]

    set the_comments ""

    set db_sub [ns_db gethandle subquery]

    set last_section_name ""
    set last_group_id ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
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
		    
		    set sub_selection [ns_db 0or1row $db_sub "
		    select section_key
		    from content_sections
		    where scope='group' and group_id=$group_id
		    and module_key='[DoubleApos $module_key]'"]
		    
		    if { [empty_string_p $sub_selection] } {
			set admin_url $admin_url_stub
		    } else {
			set_variables_after_subquery
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
	    append the_comments "<a href=\"/admin/general-comments/toggle-approved-p.tcl?comment_id=$comment_id&return_url=$return_url\">approve</a> \| "
	}
	append the_comments "
	<a href=\"/admin/general-comments/edit.tcl?comment_id=$comment_id\" target=working>edit</a> \| <a href=\"/admin/general-comments/delete.tcl?comment_id=$comment_id\" target=working>delete</a> \]
	</blockquote>
	"
	set last_group_id $group_id
	incr section_item_counter
    }

    ns_db releasehandle $db_sub

    if [empty_string_p $the_comments] {
	return [list]
    } else {
	return [list 1 "General Comments" "<ul>\n\n$the_comments\n\n</ul>"]
    }
}

proc ad_general_comments_user_contributions_for_web_display {db user_id} {
    set selection [ns_db select $db "
    select gc.*, tm.section_name, tm.module_key, tm.user_url_stub, tm.group_public_file, ug.short_name,
           decode(gc.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
    from general_comments gc, table_acs_properties tm, user_groups ug
    where gc.user_id = $user_id
    and gc.on_which_table = tm.table_name(+)
    and gc.group_id= ug.group_id(+)
    order by gc.on_which_table, scope_ordering, gc.comment_date desc"]

    set the_comments ""

     set db_sub [ns_db gethandle subquery]

    set last_section_name ""
    set last_group_id ""
    set section_item_counter 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
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
		    
		    set sub_selection [ns_db 0or1row $db_sub "
		    select section_key
		    from content_sections
		    where scope='group' and group_id=$group_id
		    and module_key='[DoubleApos $module_key]'"]
		    
		    if { [empty_string_p $sub_selection] } {
			set public_url $user_url_stub
		    } else {
			set_variables_after_subquery
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
    
    ns_db releasehandle $db_sub
    
    if [empty_string_p $the_comments] {
	return [list]
    } else {
	return [list 1 "General Comments" "<ul>\n\n$the_comments\n\n</ul>"]
    }
}

proc_doc general_comments_admin_authorize { db comment_id } "given comment_id, this procedure will check whether the user has administration rights over this comment. if comment doesn't exist page is served to the user informing him that the comment doesn't exist. if successfull it will return user_id of the administrator." {

    set selection [ns_db 0or1row $db "
    select scope, group_id
    from general_comments
    where comment_id=$comment_id"]

    if { [empty_string_p $selection] } {
	# comment doesn't exist
	uplevel {
	    ns_return 200 text/html "
	    [ad_scope_admin_header "Comment Doesn't Exist" $db]
	    [ad_scope_admin_page_title "Comment Doesn't Exist" $db]
	    [ad_scope_admin_context_bar "No Comment"]
	    <hr>
	    <blockquote>
	    Requested comment does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	return -code return
    }
 
    # faq exists
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $db $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code return
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code return
	}
    }
}



