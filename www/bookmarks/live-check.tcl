# /www/bookmarks/live-check.tcl

ad_page_contract {

    Checks all links and gets an error code for each
    @param return_url the URL for user to return to
    @author  aure@arsdigita.com
    @created June 1999
    @cvs-id  live-check.tcl,v 3.2.2.7 2000/09/22 01:37:02 kevin Exp
} {
    {return_url:trim ""}
}

# note this should be included in the ACS procs somewhere

proc get_http_status {url {use_get_p 0} {timeout 30}} { 
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

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# return headers to spool out this slowly generating page
set page_title "Checking Your Bookmarks"

set page_content "
[ad_header $page_title ]

<h2> $page_title </h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]

<hr>

Links that aren't reachable will appear with a checkbox in front of
them and the words <font color=red>NOT FOUND</font> after the link.
If you want to delete these links, simply click the checkbox and then
the \"Delete selected links\" button at the bottom of the page.

<form action=delete-dead-links method=post>"

set check_list [db_list_of_lists bookmark_list "
select unique bm_list.url_id, 
       local_title, 
       complete_url
from   bm_list, 
       bm_urls
where  owner_id = :user_id
and    bm_list.url_id = bm_urls.url_id"]

# releasing the database here because checking all of someone's bookmarks could tie
# up the database for a long time

db_release_unused_handles

if [empty_string_p $check_list] {
    append page_content "you have no bookmarks to check.
    <p>
    [ad_footer]"
    doc_return  200 text/html "$page_content"
    return
}

set dead_count 0

foreach check_set $check_list {
    set url_id       [lindex $check_set 0]
    set local_title  [lindex $check_set 1]
    set complete_url [lindex $check_set 2]

    # we only want to check http:

    if { [regexp -nocase "^mailto:" $complete_url] ||  [regexp -nocase "^file:" $complete_url] || (![regexp -nocase "^http:" $complete_url] && [regexp {^[^/]+:} $complete_url]) || [regexp "^\\#" $complete_url] } {
	# it was a mailto or an ftp:// or something (but not http://)
	# else that http_open won't like (or just plain #foobar)

	append page_content "
	<table border=0 cellpadding=0 cellspacing=0>
	<tr>
	<td width=50 align=right></td>
	<td> Skipping <a href=\"[philg_quote_double_quotes $complete_url]\">$local_title</a>....</td>
	</tr>
	</table>"
	
	continue
    } 
   
    # strip off any trailing #foo section directives to browsers
    regexp {^(.*/?[^/]+)\#[^/]+$} $complete_url dummy complete_url
    if [catch { set response [get_http_status $complete_url] } errmsg ] {
	# we got an error (probably a dead server)
	set response "probably the foreign server isn't responding at all"
    }
    if {$response == 404 || $response == 405 || $response == 500 } {
	# we should try again with a full GET 
	# because a lot of program-backed servers return 404 for HEAD
	# when a GET works fine
	if [catch { set response [get_http_status $complete_url 1] } errmsg] {
	    set response "probably the foreign server isn't responding"
	} 
    }

    set checked_pair $url_id
    if { $response != 200 && $response != 302 } {
	lappend checked_pair " "
	append page_content "
	<table border=0 cellpadding=0 cellspacing=0>
	<tr>
	<td width=50 align=right>
	<input type=checkbox name=deleteable_link value=$url_id></td>
	<td><a href=\"[philg_quote_double_quotes $complete_url]\">$local_title</a>.... <font color=red>NOT FOUND</font> $response </td></tr></table>\n"
	incr dead_count
    } else {
	lappend checked_pair ", last_live_date=sysdate"
	append page_content "
	<table border=0 cellpadding=0 cellspacing=0>
	<tr>
	<td width=50 align=right></td>
	<td><a href=\"[philg_quote_double_quotes $complete_url]\">$local_title</a>.... FOUND</td>
	</tr>
	</table>\n"
    }
    lappend checked_list $checked_pair
}

foreach checked_pair $checked_list {
    set url_id           [lindex $checked_pair 0]
    set last_live_clause [lindex $checked_pair 1]

    # this does many database updates instead of just one

    db_dml bookmark_update_last_checked "
    update bm_urls 
    set    last_checked_date = sysdate
    $last_live_clause
    where  url_id = :url_id"
    db_release_unused_handles
}

append page_content "</ul> Done! <a href=$return_url>Click</a> to continue"

if {$dead_count > 0} {
    append page_content "
    or <input type=submit value=\"Delete selected links\">
    [export_form_vars return_url]
    </form>"

}

append page_content "[bm_footer]"

doc_return 200 text/html "$page_content"
















