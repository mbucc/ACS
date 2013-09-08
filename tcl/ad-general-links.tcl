# tcl/ad-general-links.tcl

ad_library {
    Procedures for general links system.

    @author Bob Cassels (bcassels@arsdigita.com)
    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @author Jack Chung (flattop@arsdigita.com)
    @author taken from authors of general-comments :)
    @cvs-id ad-general-links.tcl,v 3.3.2.3 2000/07/15 23:27:47 ryanlee Exp
}

# this used by www/general-links/link-add-3.tcl
# and analogous pages within some modules
ad_proc -public ad_general_link_add {link_id url link_title link_description user_id ip_address approved_p} "Inserts a link into the general links system" {

    db_dml add_general_link {insert into general_links
(link_id, url, link_title, link_description, creation_time, creation_user, creation_ip_address, approved_p, last_approval_change)
values
(:link_id, :url, :link_title, :link_description, sysdate, :user_id, :ip_address, :approved_p, sysdate)}

    db_release_unused_handles

}

ad_proc -public ad_general_link_map_add {map_id link_id on_which_table on_what_id one_line_item_desc user_id ip_address approved_p } "Inserts a link between a general link and a table" {

    # let's limit this to 200 chars so we don't blow out our column
    set complete_description '[string range $one_line_item_desc 0 199]'

    db_dml add_general_link_map {insert into site_wide_link_map
(map_id, link_id, on_which_table, on_what_id, one_line_item_desc, creation_user, creation_time, creation_ip_address, approved_p)
values
(:map_id, :link_id, :on_which_table, :on_what_id, :complete_description, :user_id, sysdate, :ip_address, :approved_p)}

    db_release_unused_handles

} 

# this is used by www/general-links/link-edit-3.tcl
# and ought to be used by analogous pages within 
# submodules 
ad_proc -public ad_general_link_update {link_id url link_title link_description ip_address} "Updates a link in the general links system. No audit yet, though. . ." { 

    db_dml update_general_link {update general_links
set url = :url,
link_title = :link_title,
link_description = :link_description,
creation_ip_address = :ip_address
where link_id = :link_id}

    db_release_unused_handles

}

ad_proc -public ad_general_links_list { on_what_id on_which_table item {module ""} {submodule ""} {return_url ""}} "Generates the list of links for this item with the appropriate add/edit links for the general links system." {

    set user_id [ad_get_user_id]
    if [empty_string_p $return_url] {
	set return_url [ns_conn url]?[export_ns_set_vars "url"]
    }
    set approved_clause "and slm.approved_p = 't' and gl.approved_p = 't'"

    set return_string ""

    set sql_qry "select gl.link_id, gl.url, link_title, link_description, slm.map_id, slm.creation_time, first_names || ' ' || last_name as linker_name, u.user_id as link_user_id
    from general_links gl, site_wide_link_map slm, users u
    where gl.link_id = slm.link_id 
    and on_what_id = :on_what_id
    and on_which_table = :on_which_table $approved_clause
    and slm.creation_user = u.user_id"

    set first_iteration_p 1
    db_foreach print_links $sql_qry {
	if $first_iteration_p {
	    append return_string "<h4>Links</h4>\n"
	    set first_iteration_p 0
	}
	
	append return_string "<blockquote>\n[ad_general_link_format $link_id $url $link_title $link_description]"
		
	append return_string "<br><br>-- <a href=\"/shared/community-member?user_id=$link_user_id\">$linker_name</a>"
   
	if { !$first_iteration_p } {
	    append return_string "</blockquote>\n"
	}
    }

    db_release_unused_handles

    append return_string "
    <center>
    <A HREF=\"/general-links/link-add?[export_url_vars on_which_table on_what_id item module return_url]\">Add a link</a>
    </center>
    "
}

ad_proc -public ad_general_links_summary { on_what_id on_which_table item} "Generates the line item list of links made on this item." {
    set user_id [ad_get_user_id]

    set approved_clause "and slm.approved_p = 't' and gl.approved_p = 't'"

    set return_url [ns_conn url]?[export_ns_set_vars "url"]

    set sql_qry "select gl.link_id, gl.url, link_title, link_description, slm.map_id, slm.creation_time, first_names || ' ' || last_name as linker_name, u.user_id as link_user_id
    from general_links gl, site_wide_link_map slm, users u
    where gl.link_id = slm.link_id 
    and on_what_id = :on_what_id
    and on_which_table = :on_which_table $approved_clause
    and slm.user_id = u.user_id"

    append return_string "<ul>"

    db_foreach print_link_summary $sql_qry {
	if {[ad_parameter ClickthroughP general-links] == 1} {
	    set exact_link "/ct/ad_link_${link_id}?send_to=$url"
	} else {
	    set exact_link "$url"
	}

	append return_string "<li><a href=/general-links/one-link?[export_url_vars return_url link_id item]><a href=\"$exact_link\">$link_title</a> ($creation_time)</a> by <a href=\"/shared/community-member?user_id=$link_user_id\">$linker_name</a>"
    }

    db_release_unused_handles

    append return_string "</ul>"
}

# Helper procedure for above, to format one link.
ad_proc -private ad_general_link_format { link_id url link_title link_description } "Formats one link for consistent look in other procs/pages." {
    
    if {[ad_parameter ClickthroughP general-links] == 1} {
	set exact_link "/ct/ad_link_${link_id}?send_to=$url"
    } else {
	set exact_link "$url"
    }

    set return_string "
    <a href=\"$exact_link\"><b>$link_title</b></a>
    "
    if {![empty_string_p $link_description]} {
	append return_string "<p>$link_description"
    }
    return $return_string
}

# procedure to display link rating html
ad_proc -public ad_general_link_format_rating {link_id {rating_url ""}} "Form for entering rating." {

    set user_id [ad_get_user_id]

    set user_rating [db_string select_ "select rating from general_link_user_ratings where user_id = :user_id and link_id = :link_id" -default ""]

    db_release_unused_handles

    if {[empty_string_p $rating_url]} {
	set rating_url "link-rate"
    }

    set rating_html "<form method=post action=\"$rating_url\">
    [export_form_vars link_id]
    <select name=rating>
    "
    set current_rating 0
    while { $current_rating <= 10 } {
	if { $user_rating == $current_rating } {
	    append rating_html "<option value=\"$current_rating\" selected>$current_rating "
	} else {
	    append rating_html "<option type=radio name=rating value=\"$current_rating\">$current_rating "
	}

	incr current_rating
    }
    append rating_html "</select>"
    if {[empty_string_p $user_rating]} {
	append rating_html "<input type=submit value=\"Rate Link\"> - you have not rated this link; would you like to?</form>"
    } else {
	append rating_html "<input type=submit value=\"Change Rating\"> - you have given this link a rating of $user_rating; would you like to change this rating?</form>"
    }
}

# procedure to display results of rating for a link
ad_proc -private ad_general_link_format_rating_result {link_id} "Displays link's rating." {

    if { ![db_0or1row select_rating_stats "
    select n_ratings, avg_rating
    from general_links
    where link_id = $link_id
    "] } {
	set n_ratings 0
	set avg_rating 0
    }

    db_release_unused_handles

    if { $n_ratings == 0 } {
	return "
	<b>No ratings</b>
	"
    } else {
	return "
	<b>Average Rating</b>: $avg_rating; <b>Number of Ratings</b>: $n_ratings
	"
    }

}

###################################################
### I stole this proc from get-site-info.tcl in /admin/bookmarks
###                                 - tzumain@arsdigita.com
###################################################
# this is a proc that should be in the arsdigita procs somewhere
ad_proc -private get_http_status {url {use_get_p 0} {timeout 30}} { 
    if $use_get_p {
	set http [ns_httpopen GET $url "" $timeout] 
    } else {
	set http [ns_httpopen HEAD $url "" $timeout] 
    }
    # philg changed these to close BOTH rfd and wfd
    set rfd [lindex $http 0] 
    set wfd [lindex $http 1] 
    close $rfd
    close $wfd
    set headers [lindex $http 2] 
    set response [ns_set name $headers] 
    set status [lindex $response 1] 
    ns_set free $headers
    return $status
}

### procedure to check a link and steal its meta tags,
### based on code from get-site-info.tcl in admin/bookmarks
ad_proc -private ad_general_link_check {link_id} "checks a link and steals meta tags" {

    set url [db_string select_url {select url from general_links where link_id = :link_id}]

    db_transaction {
	db_dml update_last_checked {update general_links set last_checked_date=sysdate where link_id = :link_id}

	# strip off any trailing #foo section directives to browsers
	set complete_url $url
	regexp {^(.*/?[^/]+)\#[^/]+$} $complete_url match complete_url
	if [catch { set response [get_http_status $complete_url 0] } errmsg ] {
	    # we got an error (probably a dead server)
	    return $errmsg
	} elseif {$response == 404 || $response == 405 || $response == 500 } {
	    # we should try again with a full GET 
	    # because a lot of program-backed servers return 404 for HEAD
	    # when a GET works fine
	    if [catch { set response [get_http_status $complete_url 1] } errmsg] {
		# probably the foreign server isn't responding
		return "server not responding"
	    }
	}
    } on_error {
	return "error in databse transaction!"
    }


    if { $response != 200 && $response != 302 } {
	return "error in reaching server"
    } else {
	if {![catch {ns_httpget $complete_url 3 1} url_content]} {
	    
	    set meta_description ""
	    set meta_keywords ""
	    
	    regexp -nocase {<meta name="description" content="([^"]*)">} $url_content match meta_description
	    regexp -nocase {<meta name="keywords" content="([^"]*)">} $url_content match meta_keywords
	    
	    # process and truncate outrageously long meta tags

	    if {[string length $meta_keywords]>4000} {
		set meta_keywords "[string range $meta_keywords 0 3996]..."
	    }
	    if {[string length $meta_description]>4000} {
		set meta_description "[string range $meta_description 0 3996]..."
	    }
	} else {
	    return $url_content
	}
    }

    db_dml update_link {update general_links
    set meta_description = :meta_description,
    meta_keywords = :meta_keywords,
    last_live_date = sysdate
    where link_id = :link_id
    }

    return 1

}

ad_proc -private ad_general_link_get_title {url} "gets a link title from a url" {

    # strip off any trailing #foo section directives to browsers
    set complete_url $url
    regexp {^(.*/?[^/]+)\#[^/]+$} $complete_url match complete_url
    if [catch { set response [get_http_status $complete_url 0] } errmsg ] {
	# we got an error (probably a dead server)
	return ""
    } elseif {$response == 404 || $response == 405 || $response == 500 } {
	# we should try again with a full GET 
	# because a lot of program-backed servers return 404 for HEAD
	# when a GET works fine
	if [catch { set response [get_http_status $complete_url 1] } errmsg] {
	    # probably the foreign server isn't responding
	    return ""
	} 
    }

    if { $response != 200 && $response != 302 } {
	return ""
    } else {
	if {![catch {ns_httpget $complete_url 3 1} url_content]} {
	    
	    set link_title ""
	    
	    regexp -nocase {<title>(.*)</title} $url_content match link_title

	    # process and truncate outrageously long titles

	    if {[string length $link_title]>100} {
		set link_title "[string range $link_title 0 96]..."
	    }
	} else {
	    return ""
	}
    }

    return $link_title

}