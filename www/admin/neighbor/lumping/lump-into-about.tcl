#admin/neighbor/lup-into-about.tcl
ad_page_contract {
    not sure if this gets used, 
    but its for lumping postings that are not categorized well

    @csv-id: lump-into-about.tcl,v 3.1.6.2 2000/09/22 01:35:43 kevin Exp
    
} {
    subcategory_1:sql_identifier
}

# lump-into-about.tcl,v 3.1.6.2 2000/09/22 01:35:43 kevin Exp

set doc_body "[neighbor_header "Lumping $subcategory_1 Postings"] 

<h2>Lumping $subcategory_1 Postings</h2>

together by the about column in <a href=\"index\">[neighbor_system_name]</a>

<hr>

When users don't categorize things very well, e.g., spell \"KEH Photo\"
differently in two different postings, then you can use this page to
fix things up.

<p>

Pick what you want to be the canonical About value:  

<p>

<form action=lump-into-about-2 method=post>
<input type=text name=lump_about size=30>

<input type=submit value=\"Submit\">

<ul>

"


set last_about ""
set first_pass 1

db_foreach neighbor_lumping_sql "select neighbor_to_neighbor_id, 
users.email as poster_email, one_line, posted, about, upper(about) as sort_key
from neighbor_to_neighbor, users
where domain = 'photo.net' and
primary_category = 'photographic' 
and subcategory_1 = ':$subcategory_1'
and (expires > sysdate or expires is NULL)
and users.user_id = neighbor_to_neighbor.poster_user_id
order by sort_key, posted desc" {

    if { $sort_key != $last_about } {
	if { $first_pass != 1 } {
	    # not first time through, separate
	    append doc_body "<p>\n"
	}
	set first_pass 0
	set last_about $sort_key
    }
    if { $one_line == "" } {
	set anchor $about
    } else {
	set anchor "$about : $one_line"
    }
    append doc_body "<li><table>
    <tr>
    <td>
    <a href=\"../view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>
    (by $poster_email on $posted)
    <td>
<input type=checkbox name=lump_ids value=\"$neighbor_to_neighbor_id\"> Pick
</tr>
</table>
"

}

append doc_body "</ul>

</form>

<p>

Please contribute to making this a useful service by
<a href=\"post-new\">posting your own story</a>.

[neighbor_footer]
"
db_release_unused_handles

doc_return 200 text/html $doc_body