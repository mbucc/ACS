# /www/admin/referer/apply-to-old-data.tcl
#


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

ad_page_contract {
    apply-to-old-data.tcl
   
    this procedures takes a GLOB pattern and applies it to the old 
    data in referer_log
    @param  glob_pattern
    @param  simulate_p
    @cvs-id apply-to-old-data.tcl,v 3.3.2.6 2000/09/22 01:35:58 kevin Exp
    @author Philip Greenspun (philg@mit.edu) on 2/27/1999 
} {
    glob_pattern:notnull
    simulate_p:notnull
}


if { [info exists simulate_p] && !$simulate_p } {
    # we're not simulating
    set title "Applying GLOB Pattern to referer_log"
    set working_headline "Applying"
    set apply_option ""
} else {
    set title "Simulating the application of GLOB Pattern to referer_log"    
    set working_headline "Simulating"
    
    set apply_option "<p>
<center>
<form method=POST action=\"apply-to-old-data\">
[export_form_vars glob_pattern]
<input type=hidden name=simulate_p value=0>
<input type=submit value=\"Apply\">
</center>
"
}

set page_content "[ad_admin_header $title]

<h2>$title</h2>

in the <a href=\"\">referral tracking</a> of <a href=\"/admin/\">[ad_system_name] administration</a>

<hr>

"

db_1row referer_log_glob_patterns "select * 
from referer_log_glob_patterns
where glob_pattern = :glob_pattern"


append page_content "
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

append page_content "

We're going to run 

<blockquote>
<pre><code>
$query
</code></pre>
</blockquote>


<p>

<ul>

"


db_foreach referer_lob_pattern_list $query {
    if {[string match $glob_pattern $foreign_url]} {
	append page_content "<li>$entry_date: from $foreign_url to $local_url.\n"
	# reset the flag for code below
	set query_string ""
	if {![empty_string_p $search_engine_name] && [regexp $search_engine_regexp $foreign_url match encoded_query_string]} {
	    set query_string [ns_urldecode $encoded_query_string]
	    # remove the pluses
	    regsub -all {\+} $query_string { } query_string
	    append page_content "We think the query string was \"$query_string\"\n"
	}
    }
    if { [info exists simulate_p] && !$simulate_p } {
	# we're not simulating
	db_transaction {
	append page_content "<br>We're deleting this row from <code>referer_log</code>...\n"
	db_dml referer_delete "delete from referer_log where rowid = '[DoubleApos $rowid]'"
	append page_content "done.  We're going to increment the count for the canonical URL..."
	# let's now register the referral under the canonical URL
	set update_sql "update referer_log set click_count = click_count + 1
where local_url = '[DoubleApos $local_url]' 
and foreign_url = '[DoubleApos $canonical_foreign_url]'
and trunc(entry_date) = :entry_date"
        db_dml referer_update $update_sql
        set n_rows [db_resultrows]
        if { $n_rows == 0 } {
	    # there wasn't already a row there
	    append page_content "done, but it didn't have any effect.  There wasn't already a row in the database.  So we're inserting one..."
	    set insert_sql "insert into referer_log (local_url, foreign_url, entry_date, click_count)
values
('[DoubleApos $local_url]', '[DoubleApos $canonical_foreign_url]', :entry_date, 1)"
            db_dml referer_insert_2 $insert_sql
	    append page_content "done."

        } else {
	`    append page_content "done.  There was already a row in the database."
	}
	if {![empty_string_p $query_string] && ![empty_string_p $search_engine_name]} {
	    # we got a query string on this iteration
	    append page_content "  Inserting a row into query_strings... "
	    db_dml referer_insert_query_string "insert into query_strings 
(query_date, query_string, search_engine_name)
values
(to_date(:entry_date_timestamp,'YYYY-MM-DD HH24:MI:SS'), '[DoubleApos $query_string]', '[DoubleApos $search_engine_name]')"
	    append page_content " done."
	}

    }
    }
    append page_content "\n\n<p>\n\n"
}

append page_content " 
</ul>

$apply_option

[ad_admin_footer]
"


doc_return  200 text/html $page_content