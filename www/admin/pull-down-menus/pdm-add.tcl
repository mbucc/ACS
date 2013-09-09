# /www/admin/pull-down-menus/pdm-add.tcl
ad_page_contract {

  Page to add a new pdm to the system.

  @author aure@caltech.edu
  @creation-date Feb 2000
  @cvs-id pdm-add.tcl,v 1.2.8.5 2001/01/11 23:36:29 khy Exp

} {

}


# get the next available menu_id to pass to the processing form
# for double click protection

set menu_id [db_string next_menu_id "select pdm_menu_id_sequence.nextval from dual"]

db_release_unused_handles

set title "Create New Pull-Down Menu"

doc_return  200 text/html "
[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "" "Pull-Down Menu"] "Create New"]

<hr>

<form method=post action=pdm-add-2>
[export_form_vars -sign menu_id]

<table>
 <tr>
  <th align=right>Name:</th>
  <td colspan=2><input type=text name=menu_key size=20></td>
 </tr>
 <tr>
  <th align=right>Make this the default menu:</th>
  <td colspan=2><input type=radio name=default_p value=f checked>No &nbsp; &nbsp;
      <input type=radio name=default_p value=t>Yes </td>
 </tr>
 <tr>
  <th align=right>Orientation:</th>
  <td colspan=2><input type=radio name=orientation value=horizontal checked>Horizonal &nbsp; &nbsp;
      <input type=radio name=orientation value=vertical>Vertical (a bit crude currently)</td>
 </tr>
 <tr>
  <th align=right>Distance from top of display area:</th>
  <td colspan=2><input type=text name=y_offset size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Distance from left of display area:</th>
  <td colspan=2><input type=text name=x_offset size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Element Height:</th>
  <td colspan=2><input type=text name=element_height size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Element Width:</th>
  <td colspan=2><input type=text name=element_width size=6> pixels</td>
 </tr>
 <tr>
  <td colspan=2 colspan=2>All of the following are optional:</td>
 </tr>
 <tr>
  <th valign=top align=right> &nbsp; <br> Main Menu Font Style:</th>
  <td colspan=2><textarea name=main_menu_font_style rows=6 cols=40></textarea></td>
 </tr>
 <tr>
  <th valign=top align=right> &nbsp; <br> Sub Menu Font Style:</th>
  <td colspan=2><textarea name=sub_menu_font_style rows=6 cols=40></textarea></td>
 </tr>
 <tr>
  <th valign=top align=right> &nbsp; <br> Second Level Font Style:</th>
  <td colspan=2><textarea name=sub_sub_menu_font_style rows=6 cols=40></textarea></td>
 </tr>
<tr>
<td></td>
<th valign=bottom>Background Image URL</th>
<th colspan=2 align=left>Background Color</th></tr>
 <tr>
  <th align=right>Main Menu Default:</th>
  <td><input type=text name=main_menu_bg_img_url size=30></td>
  <td><input type=text name=main_menu_bg_color size=12 maxlength=12></td>
  <td>e.g. #ffffff</td>
 </tr>
 <tr>
  <th align=right>Main Menu Highlight:</th>
  <td><input type=text name=main_menu_hl_img_url size=30></td>
  <td><input type=text name=main_menu_hl_color size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Sub Menu Default:</th>
  <td><input type=text name=sub_menu_bg_img_url size=30></td>
  <td><input type=text name=sub_menu_bg_color size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Sub Menu Highlight:</th>
  <td><input type=text name=sub_menu_hl_img_url size=30></td>
  <td><input type=text name=sub_menu_hl_color size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Second Level Menu Default:</th>
  <td><input type=text name=sub_sub_menu_bg_img_url size=30></td>
  <td><input type=text name=sub_sub_menu_bg_color size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Second Level Menu Highlight:</th>
  <td><input type=text name=sub_sub_menu_hl_img_url size=30></td>
  <td><input type=text name=sub_sub_menu_hl_color size=12 maxlength=12></td>
 </tr>
 <tr>
  <td></td>
  <td><input type=submit value=Submit></td>
 </tr>

</table>

</form>

[ad_admin_footer]
"
