ad_library {
    Stuff for serving static .html files.

    @author Philip Greenspun [philg@arsdigita.com]
    @creation-date 7/1/98
    @cvs-id ad-html.tcl,v 3.11.2.9 2000/09/22 01:33:56 kevin Exp
}

# any request for a static html file will go through this proc
# one good thing about doing things this way is that our site 
# still looks static to AltaVista

if { ![ad_parameter "EnableAbstractURLsP" "abstract-url" 0] } {
    ad_register_proc GET /*.html ad_serve_html_page
    ad_register_proc GET /*.htm ad_serve_html_page
    ad_register_proc GET /*.html_* ad_serve_html_page
    ad_register_proc GET /*.htm_* ad_serve_html_page
}

# this must stand for "do not disturb"
# if you put it into a static .html file, the 
# following Tcl proc serves the page unmolested

proc ad_dnd_tag {} {
    return "<!--AD_DND-->"
}

proc_doc ad_space { {n 1} } "returns n spaces in html (uses nbsp)" {
    set result ""
    for {set i 0} {$i < $n} {incr i} {
	append result "&nbsp;"
    }
    #append result " "
    return $result
}

proc_doc ad_naked_html_patterns {} {
    This proc returns a list of patterns for pages that should not have the comments stuff put in.
} {
    set glob_patterns [list]
    lappend glob_patterns "/doc/*"
    lappend glob_patterns "/admin/*"
    lappend glob_patterns "/pages/*"
    lappend glob_patterns "/ct*"
    lappend glob_patterns "[ad_parameter GlobalURLStub "" "/global"]/*"
    return $glob_patterns 
}

proc_doc ad_serve_html_page {ignore} {

    The procedure that actually serves all the HTML pages on an ACS.
    It looks first to see if the file is in one of the naked_html
    directories.  If so, it simply returns the raw bytes.  It then looks
    to see if the ad_dnd_tag ("do not disturb") comment pattern is
    present.  Again, if so, it simply returns.  Otherwise, the procedure
    tries to add comments and related links.  If the database is busy, it
    will simply add links to comments and related links.

} {
    set url_stub [ad_conn canonical_url]
    append url_stub [file extension [ad_conn file]]

    if { [empty_string_p $url_stub] } {
        set url_stub [ns_conn url]
    }

    set full_filename [ad_conn file]
    if { [empty_string_p $full_filename] } {   
	set full_filename [ns_url2file $url_stub]
    }

    set type [ns_guesstype $url_stub]

    foreach naked_pattern [ad_naked_html_patterns] {
	if [string match $naked_pattern $url_stub] {
	    ad_returnfile 200 $type $full_filename
	    return
	}
    }

    if { ![file exists $full_filename]} {
	# check to see if the file exists
	# if not, return a "file not found" message
	set file_name_url "[ad_parameter GlobalURLStub "" "/global"]/file-not-found.html"
	set full_path [ns_url2file $file_name_url]
	if [file exists $full_path] {
	    ad_returnfile 404 text/html $full_path
	} else {
	    doc_return  404 text/plain "File not found"
	}
	return
    }

    set encoding [ns_encodingfortype $type]
    set stream   [open $full_filename r]
    fconfigure $stream -encoding $encoding
    set whole_page [read $stream]
    close $stream

    # sometimes we don't want comments to come up for a given page
    if {[string first [ad_dnd_tag] $whole_page] != -1} {
	doc_return  200 $type $whole_page
	return
    }

    if { [regexp -nocase {(.*)</body>(.*)} $whole_page match pre_body post_body] } {
	# there was a "close body" tag, let's try to insert a comment
	# link at least
	# before we do anything else, let's stream out what we can
	set whole_page   [static_add_curriculum_bar_if_necessary $pre_body]	
	set moby_list    [static_get_comments_and_links $url_stub $post_body]
	set comment_link_options_fragment [static_format_comments_and_links $moby_list]

	# now decide what to do with the comments and links we've queried from the database
	append whole_page "$comment_link_options_fragment\n\n</body>$post_body"
	doc_return  200 $type $whole_page
    } else {
	# couldn't find a </body> tag
	doc_return  200 $type $whole_page
    }
}

# helper proc for sticking in curriculum bar when necessary

proc_doc static_add_curriculum_bar_if_necessary {pre_body} "Returns the page, up to the close body tag, with a curriculum bar added if necessary" {
    if { ![ad_parameter EnabledP curriculum 0] || ![ad_parameter StickInStaticPagesP curriculum 0] } {
	return $pre_body
    }
    set curriculum_bar [curriculum_bar]
    if [empty_string_p $curriculum_bar] {
	# we are using the curriculum system but this user doesn't need a bar
	return $pre_body
    }
    # let's look for a good place to stuff the bar
    # rely on maximal matching in REGEXP
    if { [regexp -nocase {(.*)<hr>(.*)} $pre_body match up_to_last_hr after_last_hr] } {
	# we found at least one HR, let's make sure that it is indeed
	# at the bottom of the page
	if { [string length $up_to_last_hr] > [string length $after_last_hr] } {
	    # this is indeed probably the last
	    append pre_body_with_curriculum_bar $up_to_last_hr "\n<center>[curriculum_bar]</center>\n" "<HR>" $after_last_hr
	} else {
	    # found an HR but probably it isn't the last one
	    append pre_body_with_curriculum_bar $pre_body "\n<center>[curriculum_bar]</center>\n"
	}
    } else {
	append pre_body_with_curriculum_bar $pre_body "\n<center>[curriculum_bar]</center>\n"
    }
    return $pre_body_with_curriculum_bar
}


# helper proc for coming back with options, info, etc. 

proc_doc static_get_comments_and_links {url_stub {post_body ""}} {
    Returns a list of comment_bytes link_bytes options_list comment_option link_option 
    or the empty string if this page isn't
    registered in the database 
} {
    set user_id [ad_get_user_id]
   
    if { ![db_0or1row html_id_get { 
	select page_id, accept_comments_p, accept_links_p, inline_comments_p, inline_links_p 
	from static_pages 
	where url_stub = :url_stub
    }] } {
	# this page isn't registered in the database so we can't
	# accept comments on it or anything
	ns_log Notice "Someone grabbed $url_stub but we weren't able to offer a comment link because this page isn't registered in the db"
	return ""
    } else {
	set options_list [list]
	set comment_bytes ""
	if { $inline_comments_p == "t" } {
	    # we display comments in-line
	    db_foreach all_comments {
		select comments.comment_id, comments.page_id, comments.user_id as poster_user_id, 
			users.first_names || ' ' || users.last_name as user_name, message, posting_time, 
			html_p, client_file_name, file_type, original_width, original_height, caption
	    from static_pages sp, comments_not_deleted comments, users
		where sp.page_id = comments.page_id
		and comments.user_id = users.user_id
		and comments.page_id = :page_id
		and comments.comment_type = 'alternative_perspective'
		order by posting_time
	    } {
		append comment_bytes "<blockquote>
		[format_static_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $message $html_p]
		"
		if { $user_id == $poster_user_id} {
		    # the user wrote the message, so let him/her edit it
		    append comment_bytes " &nbsp; \[ <A HREF=\"/comments/persistent-edit?comment_id=$comment_id\">edit your comment</a> \]\n"
		}
		
		append comment_bytes "<br><br>\n
-- <A HREF=\"/shared/community-member?user_id=$poster_user_id\">$user_name</a>"
		append comment_bytes ", [util_AnsiDatetoPrettyDate $posting_time]"
		append comment_bytes "</blockquote>\n"
	    }
	}
	if { $accept_comments_p == "t" && $inline_comments_p == "t" } {
	    # we only display the option if we're inlining comments; 
	    # we assume that if the comments aren't in line but are legal
	    # then the publisher has an explicit link 
	    set comment_option "<a href=\"/comments/add?page_id=$page_id\">Add a comment</a>"
	    lappend options_list $comment_option
	} else {
	    set comment_option ""
	}

	# links
	set link_bytes ""
	if { $inline_links_p == "t" } {

	    db_foreach all_links {
		select links.page_id, links.user_id as poster_user_id, 
		users.first_names || ' ' || users.last_name as user_name, links.link_title, 
		links.link_description, links.url
	    from static_pages sp, links, users
		where sp.page_id = links.page_id
		and users.user_id = links.user_id
		and links.page_id = :page_id
		and status = 'live'
		order by posting_time
	    } {
		append link_bytes "<li><a href=\"$url\">$link_title</a>- $link_description"
		
		if { $user_id == $poster_user_id} {
		    # the user added, so let him/her edit it
		    append link_bytes "&nbsp;&nbsp;(<A HREF=\"/links/edit?page_id=$page_id&url=[ns_urlencode $url]\">edit/delete</a>)"
		} else {
		    # the user did not add it, link to the community_member page
		    append link_bytes "&nbsp;&nbsp;  <font size=-1>(contributed by <A HREF=\"/shared/community-member?user_id=$poster_user_id\">$user_name</a>)</font>"
		}
		append link_bytes "\n<p>\n"
	    }
	}
	if { $accept_links_p == "t" && $inline_links_p == "t" } {
	    # we only display the option if we're inlining links; 
	    # we assume that if the links aren't in line but are legal
	    # then the publisher has an explicit link 
	    set link_option "<a href=\"/links/add?page_id=$page_id\">Add a link</a>"
	    lappend options_list $link_option
	} else {
	    set link_option ""
	}
    }
    return [list $comment_bytes $link_bytes $options_list $comment_option $link_option]
}

# helper proc for formatting comments, links, etc.

proc_doc static_format_comments_and_links {moby_list} {
    Takes list of comment_bytes link_bytes options_list comment_option
    link_option and produces HTML fragment to stick at bottom of page.
} {
    if [empty_string_p $moby_list] {
	return ""
    }
    set comment_bytes [lindex $moby_list 0]
    set link_bytes [lindex $moby_list 1]
    set options_list [lindex $moby_list 2]
    set comment_option [lindex $moby_list 3]
    set link_option [lindex $moby_list 4]
    if { [empty_string_p $comment_bytes] && [empty_string_p $link_bytes] } {
	if { [llength $options_list] > 0 } {
	    set centered_options "<center>[join $options_list " | "]</center>"
	} else {
	    set centered_options ""
	}
	return $centered_options
    } elseif { ![empty_string_p $comment_bytes] && [empty_string_p $link_bytes] } {
	# there are comments but no links
	return "<center><h3>Reader's Comments</h3></center>
	$comment_bytes
	<center>[join $options_list " | "]</center>"
    } elseif { [empty_string_p $comment_bytes] && ![empty_string_p $link_bytes] } {
	# links but no comments 
	return "<center><h3>Related Links</h3></center>
	<ul>$link_bytes</ul>
	<center>[join $options_list " | "]</center>"
    } else {
	# comments and links 
	return "<center><h3>Reader's Comments</h3></center>
	$comment_bytes
	<center>
	$comment_option
	</center>
	<center><h3>Related Links</h3></center>
	<ul>$link_bytes</ul>
	<center>
	$link_option
	</center>"
    }
}

# Helper procedure for formatting 'alternative_perspective' comments on static
# pages, which presents inline images or attachment links as appropriate.
# Taken from a similar procedure in ad-general-comments.tcl.
proc format_static_comment { comment_id client_file_name file_type original_width original_height caption content comment_html_p } {
    set return_string ""
    set return_url "[ns_conn url]?[export_ns_set_vars url]"

    if { ![empty_string_p $client_file_name] } {
	# We have an attachment.
	if { [string match "image/*" [string tolower $file_type]] } {
	    # It was an image.
	    if { ![empty_string_p $original_width] 
		 && $original_width < [ad_parameter InlineImageMaxWidth "comments" 512] } {
		# It's narrow enough to display inline.
		append return_string "<center><img src=\"/comments/attachment/$comment_id/$client_file_name\" width=$original_width height=$original_height><p><i>$caption</i></center><br>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	    } else {
		# Send to an image display page.
		append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n<br><i>Image: <a href=\"/comments/image-attachment?[export_url_vars comment_id return_url]\">$client_file_name</a></i>"
	    }
	} else {
	    # Send to raw file download.
	    append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n<br><i>Attachment: <a href=\"/comments/attachment/$comment_id/$client_file_name\">$client_file_name</a></i>"
	}
    } else {
	# No attachment
	append return_string "[util_maybe_convert_to_html $content $comment_html_p]\n"
    }
    return $return_string
}

proc_doc send_author_comment_p { comment_type action } "Returns email notification state type of html comment" {

    if { [string compare $action "add"] == 0 } {

	switch $comment_type {
	    "unanswered_question" { return [ad_parameter EmailNewUnansweredQuestion comments] }
	    "alternative_perspective" { return [ad_parameter EmailNewAlternativePerspective comments] }
	    "rating" { return [ad_parameter EmailNewRating comments] }
	    default  { return 0 }
	}

    } else {

	switch $comment_type {
	   "unanswered_question" { return [ad_parameter EmailEditedUnansweredQuestion comments] }
	   "alternative_perspective" { return [ad_parameter EmailEditedAlternativePerspective comments] }
	   "rating" { return [ad_parameter EmailEditedRating comments] }
	    default  { return 0 }
	}
    }
}

# ns_register'ed to
# /comments/attachment/[comment_id]/[file_name] Returns a
# MIME-typed attachment based on the comment_id. We use this so that
# the user's browser shows the filename the file was uploaded with
# when prompting to save instead of the name of a Tcl file (like
# "raw-file.tcl")
# Stolen from ad-general-comments.tcl.

proc ad_static_comments_get_attachment { ignore } {
    if { ![regexp {([^/]+)/([^/]+)$} [ns_conn url] match comment_id client_filename] } {
	ad_return_error "Malformed Attachment Request" "Your request for a file attachment was malformed."
	return
    }

    # make sure comment_id is an integer
    validate_integer "comment_id" $comment_id

    set file_type [db_string comment_attachment_type_get {
	select file_type
	from comments
	where comment_id = :comment_id
    }]

    ReturnHeaders $file_type
    # This needs to be tested.
    db_write_blob attachment_write "
	select attachment
	from comments
	where comment_id = $comment_id
    " 		     
    db_release_unused_handles
}

ad_register_proc GET /comments/attachment/* ad_static_comments_get_attachment
