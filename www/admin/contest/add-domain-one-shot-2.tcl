set_the_usual_form_variables

#  ad_page_contract {
#      @cvs-id add-domain-one-shot-2.tcl,v 3.4.2.5 2000/09/22 01:34:36 kevin Exp
#  } {
#      domain
#      home_url
#      pretty_name
#      maintainer
#      start_date
#      end_date
#  }

set_form_variables 0

set domain_id [db_string domain_id_get "select contest_domain_id_sequence.nextval from dual"]

set exception_text ""
set exception_count 0

ns_dbformvalue [ns_conn form] start_date date start_date
ns_dbformvalue [ns_conn form] end_date date end_date
ns_set delkey [ns_conn form] "start_date.month"
ns_set delkey [ns_conn form] "start_date.year"
ns_set delkey [ns_conn form] "start_date.day"
ns_set delkey [ns_conn form] "end_date.month"
ns_set delkey [ns_conn form] "end_date.year"
ns_set delkey [ns_conn form] "end_date.day"
ns_set put [ns_conn form] start_date $start_date
ns_set put [ns_conn form] end_date $end_date

if { [info exists domain] && $domain != "" && [regexp {[^a-zA-Z0-9_]} $domain] } {
    append exception_text "<li>You can't have spaces, dashes, slashes, quotes, or colons in a domain name.  It has to be just alphanumerics and underscores"
    incr exception_count
}

if { ![info exists home_url] || $home_url == "" } {
    append exception_text "<li>You didn't enter a contest home URL.  It doesn't make any sense to have a contest that isn't associated with any page."
    incr exception_count
}

if { ![info exists pretty_name] || $pretty_name == "" } {
    append exception_text "<li>The pretty name was blank.  We need this for the user interface."
    incr exception_count
}

if { ![info exists maintainer] || [empty_string_p $maintainer] } {
    append exception_text "<li>We didn't get a maintainer user id.  This is probably a bug in our software."
    incr exception_count

}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# no obvious problems with the input



set n_already [db_string num_contests "select count(*) from contest_domains where domain=:domain" -bind [ad_tcl_vars_to_ns_set domain]]

if { $n_already > 0 } {
    # there already is a contest with this ID

    db_1row contest_get "select unique * from contest_domains where domain=:domain" -bind [ad_tcl_vars_to_ns_set domain]
    doc_return  200 text/html "[ad_admin_header "$domain"]

<h2>$domain is already in use</h2>

for a contest from <a href=\"$home_url\">$home_url</a>

<hr>

So you should back up and choose another domain for the contest
you have in mind, or if what you really wanted to do is manage
the $pretty_name, then <a
href=\"manage-domain.tcl?[export_url_vars domain_id]\">go
for it</a>

</ul>

[ad_contest_admin_footer]
"
    return
}

# everything was normal

set entrants_table_name "contest_entrants_$domain_id"
# add it to the form ns_set 
ns_set put [ns_conn form] voting_p t
ns_set put [ns_conn form] domain_id $domain_id
ns_set put [ns_conn form] entrants_table_name $entrants_table_name

set meta_table_insert_and_bind_vars [util_prepare_insert contest_domains [ns_conn form]]
set meta_table_insert [lindex $meta_table_insert_and_bind_vars 0]
set bind_vars [lindex $meta_table_insert_and_bind_vars 1]

set entrants_table_ddl "create table $entrants_table_name (
	entry_date	date not null,
	user_id		not null references users)"

if { [catch { 
    db_dml meta_table_insert $meta_table_insert -bind $bind_vars
    db_dml table_create $entrants_table_ddl
            } errmsg] } {  
	ad_return_error "Error trying to update the database." "Here was the bad news from the database:

<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" } else {
    ReturnHeaders
    ns_write "[ad_admin_header "Domain $domain_id added"]

<h2>Domain $domain_id added</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] "New Contest"]

<hr>

In order to make this work for users, what you must do one of the
following:

<ul>

<li>add a link to the generated entry form:

<blockquote><code>
&lt;a href=\"/contest/entry-form.tcl?[export_url_vars domain_id]\"&gt;enter our contest&lt;/a&gt;
</blockquote></code>

<h4>or</h4>

<li>create a static page on the site that contains all the proper
HTML variables.  The target for the form should be 
<code>/contest/process-entry.tcl</code>.
You will need a hidden variable
<blockquote><code>
&lt;input type=hidden name=domain_id value=\"$domain_id\"&gt;
</blockquote></code>

<p>

If you want to collect more than just which user entered, e.g., the
answer to a question, you need to use 
 <a
href=\"manage-domain.tcl?[export_url_vars domain_id]\">the management page for this contest</a>.

</ul>

[ad_contest_admin_footer]"

}
