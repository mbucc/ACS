# $Id: blacklist-2.tcl,v 3.1.2.1 2000/04/28 15:09:09 carsten Exp $
set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

set_the_usual_form_variables

# relevant_page_id, glob_pattern

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

if { $page_id == "*" } {
    set complete_page_id "NULL"
    set pretty_page_id "everywhere"
} else {
    set url_stub [database_to_tcl_string $db "select url_stub from static_pages where page_id = $page_id"]
    set complete_page_id $page_id
    set pretty_page_id "from $url_stub"
}

ReturnHeaders

ns_write "[ad_admin_header "Blacklisting $glob_pattern"]

<h2>Blacklisting $glob_pattern</h2>

from <a href=\"index.tcl\">the links in [ad_system_name]</a>

<hr>

<ul>

<li>Step 1:  Inserting \"$glob_pattern\" into the table of kill patterns (relevant pages:  $pretty_page_id) ..."

set insert_sql "insert into link_kill_patterns 
(page_id, user_id, date_added, glob_pattern) 
values
($complete_page_id, $admin_id, sysdate, '$QQglob_pattern')"

ns_db dml $db $insert_sql

ns_write "DONE

<li>Step 2: Searching through the database to find links that match
this kill pattern.  If you've asked for a blacklist everywhere, this
could take a long time....  
<ul>"

if { $page_id == "*" } {
    set search_sql "select rowid,url
from links"
} else {
    set search_sql "select rowid,url 
from links
where page_id = $page_id"
}

set selection [ns_db select $db $search_sql]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { [string match $glob_pattern $url] } {
	# it matches, kill it
	# subquery for some info about what we're killing; do it with
	# correlation names so that we don't clobber existing variables 
	set sub_selection [ns_db 1row $db_sub "select 
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
and links.rowid='$rowid'"]
        set_variables_after_subquery
	ns_db dml $db_sub "delete from links where rowid='$rowid'"
	set item "<li>Deleted $killed_url ($killed_title) from $killed_url_stub, originally posted by <a href=\"/admin/users/one.tcl?user_id=$killed_user_id\">$killed_first_names $killed_last_name</a>\n"
        if ![empty_string_p $killed_ip] {
	    append item "from $killed_ip"
	}
	ns_write "$item\n"
    }
}

ns_write "</ul>
<p>
</ul>

Done.

[ad_admin_footer]
"
