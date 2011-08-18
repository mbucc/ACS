#
# /portals/manage-portal.tcl
#
# GUI that facilitates page layout (USER VERSION)
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: manage-portal.tcl,v 3.2 2000/03/10 22:57:39 richardl Exp $
#

set db [ns_db gethandle]

# -------------------------------------
# get user info

set user_id [ad_verify_and_get_user_id]

set user_name test
set user_name [database_to_tcl_string $db "
	    select first_names||' '||last_name from users where user_id=$user_id"]
 					    
# Get generic display information
portal_display_info

# get number of existing pages +1
set max_page [database_to_tcl_string $db "select max(page_number)+1 from portal_pages
where     user_id = $user_id"]

if {[empty_string_p $max_page]} {
    set max_page 1
}

set total [database_to_tcl_string $db "select count(*) from portal_tables"]

set page_content "
<html>
<head>
<title>Personalize Page Layout</title>

<script src=manage-portal-js?[export_url_vars max_page group_id total]></script>
</head>
$body_tag $font_tag
<h2>[ad_parameter SystemName portals] Administration for $user_name</h2>
<form action=manage-portal-2 method=get name=theForm>
[export_form_vars user_id]
<input type=hidden name=\"left\" value=\"\" >
<input type=hidden name=\"right\" value=\"\">
<input type=hidden name=\"hiddennames\" value=\"\">
<table width=100% border=0 cellpadding=0 cellspacing=0><tr><td>This page enables you to manage current content.
</td><td valign=bottom align=right>Click here when completed: <input type=submit value=\" FINISHED \" onClick=\"return doSub();\">
</td></tr></table><p>"

set n_longest 30

set spaces ""

for {set i 0} {$i <=  $n_longest} {incr i} {
    append spaces "&nbsp;"
}

set x 0
set extra_options ""
while {$x <= $total} {
    if { $x == 0 } {
	append extra_options "<option value=\"null\">$spaces</option>\n"
    } else {
	append extra_options "<option value=\"null\">&nbsp;</option>\n"
    }
    incr x
}

for {set current_page 1} {$current_page <= $max_page} {incr current_page} {

    set sql_query "
    select    table_name, page_number, page_side, map.table_id, page_name
    from      portal_table_page_map map, portal_tables p_t, portal_pages p_p
    where     user_id = $user_id
    and       map.page_id = p_p.page_id
    and       map.table_id = p_t.table_id
    and       page_number = $current_page
    order by  page_side, sort_key"

    set selection [ns_db select $db $sql_query]

    set left_select ""
    set right_select ""
    set page_name ""

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	set table_name [string range [string toupper [ns_adp_parse -string $table_name]] 0 31]

	if {$page_side == "l"} {
	    append left_select "<option value=\"$table_id\">$table_name</option>\n"
	} else {
	    append right_select "<option value=\"$table_id\">$table_name</option>\n"
	}
    }
    regsub -all { } [string tolower $user_name] {-} lower_user_name

    if {$current_page != $max_page} {
	set right_link "<td align=right>(<a target=_new href=/portals/user$user_id-$current_page[ad_parameter PortalExtension portals .ptl]>current version</a>)</td>"
    } else {
	set right_link "<td align=right>(a new page if needed)</td>"
    }
	    
    append page_content "
	<table width=100% bgcolor=#0000 border=0 cellpadding=0 cellspacing=1><tr><td>
	    <table bgcolor=#cccccc cellspacing=1 cellpadding=4 width=100% border=0>
	       <tr>
	          <td colspan=2 bgcolor=#cccccc><table width=100% border=0 cellpadding=0 cellspacing=0><tr><td>Page #$current_page - Titled: <font face=arial,helvetica size=-1><input name=page_name$current_page type=text size=30 value=\"$page_name\"></td>$right_link</tr></table></td>
	       </tr>
	       <tr>
	       <td bgcolor=#dddddd valign=top align=center><table border=0 cellpadding=1 cellspacing=0>
	          <tr><td><table cellpadding=4>
	          <tr>
	             <td><a href=\"#\" onClick=\"return Delete('left',$current_page)\"><img src=pics/x width=18 height=15 border=0 alt=Delete></a></td>
	          </tr>
	       </table></td>
	             <td><font face=courier size=-1><select name=\"left$current_page\" size=6>$left_select $extra_options</select></td>
	             <td><table cellpadding=4>
	          <tr>
	             <td><a href=\"#\" onClick=\"return moveTable('up','left',$current_page)\"><img src=pics/up width=18 height=15 border=0 alt=\"Up\"></a></td>
	          </tr>
	          <tr>
	             <td><a href=\"#\" onClick=\"return slide('left',$current_page)\"><img src=pics/right width=18 height=15 border=0 alt=\"Right\" hspace=10></a></td>
	          </tr>
	          <tr>
	             <td><a href=\"#\" onClick=\"return moveTable('down','left',$current_page)\"><img src=pics/down width=18 height=15 border=0 alt=Down></a></td>
	          </tr>
	       </table></td>
	    </tr></table></td>
	        <td bgcolor=#dddddd valign=top align=center width=50%><table border=0 cellpadding=1 cellspacing=0>
	           <tr>
	              <td><table cellpadding=4>
	           <tr>
	              <td align=right><a href=\"#\" onClick=\"return moveTable('up','right',$current_page)\"><img src=pics/up width=18 height=15 border=0 alt=\"Up\"></a></td>
	           </tr>
	           <tr>
	              <td><a href=\"#\" onClick=\"return slide('right',$current_page)\"><img src=pics/left width=18 height=15 border=0 alt=\"Left\" hspace=10></a></td>
	           </tr>
	           <tr>
	              <td align=right><a href=\"#\" onClick=\"return moveTable('down','right',$current_page)\"><img src=pics/down alt=Down width=18 height=15 border=0></a></td>
	           </tr>
	        </table></td>
	        <td><font face=courier size=-1><select name=\"right$current_page\" size=6>$right_select $extra_options</select></td>
	        <td><table cellpadding=4>
	           <tr>
	              <td><a href=\"#\" onClick=\"return Delete('right',$current_page)\"><img src=pics/x width=18 height=15 border=0 alt=Delete></a></td>
	           </tr>
	        </table></td>
	    </tr>
	    </table></td>
	    </tr>
	    </table></td>
	    </tr>
	    </table><br>
        "
}

# a list of all tables in the portals you don't already have
set sql_query "
select   table_name, pt.table_id 
from     portal_tables pt
where    pt.table_id not in (select map.table_id from portal_table_page_map map, portal_pages pp
where pp.user_id=$user_id and map.page_id=pp.page_id)
order by table_name" 
set selection [ns_db select $db $sql_query]
    
append page_content "
	<table width=100% bgcolor=#0000 border=0 cellpadding=0 cellspacing=1><tr><td>
	    <table bgcolor=#cccccc cellspacing=1 cellpadding=4 width=100% border=0>
	       <tr>
	          <td bgcolor=#cccccc>Here are information tables that you don't currently use:</td>
               </tr>
               <tr><td width=100% bgcolor=#dddddd align=center><table><tr>
<td align=right valign=top><table cellpadding=4>
	           <tr>
	              <td><a href=\"#\" onClick=\"return addTable('left',$max_page)\"><img src=pics/up width=18 height=15 border=0 alt=\"Up\"></a></td>
	           </tr>
	        </table></td>
<td valign=top><font face=courier size=-1><select name=new size=5>"
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set table_name [string toupper [ns_adp_parse -string $table_name]]

    append page_content "<option value=$table_id>$table_name</option>\n "
}
append page_content "$extra_options</select></td>
<td align=left valign=top><table cellpadding=4>
	           <tr>
	              <td><a href=\"#\" onClick=\"return addTable('right',$max_page)\"><img src=pics/up width=18 height=15 border=0 alt=\"Up\"></a></td>
	           </tr>
	        </table></td></tr></table></center></td></tr></table></td></tr></table>
<p>

<table width=100% border=0 cellpadding=0 cellspacing=0><tr><td>
Key:<td valign=top align=right>Click here when completed: <input type=submit value=\" FINISHED \" onClick=\"return doSub();\">
</td></tr></table>
</form>

<ul>
<br><img src=pics/x width=18 height=15 border=0> - Delete selected item
<br><img src=pics/up width=18 height=15 border=0> - Move item up (to previous page if it is already at the top of the current page)
<br><img src=pics/right width=18 height=15 border=0> - Move item from the left side of the page to the right
<br><img src=pics/left width=18 height=15 border=0> - Move item from the right side of the page to the left
<br><img src=pics/down width=18 height=15 border=0> - Move item down (to next page if it is already at the bottom of the current page)"

ns_return 200 text/html $page_content















