# $Id: index.tcl,v 3.3.2.1 2000/03/17 08:23:05 mbryzek Exp $
# File: /www/intranet/partners/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Lists all partners with dimensional sliders
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# optional: type_id

if { ![exists_and_not_null order_by] } {
    set order_by "Partner"
}
if { ![exists_and_not_null type_id] } {
    set type_id 0
}
if { ![exists_and_not_null status_id] } {
    set status_id 0
}
if { ![exists_and_not_null mine_p] } {
    set mine_p "t"
}
set view_types [list "t" "Mine" "f" "All"]

# status_types will be a list of pairs of (partner_type_id, partner_status)
set partner_types [ad_partner_memoize_list_from_db \
	"select partner_type_id, partner_type
           from im_partner_types
          order by display_order, lower(partner_type)" [list partner_type_id partner_type]]
lappend partner_types 0 All


# status_types will be a list of pairs of (partner_status_id, partner_status)
set status_types [ad_partner_memoize_list_from_db \
	"select partner_status_id, partner_status
           from im_partner_status
          order by display_order, lower(partner_status)" [list partner_status_id partner_status]]
lappend status_types 0 All


# Now let's generate the sql query
set criteria [list]

if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.partner_type_id=$type_id"
}

if { ![empty_string_p $status_id] && $status_id != 0 } {
    lappend criteria "p.partner_status_id=$status_id"
}

set extra_tables [list]
if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( $user_id, g.group_id ) = 't'"
}

set order_by_clause ""
switch $order_by {
    "Partner" { set order_by_clause "order by upper(group_name)" }
    "Type" { set order_by_clause "order by upper(partner_type), upper(group_name)" }
    "Status" { set order_by_clause "order by upper(partner_status), upper(group_name)" }
    "URL" { set order_by_clause "order by upper(url), upper(group_name)" }
    "Note" { set order_by_clause "order by upper(note), upper(group_name)" }
}

set extra_table ""
if { [llength $extra_tables] > 0 } {
    set extra_table ", [join $extra_tables ","]"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set page_title "Partners"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] $page_title]

set db [ns_db gethandle]
set selection [ns_db select $db \
	"select p.*, g.group_name, t.partner_type, s.partner_status
           from user_groups g, im_partners p, im_partner_types t, im_partner_status s$extra_table
          where p.group_id = g.group_id
            and p.partner_type_id=t.partner_type_id(+) 
            and p.partner_status_id=s.partner_status_id(+) $where_clause $order_by_clause"]
            

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [empty_string_p $url] } {
	set url "&nbsp;"
    } else {
	set url "<a href=\"[im_maybe_prepend_http $url]\">[im_maybe_prepend_http $url]</a>"
    }
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>[ad_partner_default_font]<a href=view.tcl?[export_url_vars group_id]>$group_name</a></font></td>
  <td valign=top>[ad_partner_default_font][util_decode $partner_type "" "&nbsp;" $partner_type]</font></td>
  <td valign=top>[ad_partner_default_font][util_decode $partner_status "" "&nbsp;" $partner_status]</font></td>
  <td valign=top>[ad_partner_default_font]$url</font></td>
  <td valign=top>[ad_partner_default_font][util_decode $note "" "&nbsp;" $note]</font></td>
</tr>
"
    incr ctr
}


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no partners</b></ul>\n"
} else {
    set column_headers [list Partner Type Status URL Note]
    set url "index.tcl"
    set query_string [export_ns_set_vars url [list order_by]]
    if { [empty_string_p $query_string] } {
	append url "?"
    } else {
	append url "?$query_string&"
    }
    set table "
<table width=100% cellpadding=1 cellspacing=2 border=0>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table "  <th>$col</th>\n"
	} else {
	    append table "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    set results "
<br>
$table
</tr>
$results
</table>
"
}




set page_body "
[ad_partner_default_font "size=-1"]
Partner status: [im_slider status_id $status_types]
<br>Partner type: [im_slider type_id $partner_types]
<br>View: [im_slider mine_p $view_types]
</font>
<p>
$results

<p><a href=ae.tcl>Add a partner</a>
"

ns_db releasehandle $db

 
ns_return 200 text/html [ad_partner_return_template]
