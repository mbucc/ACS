# /admin/links/blacklist-2.tcl

ad_page_contract {
    Step 2 in blacklisting a link from a page (or all pages)

    @param page_id The page ID (or "*") to blacklist the link on
    @param glob_pattern The URL to blacklist
    @param pattern_id The ID of the new link pattern

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id blacklist-2.tcl,v 3.4.2.7 2000/09/22 01:35:28 kevin Exp
} {
    page_id:notnull
    glob_pattern:notnull
    pattern_id:notnull,naturalnum
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

if { $page_id == "*" } {
    set complete_page_id ""
    set pretty_page_id "everywhere"
} else {
    set url_stub [db_string select_url_stub "select url_stub from static_pages where page_id = :page_id"]
    set complete_page_id $page_id
    set pretty_page_id "from $url_stub"
}

set page_content "[ad_admin_header "Blacklisting $glob_pattern"]

<h2>Blacklisting $glob_pattern</h2>

from <a href=\"index\">the links in [ad_system_name]</a>

<hr>

<ul>

<li>Step 1:  Inserting \"$glob_pattern\" into the table of kill patterns (relevant pages:  $pretty_page_id) ..."

set insert_sql "insert into link_kill_patterns 
(pattern_id, page_id, user_id, date_added, glob_pattern) 
values
(:pattern_id, :complete_page_id, :admin_id, sysdate, :glob_pattern)"

db_dml insert_blacklist $insert_sql

append page_content "DONE

<li>Step 2: Searching through the database to find links that match
this kill pattern.  If you've asked for a blacklist everywhere, this
could take a long time....  
<ul>"

if { $page_id == "*" } {
    set search_sql "select url, page_id
from links"
} else {
    set search_sql "select url 
from links
where page_id = :page_id"
}

db_foreach search_for_url $search_sql {

    if { [string match $glob_pattern $url] } {
	# it matches, kill it
	# subquery for some info about what we're killing; do it with
	# correlation names so that we don't clobber existing variables 
	db_1row kill_link "select 
  links.url as killed_url, 
  links.link_title as killed_title, 
  links.posting_time as killed_posting_time, 
  links.originating_ip as killed_ip, 
  sp.url_stub as killed_url_stub, 
  users.user_id as killed_user_id, 
  users.first_names as killed_first_names, 
  users.last_name as killed_last_name
  from links, static_pages sp, users 
  where links.page_id = sp.page_id
  and links.user_id = users.user_id 
  and links.url = :url
  and links.page_id = :page_id
"

	db_dml delete_link "delete from links 
                            where page_id=:page_id and url=:url"

	set item "<li>Deleted $killed_url ($killed_title) from $killed_url_stub, originally posted by <a href=\"/admin/users/one?user_id=$killed_user_id\">$killed_first_names $killed_last_name</a>\n"
        if ![empty_string_p $killed_ip] {
	    append item "from $killed_ip"
	}
	append page_content "$item\n"
    }
}

db_release_unused_handles

append page_content "</ul>
<p>
</ul>

Done.

[ad_admin_footer]
"

doc_return  200 text/html $page_content