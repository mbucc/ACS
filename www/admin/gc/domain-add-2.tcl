# /www/admin/gc/domain-add-2.tcl

ad_page_contract {
    Second form for adding a domain, once an administrator has been chosen.

    @author xxx
    @creation-date unknown
    @cvs-id domain-add-2.tcl,v 3.3.2.13 2001/01/10 18:54:17 khy Exp
} {
    full_noun:notnull
    domain:notnull
    user_id_from_search:naturalnum,notnull
    first_names_from_search
    last_name_from_search
    email_from_search
} -errors {
    full_noun:notnull {Please enter a name for this domain.}
    domain:notnull {Please enter a short key.}
}

if { [db_string domain_exists_p "
select count(domain) from ad_domains where domain = :domain"] > 0 } {
    ad_return_error "$domain already exists" "A domain with a short key \"$domain\" already exists in [ad_system_name].  The short key must be unique. Perhaps there is a conflict with an existing domain or you double clicked and submitted the form twice."
    return
}

db_transaction {

    set next_id [db_string gc_admin_domain_add_2_get_id "
    select ad_domain_id_seq.nextval from dual"]

    set domain_id $next_id

    db_dml domain_add_dml "
    insert into ad_domains 
    (domain_id, primary_maintainer_id, domain, full_noun) 
    values
    (:next_id, :user_id_from_search, :domain , :full_noun)"

    # create an administration group for users authorized to
    # delete and edit ads

    ad_administration_group_add \
	    "Admin group for $domain classifieds" "gc" $domain \
	    "/gc/admin/domain-top.tcl?domain_id=[ns_urlencode $next_id]" 

    ad_administration_group_user_add $user_id_from_search administrator \
	    gc $domain

}  on_error {
    db_release_unused_handles
    ad_return_error "Error" "An error occurred while adding your domain: 
    <blockquote>$errmsg</blockquote>"
}

set html "[ad_admin_header "Add a domain, Step 2"]

<h2>Add domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] "Add domain, Step 2"]

<hr>

<form method=post action=domain-add-3>
<H3>User Interface</H3>
Annotation for the top of the domain page:<br>
<textarea cols=60 rows=6 wrap=soft type=text name=blurb></textarea>
<p>
Annotation for the bottom of the domain page: <br>
<textarea cols=60 rows=6 wrap=soft type=text name=blurb_bottom></textarea><br>
<H3>Ad Parameters</H3>
By default, a full ad and a short description will be collected for all ads.  To include more fields, write the form fragment to collect the ad data you desire.  This fragment will be place inside a 2 column table.
<br>
Valid fields:
<table>
<tr><th align=left>Name</th><th align=left>Properties</th></tr>
<tr><td>manufacturer</td><td>Maxlength 50</td></tr>
<tr><td>model</td><td>Maxlength 50</td></tr>
<tr><td>item_size</td><td>Maxlength 100</td></tr>
<tr><td>color</td><td>Maxlength 50</td></tr>
<tr><td>us_citizen_p</td><td>\"t\" or \"f\"</td></tr>
</table>
<br>
The default below is a sample of a form fragment
that incorporates all the above fields.  Modify this
to use the fields and annotation you dpesire.<br>

<textarea cols=60 rows=6 wrap=soft type=text name=insert_form_fragments>
<tr><th align=left>Manufacturer</th><td><input type=text name=manufacturer maxlength=50></td></tr>
<tr><th align=left>Model</th><td><input type=text name=model maxlength=50></td></tr>
<tr><th align=left>Item Size</th><td><input type=text name=item_size maxlength=100></td></tr> 
<tr><th align=left>Color</th><td><input type=text name=color maxlength=50></td></tr>
<tr><th align=left>US  Citizenship required</th><td>Yes<input type=radio name=us_citizen_p value=\"t\">
No<input type=radio name=us_citizen_p value=\"f\"></td></tr>
</textarea>

<table>
<tr>
<td>
Default expiration days:
</td><td> 
<input type=text name=default_expiration_days size=3 value=30>
</td></tr>
<tr><td>
Do you want to allow \"Wanted to buy\" adds?  
</td><td>
<input type=radio name=wtb_common_p value=\"t\">Yes
<input type=radio name=wtb_common_p value=\"f\">No
</td></tr>
<tr><td>
Do you wish to have auctions on this site?  
</td><td>
<input type=radio name=auction_p value=\"t\">Yes
<input type=radio name=auction_p value=\"f\">No
</td></tr>
<tr><td>
Are your ads based on geography?
</td><td>
<input type=radio name=geocentric_p value=\"t\">Yes
<input type=radio name=geocentric_p value=\"f\">No
</td></tr>
</table>
<p>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars -sign domain_id]
[export_form_vars domain]
</form>
[ad_admin_footer]
"


doc_return  200 text/html $html
