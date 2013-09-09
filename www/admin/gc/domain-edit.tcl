# /www/admin/gc/domain-edit.tcl
ad_page_contract {
    Lets the site administrator edit a domain.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs_id domain-edit.tcl,v 3.4.2.5 2000/09/22 01:35:22 kevin Exp
} {
    domain_id:integer
}


set column_list [list domain full_noun blurb blurb_bottom insert_form_fragments default_expiration_days wtb_common_p auction_p geocentric_p]

db_1row domain_info "select [join $column_list ", "] from ad_domains where domain_id = :domain_id"

# this has to be done because database API doesn't yet create ns_sets,
# but bt_mergepiece requires them

set selection [ns_set new]

foreach column $column_list {
    ns_set put $selection $column [set $column]
}

set page_contents "[ad_admin_header "Edit $domain parameters"]

<h2>Edit $domain parameters</h2>

in the <a href=\"index\"> classifieds</a>

<hr>

<form method=post action=domain-edit-2>
<H3>Identity</H3>
Full domain name: <input type=text name=full_noun value=\"$full_noun\"><br>
Pick a short key : <input type=text name=domain value=\"$domain\"><br>
<H3>User Interface</H3>
Annotation for the top of the domain page:<br>
<textarea cols=60 rows=6 wrap=soft type=text name=blurb>[ns_quotehtml $blurb]</textarea>
<p>
Annotation for the bottom of the domain page: <br>
<textarea cols=60 rows=6 wrap=soft type=text name=blurb_bottom>[ns_quotehtml $blurb_bottom]</textarea><br>
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
<textarea cols=60 rows=6 wrap=soft type=text name=insert_form_fragments>[ns_quotehtml $insert_form_fragments]</textarea>
<table>
<tr>
<td>
Default expiration days:
</td><td> 
<input type=text name=default_expiration_days size=3 value=\"$default_expiration_days\">
</td></tr>
<tr><td>
Do you want to allow \"Wanted to by\" ads?  
</td><td>"

set html_form "<input type=radio name=wtb_common_p value=\"t\">Yes
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
<input type=radio name=geocentric_p value=\"f\">No"

append page_contents "[bt_mergepiece $html_form $selection]
</td></tr>
</table>
<p>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars domain_id]
</form>
[ad_admin_footer]
"


doc_return  200 text/html $page_contents
