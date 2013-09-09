# /www/admin/manuals/manual-edit.tcl
ad_page_contract {
    Displays the properties of one manual

    @param manual_id the ID of the manual being edited

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id manual-edit.tcl,v 1.6.2.4 2000/07/21 03:57:34 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

page_validation {
    if { ![db_0or1row manual_info "
    select title,
    	   short_name,
    	   owner_id as curr_owner_id,
    	   author,
    	   copyright,
    	   version,
    	   scope,
    	   group_id as viewing_group_id,
    	   notify_p,
    	   active_p
    from   manuals
    where  manual_id = :manual_id"]} {

	error "An error occured looking up manual_id = $manual_id"
    }
}
 
# get the page and figure counts 

set number_of_pages [db_string num_pages "
select count(*)
from manual_sections
where manual_id = :manual_id"]

set number_of_figures [db_string num_figures "
select count(*)
from manual_figures
where manual_id = :manual_id"]


# get the editors for this manual

db_foreach manual_editors "
select   u.user_id,
         u.first_names||' '||u.last_name as editor,
         u.email as editor_email
from     user_group_map ugm, users u
where    ugm.group_id  in (select a.group_id
                           from administration_info a
                           where module    = 'manuals'
                           and   submodule = :manual_id )
and      u.user_id = ugm.user_id
order by u.last_name " {

    append editor_list  \
	    "<li><a href=/shared/community-member?user_id=$user_id>$editor</a> ($editor_email)\n" 

} if_no_rows {
    set editor_list "None"
}

set group_id [ad_administration_group_id manuals $manual_id]

# -----------------------------------------------------------------------------

doc_set_property title "Manuals: $title"
doc_set_property navbar [list [list "index.tcl" "Manuals"] $title]

doc_body_append "
<table>
<tr>
<td align=right>Editor Page:</td>
<td><a href=/manuals/admin/manual-view?manual_id=$manual_id>
            /manuals/admin/manual-view.tcl?manual_id=$manual_id</a></td>
</tr>

<tr>
<td align=right>User Page:</td>
<td><a href=/manuals/manual-view?manual_id=$manual_id>
            /manuals/manual-view.tcl?manual_id=$manual_id</a></td>
</tr>

<tr>
<td align=right>Number of Pages:</td>
<td>$number_of_pages</td>
</tr>

<tr>
<td align=right>Number of Figures:</td>
<td>$number_of_figures</td>
</tr>

</table>

<h4>Properties</h4>

<blockquote>

<form action=manual-edit-2 method=post>

[export_form_vars manual_id]

<table>

<tr>
 <th align=right>Title:</th>
 <td><input type=text size=60 name=title value=\"[philg_quote_double_quotes $title]\"></td>
</tr>

<tr>
 <th align=right>Short Name:</th>
 <td><input type=text size=30 name=short_name 
      value=\"[philg_quote_double_quotes $short_name]\"></td>
</tr>

<tr>
  <th align=right>Owner:</th>
  <td>[ad_db_select_widget -default $curr_owner_id \
	  owner_names "
    select u.last_name || ', ' || u.first_names full_name,
           u.user_id as owner_id
    from   users u, user_group_map ugm
    where  ugm.user_id     = u.user_id
    and    lower(ugm.role) = 'administrator'
    group by u.user_id, u.first_names, u.last_name
    order by u.last_name" owner_id]
  </td>
</tr>

[manual_radio_widget notify_p "Notify on Changes"]

<tr>
  <th align=right>Author(s):</th>
  <td><input type=text size=60 name=author value=\"[philg_quote_double_quotes $author]\"></td>
</tr>

<tr>
  <th align=right>Copyright Statement:</th>
  <td><input type=text size=60 name=copyright value=\"[philg_quote_double_quotes $copyright]\"></td>
</tr>

<tr>
  <th align=right>Version:</th>
  <td><input type=text size=60 name=version value=\"[philg_quote_double_quotes $version]\"></td>
</tr>

[manual_scope_widget $viewing_group_id]

[manual_radio_widget active_p "Active"]

<tr>
 <td></td>
 <td><input type=submit value=\"Update Properties\"></td>
</tr>

</table>
</form>
</blockquote>

<p>

<h4>Editors</h4>

<ul>

$editor_list

<p>

<li><a href=/admin/ug/group?group_id=$group_id>Add/Maintain Editors</a>
</ul>

<h4>Extreme Actions</h4>

<ul>

<li><a href=manual-delete?manual_id=$manual_id>Delete this manual</a>

</ul>

"










