# $Id: domain-add-2.tcl,v 3.1 2000/03/11 00:45:11 curtisg Exp $
set_the_usual_form_variables

# domain_id, full_noun, domain, user_id_from_search, 
# first_names_from_search, last_name_from_search, email_from_search


# user error checking

set exception_text ""
set exception_count 0

if { ![info exists full_noun] || [empty_string_p $full_noun] } {
    incr exception_count
    append exception_text "<li>Please enter a name for this domain."
}

if { ![info exists domain] || [empty_string_p $domain] } {
    incr exception_count
    append exception_text "<li>Please enter a short key."
}


if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(domain) from ad_domains where domain = '$QQdomain'"] > 0 } {
    ad_return_error "$domain already exists" "A domain with a short key \"$domain\" already exists in [ad_system_name].  The short key must be unique. Perhaps there is a conflict with an existing domain or you double clicked and submitted the form twice."
    return
}  

ns_db dml $db "begin transaction"

ns_db dml $db "insert into ad_domains 
(domain_id, primary_maintainer_id, domain, full_noun) 
values
($domain_id, $user_id_from_search, '$QQdomain', '$QQfull_noun')"

# create an administration group for users authorized to
# delete and edit ads
ns_db dml $db "declare begin administration_group_add('Admin group for the $QQdomain classifieds', short_name_from_group_name('Admin group for the $QQdomain classifieds'), 'gc', '$QQdomain', 'f', '/gc/admin/domain-top.tcl?domain=[ns_urlencode $domain]'); end;"

ns_db dml $db "end transaction"

append html "[ad_admin_header "Add a domain, Step 2"]

<h2>Add domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] "Add domain, Step 2"]


<hr>

<form method=post action=domain-add-3.tcl>
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
to use the fields and annotation you desire.<br>

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
Do you want to allow \"Wanted to by\" adds?  
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
[export_form_vars domain_id domain]
</form>
[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
