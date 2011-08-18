# $Id: define-new-category.tcl,v 3.1 2000/03/10 23:58:22 curtisg Exp $
# we get here when user is placing ad

set_the_usual_form_variables

# domain_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set category_id [database_to_tcl_string $db "select ad_category_id_seq.nextval from dual"]

append html "[gc_header "Define New Category for $full_noun"]

<h2>Define a New Category</h2>

in <a href=\"domain-top.tcl?[export_url_vars domain_id]\">$full_noun</a>

<hr>

Category Name should be descriptive and plural, e.g., \"Camera Parts\"
or \"Professorships\".  Placement blurb is something to jog the users
minds when they are placing an ad.  For example, if the new category
were \"Automobiles, Sports\" you could have \"Remember to include
engine size, maximum speed, and number of dyed blondes obtained\".


<form method=post action=define-new-category-2.tcl>
[export_form_vars domain_id category_id]
<table>
<tr><th>Category Name<td><input type=text name=primary_category size=40></tr>
<tr><th>Placement Blurb<br>
<td><textarea name=ad_placement_blurb wrap=soft rows=6 cols=50>
Remember to include... 
</textarea>
</tr>
</table>
<p>
<center>
<input type=submit value=submit>
</center>
</form>

"

append html "

[gc_footer $maintainer_email]"

ns_return 200 text/html $html
