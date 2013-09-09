# /www/admin/manual/manual-add.tcl
ad_page_contract {
    Page to add a new manual to the system.

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id manual-add.tcl,v 1.6.2.4 2001/01/11 17:40:35 khy Exp
} {}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

# get the next available manual id to pass to the processing form

set next_manual_id [db_string next_manual_id "
select manual_id_sequence.nextval from dual"]

# -----------------------------------------------------------------------------

doc_set_property title "Create a Manual"
doc_set_property navbar [list [list index.tcl "Manuals"] "Create a Manual"]

doc_body_append "
<form action=manual-add-2 method=post>
[export_form_vars -sign next_manual_id]

<table>
 <tr>
  <th align=right>Title:</th>
  <td><input type=text name=title size=60></td>
 </tr>
 <tr>
  <th align=right>Short Name:</th>
  <td><input type=text name=short_name size=30 maxlength=100>
  </td>
 </tr>
 
 <tr>
   <th align=right>Owner:</th>
   <td>[ad_db_select_widget -option_list {{{} {-- please select --}}} \
	   user_names "
     select u.last_name || ', ' || u.first_names full_name,
            u.user_id as owner_id
     from   users u, user_group_map ugm
     where  ugm.user_id     = u.user_id
     and    lower(ugm.role) = 'administrator'
     group by u.user_id, u.first_names, u.last_name
     order by u.last_name" owner_id]
   </td>
 </tr>

 <tr>
  <th align=right>Notify on Changes:</th>
  <td><input type=radio name=notify_p value=t checked>Yes
      <input type=radio name=notify_p value=f>No</td>
 </tr>

 <tr>
  <th align=right>Author(s):</th>
  <td><input type=text size=60 name=author></td>
 </tr>

 <tr>
  <th align=right>Copyright:</th>
  <td><input type=text size=60 name=copyright></td>
 </tr>

 <tr>
  <th align=right>Version:</th>
  <td><input type=text size=60 name=version></td>
 </tr>

 [manual_scope_widget]

 <tr>
  <th align=right>Activate Now:</th>
  <td><input type=radio name=active_p value=t>Yes
      <input type=radio name=active_p value=f checked>No</td>
 </tr>

 <tr>
  <td></td>
  <td><input type=submit value=Submit></td>
 </tr>

</table>

</form>

"









