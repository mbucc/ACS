# $Id: category-edit.tcl,v 3.1.2.2 2000/03/15 05:18:15 curtisg Exp $
set_the_usual_form_variables

# domain_id, primary_category

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select ac.*, ad.domain
from ad_categories ac, ad_domains ad
where ac.domain_id = $domain_id
and ad.domain_id = ac.domain_id
and primary_category = '$QQprimary_category'"]
set_variables_after_query

append html "[ad_admin_header "Edit $primary_category"]

<h2>Edit $primary_category</h2>

in the <a href=\"domain-top.tcl?domain_id=$domain_id\">$domain classifieds</a>

<hr>

<form method=post action=category-edit-2.tcl>
<input type=hidden name=domain_id value=\"$domain_id\">
<input name=old_primary_category type=hidden value=\"[philg_quote_double_quotes $primary_category]\">

Category name: <input name=primary_category type=text size=50 value=\"[philg_quote_double_quotes $primary_category]\"><p>
Annotation for the ad placement page:<br>
<textarea cols=60 rows=6 wrap=soft type=text name=ad_placement_blurb>[philg_quote_double_quotes $ad_placement_blurb]</textarea>
<center>
<input type=submit name=submit_type value=\"Edit\">
</center>
<br>
<br>


[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
