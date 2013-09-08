# /www/admin/bookmarks/get-site-info.tcl

ad_page_contract {
    populate the database with url titles, live status and meta tags
    Note: this probably should be moved to pl/sql and run nightly
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id get-site-info.tcl,v 3.2.2.6 2000/09/22 01:34:24 kevin Exp
} {} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# this is a proc that should be in the arsdigita procs somewhere
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

set title "Get Site Information"

# we spool this page since it can take a long time (and also access it
# from a softlink so that we can use http instead of https)

set page_content "
[ad_admin_header $title]

<h2> $title </h2>
[ad_admin_context_bar [list "" "Bookmarks"] $title]
<hr>"

# get all the sites that haven't been checked recently

set check_list [db_list_of_lists site_list "
    select unique bm_list.url_id, 
           local_title, 
           complete_url, 
           bookmark_id
    from   bm_list, bm_urls
    where  bm_list.url_id=bm_urls.url_id
    and    last_live_date < sysdate - 1
    order by bookmark_id desc"]

# here we release the database handle in order so that we don't stay connected
# to oracle while this procedure chugs along
db_release_unused_handles

set checked_list [list ]
foreach check_set $check_list {
    set url_id       [lindex $check_set 0]
    set local_title  [lindex $check_set 1]
    set complete_url [lindex $check_set 2]

    # we only want to check http:
    if { [regexp -nocase "^mailto:" $complete_url] ||  [regexp -nocase "^file:" $complete_url] || (![regexp -nocase "^http:" $complete_url] && [regexp {^[^/]+:} $complete_url]) || [regexp "^\\#" $complete_url] } {
	# it was a mailto or an ftp:// or something (but not http://)
	# else that http_open won't like (or just plain #foobar)

	append page_content "Skipping <a href=\"[philg_quote_double_quotes $complete_url]\">$local_title</a>...<br>"
	continue
    } 
    append page_content "Checking <a href=\"[philg_quote_double_quotes $complete_url]\">$local_title</a>..."
    
    # strip off any trailing #foo section directives to browsers
    regexp {^(.*/?[^/]+)\#[^/]+$} $complete_url dummy complete_url
    if [catch { set response [get_http_status $complete_url 0] } errmsg ] {
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
	append page_content " NOT FOUND<br>" 
    } else {
	if {![catch {ns_httpget $complete_url 3 1} url_content]} {
	    set title ""
	    set description ""
	    set keywords ""
	    regexp -nocase {<title>([^<]*)</title>} $url_content match title
	    regexp -nocase {<meta name="description" content="([^"]*)">} $url_content match description
	    regexp -nocase {<meta name="keywords" content="([^"]*)">} $url_content match keywords
	    
	    # truncate outrageously long titles and meta tags
	    if {[string length $title]>100} {
		set title "[string range $title 0 100]..."
	    }
	    if {[string length $keywords]>990} {
		set keywords "[string range $keywords 0 990]..."
	    }
	    if {[string length $description]>990} {
		set description "[string range $description 0 990]..."
	    }
	    lappend checked_pair ", last_live_date=sysdate,
	    url_title= :title,
	    meta_description= :description,
	    meta_keywords= :keywords"
	}
	append page_content " FOUND<br>"
    }
    lappend checked_list $checked_pair
}

foreach checked_pair $checked_list {
    set url_id [lindex $checked_pair 0]
    set last_live_clause [lindex $checked_pair 1]
    db_dml bm_update "
        update bm_urls 
	set    last_checked_date = sysdate$last_live_clause
	where  url_id = :url_id"
}

append page_content "
</ul> Done!  

<a href=\"\">Click</a> to continue.

[ad_admin_footer]"

doc_return  200 text/html "$page_content"




