# admin/pdm/pdm-edit.tcl
#
# Author: aure@caltech.edu, Feb 2000
# 
# Page to add a new pdm to the system
#
# $Id: pdm-edit.tcl,v 1.1.2.1 2000/03/16 05:33:10 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {menu_id}

set db [ns_db gethandle]

# get the next available menu_id to pass to the processing form
# for double click protection

set selection [ns_db 0or1row $db "
    select *
    from pdm_menus
    where menu_id = $menu_id"]
set_variables_after_query

ns_db releasehandle $db

if {$default_p == "t"} {
    set default_question [export_form_vars default_p]
} else {
    set default_question "
    <tr>
    <th align=right>Make this the default menu:</th>
    <td colpan=2><input type=radio name=default_p value=f checked>No &nbsp; &nbsp;
    <input type=radio name=default_p value=t>Yes </td>
    </tr>"
}

if {$orientation == "horizontal"} {
    set h_checked "checked"
    set v_checked ""
} else {
    set h_checked ""
    set v_checked "checked"
}

set title "Edit Pull-Down Menu: $menu_key"

ns_return 200 text/html "
[ad_header_with_extra_stuff $title [ad_pdm $menu_key 5 5] [ad_pdm_spacer $menu_key]]

<h2>$title</h2>

[ad_admin_context_bar [list "" "Pull-Down Menu"] [list "items?menu_id=$menu_id" $menu_key] "Edit Parameters"]

<hr>

<form method=post action=pdm-edit-2>
[export_form_vars menu_id]

<table>
 <tr>
  <th align=right>Name:</th>
  <td colspan=2><input type=text name=menu_key value=\"$menu_key\" size=20></td>
 </tr>

 $default_question

 <tr>
  <th align=right>Orientation:</th>
  <td colspan=2><input type=radio name=orientation value=horizontal $h_checked>Horizonal &nbsp; &nbsp;
      <input type=radio name=orientation value=vertical $v_checked>Vertical (a bit crude currently)</td>
 </tr>
 <tr>
  <th align=right>Distance from top of display area:</th>
  <td colspan=2><input type=text name=y_offset value=$y_offset size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Distance from left of display area:</th>
  <td colspan=2><input type=text name=x_offset value=$x_offset size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Element Height:</th>
  <td colspan=2><input type=text name=element_height value=$element_height size=6> pixels</td>
 </tr>
 <tr>
  <th align=right>Element Width:</th>
  <td colspan=2><input type=text name=element_width value=$element_width size=6> pixels</td>
 </tr>
 <tr>
  <td colspan=3> All of the following are optional:
 </tr>
  <tr>
  <th valign=top align=right> &nbsp; <br> Main Menu Font Style:</th>
  <td colspan=2><textarea name=main_menu_font_style rows=6 cols=40>$main_menu_font_style</textarea></td>
 </tr>
 <tr>
  <th valign=top align=right> &nbsp; <br> Sub Menu Font Style:</th>
  <td colspan=2><textarea name=sub_menu_font_style rows=6 cols=40>$sub_menu_font_style</textarea></td>
 </tr>
 <tr>
  <th valign=top align=right> &nbsp; <br> Second Level Font Style:</th>
  <td colspan=2><textarea name=sub_sub_menu_font_style rows=6 cols=40>$sub_sub_menu_font_style</textarea></td>
 </tr>
<tr>
<td></td>
<th valign=bottom>Background Image URL</th>
<th align=left colspan=2>Background Color</th></tr>
 <tr>
  <th align=right>Main Menu Default:</th>
  <td><input type=text name=main_menu_bg_img_url value=\"[philg_quote_double_quotes $main_menu_bg_img_url]\" size=30></td>
  <td><input type=text name=main_menu_bg_color value=\"[philg_quote_double_quotes $main_menu_bg_color]\" size=12 maxlength=12></td>
  <td>e.g #ffffff</td>
 </tr>
 <tr>
  <th align=right>Main Menu Highlight:</th>
  <td><input type=text name=main_menu_hl_img_url value=\"[philg_quote_double_quotes $main_menu_hl_img_url]\" size=30></td>
  <td><input type=text name=main_menu_hl_color value=\"[philg_quote_double_quotes $main_menu_hl_color]\" size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Sub Menu Default:</th>
  <td><input type=text name=sub_menu_bg_img_url value=\"[philg_quote_double_quotes $sub_menu_bg_img_url]\" size=30></td>
  <td><input type=text name=sub_menu_bg_color value=\"[philg_quote_double_quotes $sub_menu_bg_color]\" size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Sub Menu Highlight:</th>
  <td><input type=text name=sub_menu_hl_img_url value=\"[philg_quote_double_quotes $sub_menu_hl_img_url]\" size=30></td>
  <td><input type=text name=sub_menu_hl_color value=\"[philg_quote_double_quotes $sub_menu_hl_color]\" size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Second Level Menu Default:</th>
  <td><input type=text name=sub_sub_menu_bg_img_url value=\"[philg_quote_double_quotes $sub_sub_menu_bg_img_url]\" size=30></td>
  <td><input type=text name=sub_sub_menu_bg_color value=\"[philg_quote_double_quotes $sub_sub_menu_bg_color]\" size=12 maxlength=12></td>
 </tr>
 <tr>
  <th align=right>Second Level Menu Highlight:</th>
  <td><input type=text name=sub_sub_menu_hl_img_url value=\"[philg_quote_double_quotes $sub_sub_menu_hl_img_url]\" size=30></td>
  <td><input type=text name=sub_sub_menu_hl_color value=\"[philg_quote_double_quotes $sub_sub_menu_hl_color]\" size=12 maxlength=12></td>
 </tr>
 <tr>
  <td></td>
  <td colspan=2><input type=submit value=\"Update Parameters\"></td>
 </tr>

</table>
</td></tr></table>
</form>

[ad_admin_footer]"



