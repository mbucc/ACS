# $Id: apply-to-old-data.tcl,v 3.0 2000/02/06 03:27:38 ron Exp $
proc_doc util_translate_tcl_glob_to_sql_like_pattern {glob_pattern} "Attempts to translate a Tcl glob pattern to a SQL LIKE pattern.  Only works if the GLOB is just alphanumerics plus * or ?.  Returns empty string if it can't succeed." {
    set regexps [list {\]} {\[} {\\}]
    foreach regexp $regexps {
	if [regexp $regexp $glob_pattern] {
	    return ""
	}
    }
    regsub -all {\*} $glob_pattern "%" glob_pattern
    regsub -all {\?} $glob_pattern "_" glob_pattern
    return $glob_pattern
}

# apply-to-old-data.tcl
# by philg@mit.edu on 2/27/1999 

# this procedures takes a GLOB pattern and applies it to the old 
# data in referer_log

set_the_usual_form_variables

# glob_pattern, simulate_p (pointing into referer_log_glob_patterns)

if { [info exists simulate_p] && !$simulate_p } {
    # we're not simulating
    set title "Applying GLOB Pattern to referer_log"
    set working_headline "Applying"
    set db_conns [ns_db gethandle [philg_server_default_pool] 2]
    set db [lindex $db_conns 0]
    set db_sub [lindex $db_conns 1]
    set apply_option ""
} else {
    set title "Simulating the application of GLOB Pattern to referer_log"    
    set working_headline "Simulating"
    set db [ns_db gethandle]
    set apply_option "<p>
<center>
<form method=POST action=\"apply-to-old-data.tcl\">
[export_form_vars glob_pattern]
<input type=hidden name=simulate_p value=0>
<input type=submit value=\"Apply\">
</center>
"
}


ReturnHeaders

ns_write "[ad_admin_header $title]

<h2>$title</h2>

in the <a href=\"report.tcl\">referral tracking</a> of <a href=\"/admin/index.tcl\">[ad_system_name] administration</a>

<hr>

"


set selection [ns_db 1row $db "select * 
from referer_log_glob_patterns
where glob_pattern = '$QQglob_pattern'"]

set_variables_after_query


ns_write "
<ul>
<li>glob_pattern: \"$glob_pattern\"
<li>canonical_foreign_url: \"$canonical_foreign_url\"
<p>
<li>search_engine_name:  \"$search_engine_name\"
<li>search_engine_regexp: \"$search_engine_regexp\"
</ul>

<h3>$working_headline</h3>

"

set sql_like_pattern [util_translate_tcl_glob_to_sql_like_pattern $glob_pattern]

if ![empty_string_p $sql_like_pattern] {
    # we don't have to go through entire log
    set query "select rowid, local_url, foreign_url, entry_date, click_count, to_char(entry_date,'YYYY-MM-DD HH24:MI:SS') as entry_date_timestamp
from referer_log
where foreign_url <> '[DoubleApos $canonical_foreign_url]'
and foreign_url like '[DoubleApos $sql_like_pattern]'"
} else {
    set query "select rowid, local_url, foreign_url, entry_date, click_count, to_char(entry_date,'YYYY-MM-DD HH24:MI:SS') as entry_date_timestamp
from referer_log
where foreign_url <> '[DoubleApos $canonical_foreign_url]'"
}


ns_write "

We're going to run 

<blockquote>
<pre><code>
$query
</code></pre>
</blockquote>


If you applied this glob pattern to legacy data, here's what would
happen..

<p>

<ul>

"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if {[string match $glob_pattern $foreign_url]} {
	ns_write "<li>$entry_date: from $foreign_url to $local_url.\n"
	# reset the flag for code below
	set query_string ""
	if {![empty_string_p $search_engine_name] && [regexp $search_engine_regexp $foreign_url match encoded_query_string]} {
	    set query_string [ns_urldecode $encoded_query_string]
	    # remove the pluses
	    regsub -all {\+} $query_string { } query_string
	    ns_write "We think the query string was \"$query_string\"\n"
	}
    }
    if { [info exists simulate_p] && !$simulate_p } {
	# we're not simulating
	ns_db dml $db_sub "begin transaction"
	ns_write "<br>We're deleting this row from <code>referer_log</code>...\n"
	ns_db dml $db_sub "delete from referer_log where rowid = '[DoubleApos $rowid]'"
	ns_write "done.  We're going to increment the count for the canonical URL..."
	# let's now register the referral under the canonical URL
	set update_sql "update referer_log set click_count = click_count + 1
where local_url = '[DoubleApos $local_url]' 
and foreign_url = '[DoubleApos $canonical_foreign_url]'
and trunc(entry_date) = '$entry_date'"
        ns_db dml $db_sub $update_sql
        set n_rows [ns_ora resultrows $db_sub]
        if { $n_rows == 0 } {
	    # there wasn't already a row there
	    ns_write "done, but it didn't have any effect.  There wasn't already a row in the database.  So we're inserting one..."
	    set insert_sql "insert into referer_log (local_url, foreign_url, entry_date, click_count)
values
('[DoubleApos $local_url]', '[DoubleApos $canonical_foreign_url]', '$entry_date', 1)"
            ns_db dml $db_sub $insert_sql
	    ns_write "done."

        } else {
	    ns_write "done.  There was already a row in the database."
	}
	if {![empty_string_p $query_string] && ![empty_string_p $search_engine_name]} {
	    # we got a query string on this iteration
	    ns_write "  Inserting a row into query_strings... "
	    ns_db dml $db_sub "insert into query_strings 
(query_date, query_string, search_engine_name)
values
(to_date('$entry_date_timestamp','YYYY-MM-DD HH24:MI:SS'), '[DoubleApos $query_string]', '[DoubleApos $search_engine_name]')"
	    ns_write " done."
	}

	ns_db dml $db_sub "end transaction"
    }
    ns_write "\n\n<p>\n\n"
}

ns_write " 
</ul>

$apply_option

[ad_admin_footer]
"
