# $Id: lump-into-about.tcl,v 3.0 2000/02/06 03:26:18 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables
   
# subcategory_1

ReturnHeaders

ns_write "[neighbor_header "Lumping $subcategory_1 Postings"] 

<h2>Lumping $subcategory_1 Postings</h2>

together by the about column in <a href=\"index.tcl\">[neighbor_system_name]</a>

<hr>

When users don't categorize things very well, e.g., spell \"KEH Photo\"
differently in two different postings, then you can use this page to
fix things up.

<p>

Pick what you want to be the canonical About value:  

<p>

<form action=lump-into-about-2.tcl method=post>
<input type=text name=lump_about size=30>

<input type=submit value=\"Submit\">

<ul>

"

set db [neighbor_db_gethandle]

set selection [ns_db select $db "select neighbor_to_neighbor_id, 
users.email as poster_email, one_line, posted, about, upper(about) as sort_key
from neighbor_to_neighbor, users
where domain = 'photo.net' and
primary_category = 'photographic' 
and subcategory_1 = '[DoubleApos $subcategory_1]'
and (expires > sysdate or expires is NULL)
and users.user_id = neighbor_to_neighbor.poster_user_id
order by sort_key, posted desc"]

set last_about ""
set first_pass 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $sort_key != $last_about } {
	if { $first_pass != 1 } {
	    # not first time through, separate
	    ns_write "<p>\n"
	}
	set first_pass 0
	set last_about $sort_key
    }
    if { $one_line == "" } {
	set anchor $about
    } else {
	set anchor "$about : $one_line"
    }
    ns_write "<li><table>
<tr>
<td>
<a href=\"../view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>
 (by $poster_email on $posted)
<td>
<input type=checkbox name=lump_ids value=\"$neighbor_to_neighbor_id\"> Pick
</tr>
</table>
"

}

ns_write "</ul>

</form>

<p>

Please contribute to making this a useful service by
<a href=\"post-new.tcl\">posting your own story</a>.

[neighbor_footer]
"
