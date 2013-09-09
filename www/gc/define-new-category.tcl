# /www/gc/define-new-category.tcl
ad_page_contract {
    Define a new category with an accompanying blurb to jog the users
    minds when they are placing an ad under that category.
    
    @author xxx
    @date unknown
    @cvs-id define-new-category.tcl,v 3.3.2.4 2000/09/22 01:37:51 kevin Exp
} {
    domain_id:integer
}

db_1row gc_domain_info_query [gc_query_for_domain_info :domain_id] -bind [ad_tcl_vars_to_ns_set domain_id]

set category_id [db_string next_category_id_in_sequence_query "select ad_category_id_seq.nextval from dual"]

set html "[gc_header "Define New Category for $full_noun"]

<h2>Define a New Category</h2>

in <a href=\"domain-top?[export_url_vars domain_id]\">$full_noun</a>

<hr>

Category Name should be descriptive and plural, e.g., \"Camera Parts\"
or \"Professorships\".  Placement blurb is something to jog the users
minds when they are placing an ad.  For example, if the new category
were \"Automobiles, Sports\" you could have \"Remember to include
engine size, maximum speed, and number of dyed blondes obtained\".

<form method=post action=define-new-category-2>
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



doc_return  200 text/html $html
