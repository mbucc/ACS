# /www/admin/contest/update-domain.tcl
ad_page_contract {
    Updates contest info (from form on manage-domain.tcl).

    @param domain_id which contest this is

    @author mbryzek@arsdigita.com
    @cvs_id update-domain.tcl,v 3.3.2.5 2000/09/22 01:34:37 kevin Exp
} {
    domain_id:integer
}

set domain [db_string domain "select domain from contest_domains where domain_id = :domain_id"]

set form [ns_getform]

set sql_statement_and_bind_vars [util_prepare_update contest_domains domain_id $domain_id $form]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml contest_info_update $sql_statement -bind $bind_vars } errmsg] {
    # something went a bit wrong
    ad_return_error "Update Error" "Error while trying to update $domain.
Tried the following SQL:
	    
<blockquote>
<pre>
$sql_statement
</pre>
</blockquote>	

and got back the following:
	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>	
"
return
} 



doc_return  200 text/html "[ad_admin_header "Update of $domain complete"]
    
<h2>Update of $domain Complete</h2>
    
in the <a href=\"index\">contest system</a>

<hr>

Here was the SQL:
    
<blockquote>
<pre>
$sql_statement
</pre>
</blockquote>

<P>
        
You probably want to <a href=\"manage-domain?[export_url_vars domain_id]\">
return to the management page for $domain</a>.

[ad_contest_admin_footer]
"

	
