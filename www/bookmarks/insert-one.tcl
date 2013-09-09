# /www/bookmarks/insert-one.tcl

ad_page_contract {
    finds title information and give s the user folder placement options
    @param complete_url the complete url for bookmark
    @param local_title the title for bookmark
    @param return_url the URL for user to return to
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id insert-one.tcl,v 3.2.6.9 2001/01/09 22:52:13 khy Exp
} {
    complete_url:trim,notnull
    {local_title ""}
    return_url:trim
} 

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
    return
}

# see if 'complete_url' is missing the protocol (ie https:// ) - if so set complete_url "http://$complete_url"

if { ![regexp {^[^:\"]+://} $complete_url] } {
    set complete_url "http://$complete_url"
}

if {[catch {ns_httpget $complete_url 10} url_content]} {
    ad_return_complaint 1 "
    We're sorry, the URL is unreachable. <p> If you still want to add this bookmark now,
    press \[Back\] on your browser and check the URL or type in a title.
    "
} else {

    # If user did not enter a title for the bookmark, we need to assign remote page title
    if {[empty_string_p $local_title]} {
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

# get the next bookmark_id (used as primary key in bm_list)
set bookmark_id [db_string bm_id "select bm_bookmark_id_seq.nextval from dual"]

db_release_unused_handles 

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
    [export_form_vars local_title complete_url return_url]
    [export_form_vars -sign bookmark_id]
    If this is correct, choose which folder to place the bookmark in:
    <ul>
    <table>
    <tr>
    <td>
    [bm_folder_selection $user_id $bookmark_id]
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

doc_return 200 text/html $page_content













