# $Id: update-domain.tcl,v 3.1 2000/03/10 20:02:03 markd Exp $
set_the_usual_form_variables

# expects domain_id

set db [ns_db gethandle]

set domain [database_to_tcl_string $db "select domain from contest_domains where domain_id='$QQdomain_id'"]

set form [ns_conn form $conn]

set sql_statement [util_prepare_update $db contest_domains domain_id $QQdomain_id $form]

if [catch { ns_db dml $db $sql_statement } errmsg] {
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

ns_return 200 text/html "[ad_admin_header "Update of $domain complete"]
    
<h2>Update of $domain Complete</h2>
    
in the <a href=\"index.tcl\">contest system</a>

<hr>

Here was the SQL:
    
<blockquote>
<pre>
$sql_statement
</pre>
</blockquote>

<P>
        
You probably want to <a href=\"manage-domain.tcl?[export_url_vars domain_id]\">
return to the management page for $domain</a>.

[ad_contest_admin_footer]
"

	
