# /bookmarks/insert-one.tcl
#
# finds title information and give s the user folder placement options
#
# by dh@arsdigita.com and aure@arsdigita.com, June 1999
#
# $Id: insert-one.tcl,v 3.0.4.3 2000/04/28 15:09:46 carsten Exp $

ad_page_variables {
    complete_url
    local_title
    return_url
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
    return
}

# check that the 'complete_url' isn't blank
if {[empty_string_p $complete_url]} {
    set title "Missing URL"
    ns_return 200 text/html  "[ad_header $title] 
    <h2>$title</h2>

    [ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] [list "import" "Add"] $title]
    <hr>
    You left the URL field empty - to add link you must enter a URL.
    [bm_footer]"

    return
}

# see if 'complete_url' is missing the protocol (ie https:// ) - if so set complete_url "http://$complete_url"

if { ![regexp {^[^:\"]+://} $complete_url] } {
    set complete_url "http://$complete_url"
}

if {[empty_string_p $local_title]} {
    if {[catch {ns_httpget $complete_url 10} url_content]} {
	set errmsg "
	We're sorry but we can not detect a title for this bookmark,
	the URL is unreachable. <p> If you still want to add this bookmark now,
	press \[Back\] on your browser and check the URL or type in a title.
	"
    } else {
	regexp -nocase {<title>([^<]*)</title>} $url_content match local_title
	if {[empty_string_p $local_title]} {
	    set errmsg "
	    We're sorry but we can not detect a title for this bookmark,
	    the host does not provide one.  <p>If you still want to add this 
	    bookmark now,
	    press \[Back\] on your browser and check the URL or type in a title.
            "
	}
    }
}

set title "Inserting \"[string trim $local_title]\""

set page_content "[ad_header $title]

<h2>$title</h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] [list "import" "Add"] $title]

<hr>"

set db [ns_db gethandle]

# get the next bookmark_id (used as primary key in bm_list)
set bookmark_id [database_to_tcl_string $db "select bm_bookmark_id_seq.nextval from dual"]

if {[empty_string_p $local_title]} {
    append page_content $errmsg
} else {

    append page_content "
    
    You will be adding: 
    <ul> 
    <li>$local_title
    <li><a href=$complete_url>$complete_url</a>
    </ul>
    <form action=insert-one-2 method=post>
    [export_form_vars local_title complete_url bookmark_id return_url]
    
    If this is correct, choose which folder to place the bookmark in:
    <ul>
    <table>
    <tr>
    <td>
    [bm_folder_selection $db $user_id $bookmark_id]
    <p>
    <input type=submit value=Submit>
    </td>
    </tr>
    </table>
    </form>
    </ul>"
}

append page_content "
[bm_footer]"

ns_return 200 text/html $page_content









