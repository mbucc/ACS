# $Id: portals-defs.tcl,v 3.2.2.2 2000/04/28 15:08:18 carsten Exp $
#
# portals-defs.tcl
#
# by aure@arsdigita.com, September 1999
# 

ns_register_proc GET /portals/*[ad_parameter PortalExtension portals .ptl] portal_display

proc_doc portal_footer {db id group_name page_number type} {Generate footer for portal pages.} {

    # Get generic display information
    portal_display_info

    # Find out the number of pages this portal has
    set total_pages [database_to_tcl_string $db "
    select count(*) from portal_pages where ${type}_id=$id"]

    if { $type == "group" } {
	# names and emails of the managers of this portal group;
	# we need the "distinct" because a user can be mapped more
	# than once to a group (one mapping per role)
	#
	set administrator_query "select distinct u.first_names||' '||u.last_name as admin_name, u.email as admin_email
	from users u, user_group_map map
	where u.user_id =  map.user_id
	and map.group_id = $id"

	set selection [ns_db select $db $administrator_query]

	set administrator_list [list]
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    lappend administrator_list "<a href=mailto:$admin_email>$admin_name</a>"
	}
	set extra_footer_text "The content of this portal page is managed by: [join $administrator_list ", "]"
	regsub -all -- " " [string tolower $group_name] {-} link_name
    } else {
	set link_name "user$id"
	set extra_footer_text "<a href=\"manage-portal.tcl\">Personalize</a> this portal."
    }

    set page_name [database_to_tcl_string_or_null $db "
    select page_name from portal_pages 
    where page_number = $page_number 
    and ${type}_id = $id"]


    # while the following may not seem very readable, it is important that there are no
    # extra spaces in this table
    set footer_html "
    <table width=100% border=0 cellspacing=0 cellpadding=0>
    <tr bgcolor=$header_bg>
       <td colspan=2 width=100%><img src=[ad_parameter SpacerImage portals] width=10 height=3></td>
    </tr>
    <tr>
       <td><font face=arial,helvetica><b>[string toupper "$system_name : $group_name"]</td>
       <td align=right valign=bottom><table width=100% border=0 cellspacing=0 cellpadding=1 bgcolor=$header_bg>
          <tr>
             <td><table width=100% border=0 cellspacing=1 cellpadding=3 bgcolor=$header_bg><tr>\n"

    # set up the page tabs only if there is more than one page
    if {$total_pages > 1} {

	# if we want equal size tabs, regsub a width restriction into the td
	if {[ad_parameter EqualWidthTabsP portals]} {
	    regsub {<td} $header_td "<td width=[expr round(100/$total_pages)]" header_td
	    regsub {<td} $subheader_td "<td width=[expr round(100/$total_pages)]" subheader_td
	}

	# Get a list of portal page names	
	set page_select "
	select distinct nvl(page_name,'Page #'||page_number) as page_name, page_number as new_page_number
	from   portal_table_page_map p_tpm, portal_pages p_p
	where  p_tpm.page_id = p_p.page_id
	and    ${type}_id = $id
	order by page_number"

	set selection [ns_db select $db $page_select]
	
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query

	    if {$new_page_number == $page_number} {
		append footer_html "$header_td <center> $page_name</td>\n"
	    } else {
		append footer_html "
		$subheader_td <center><a href=$link_name-$new_page_number[ad_parameter PortalExtension portals .ptl]>$page_name</a></td>\n"
	    }
	}
    }

    append footer_html "
    </tr></table>
    </td></tr></table>
    </td></tr></table>
    $font_tag <p>
    $extra_footer_text
    <p>
    If you encounter any bugs or have suggestions that are not content-related, email <a href=\"mailto:[ad_parameter Administrator portals [ad_system_owner]]\">[ad_parameter AdministratorName portals [ad_system_owner]]</a>.
</body>
</html>
"
   
    return $footer_html
}


proc_doc portal_header {db id group_name page_number type} {Generate header for portal pages.} {

    # Get generic display information
    portal_display_info
    
    # Find out the number of pages this portal has
    set total_pages [database_to_tcl_string $db "
    select count(*) from portal_pages where ${type}_id=$id"]

    set page_name [database_to_tcl_string_or_null $db "
    select page_name from portal_pages 
    where page_number=$page_number and ${type}_id=$id"]


    # while the following may not seem very readable, it is important that there are no
    # extra spaces in this table
    set header_html "
    <table width=100% border=0 cellspacing=0 cellpadding=0>
    <tr>
       <td><font face=arial,helvetica><b>[string toupper "$system_name : $group_name"]</td>
       <td align=right valign=bottom><table width=100% border=0 cellspacing=0 cellpadding=1 bgcolor=$header_bg>
          <tr>
             <td><table width=100% border=0 cellspacing=1 cellpadding=3 bgcolor=$header_bg><tr>\n"

    # set up the page tabs only if there is more than one page
    if {$total_pages > 1} {

	if {$type == "group"} {
	    # convert group_name to a URL friendly string
	    regsub -all -- " " [string tolower $group_name] {-} link_name
	} else {
	    set link_name "user$id"
	}
	# if we want equal size tabs, regsub a width restriction into the td
	if {[ad_parameter EqualWidthTabsP portals]} {
	    regsub {<td} $header_td "<td width=[expr round(100/$total_pages)]" header_td
	    regsub {<td} $subheader_td "<td width=[expr round(100/$total_pages)]" subheader_td
	}

	# Get a list of portal page names	
	set page_select "
	select distinct nvl(page_name,'Page #'||page_number) as page_name, page_number as new_page_number
	from   portal_table_page_map p_tpm, portal_pages p_p
	where  p_tpm.page_id = p_p.page_id
	and    ${type}_id = $id
	order by page_number"

	set selection [ns_db select $db $page_select]
	
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query

	    if {$new_page_number == $page_number} {
		append header_html "$header_td <center> $page_name</td>\n"
	    } else {
		append header_html "
		$subheader_td <center><a href=$link_name-$new_page_number[ad_parameter PortalExtension portams .ptl]>$page_name</a></td>\n"
	    }
	}
    }
    append header_html "
    </tr></table>
    </td></tr></table>
    </td></tr><tr bgcolor=$header_bg><td colspan=2 width=100%><img src=[ad_parameter SpacerImage portals] width=10 height=3></td></tr></table>\n"
   
    return $header_html
}


proc portal_display_page {id page_number type} {

    # Get generic display information
    portal_display_info

    set left_side_width  [ad_parameter LeftSideWidth  portals]
    set right_side_width [ad_parameter RightSideWidth portals]

    if ![empty_string_p $left_side_width] {
	set left_side_width "width=$left_side_width"
    }
    if ![empty_string_p $right_side_width] {
	set left_side_width "width=$right_side_width"
    }

    set table_spacer "<table border=0 cellpadding=0 cellspacing=0><tr><td><img src=[ad_parameter SpacerImage portals] width=100% height=5></td></tr></table>"

    set db [ns_db gethandle]

    if {$type == "group" } {    
	set main_name  [database_to_tcl_string $db "
	    select upper(group_name) from user_groups where group_id=$id"] 
	set nottype "user"
    } else {
	set main_name [database_to_tcl_string $db "
	    select upper(first_names||' '||last_name) from users where user_id=$id"]
	set nottype "group"
    }

    set page_name [database_to_tcl_string_or_null $db "
    select page_name from portal_pages where page_number=$page_number and ${type}_id=$id"]

    
    set main_title "$main_name : $page_name"

    # Get the table_id for each table that will appear on this page

    set table_select "
    select  page_side, table_name, adp
    from    portal_table_page_map map, portal_pages p_p, portal_tables p_t
    where   map.page_id = p_p.page_id
    and     p_t.table_id = map.table_id
    and     ${type}_id = $id
    and     ${nottype}_id is null
    and     page_number = $page_number
    order by page_side, sort_key"
    
    set table_list [database_to_tcl_list_list $db $table_select]

    set l_side_html ""
    set r_side_html ""
    
    set header [portal_header $db $id $main_name $page_number $type]
    set footer [portal_footer $db $id $main_name $page_number $type]

    # we're done with $db, let's leave it around in case any of the 
    # page elements need to use it

    foreach table_triplet $table_list {
	set page_side [lindex $table_triplet 0]
	set table_name [lindex $table_triplet 1]
	set adp [lindex $table_triplet 2]

	# we have to evaluate the adp now; at this point we have to 
	# worry about security **** (the .adp could contain an exec or 
	# destructive database action; of course only authorized portal
	# admins get to change the code but still).  We also have to 
	# worry about programming mistakes and don't want a little bug
	# in one section to make an entire portal unavailable
	if [catch { set parsed_adp [ns_adp_parse -string $adp] } errmsg] {
	    ns_log Error "portal_display_page tried to evaluate\n\n$adp\n\nand got hit with\n\n$errmsg\n"
	    # go to the next loop iteration
	    continue 
	} 
	
	# replace any <td>s or <th>s in an embedded table with one has the normal font tag
	# after it so that this text also will conform to the portal standard font
	regsub -nocase -all {(<td[^>]*>)} $parsed_adp {\1 font_tag} table_innards
	regsub -nocase -all {(<th[^>]*>)} $table_innards {\1 font_tag} table_innards
	regsub -nocase -all {font_tag} $table_innards $font_tag table_innards

	# let's ADP parse evaluate the table_name, again watching for errors
	if [catch { set parsed_table_name [ns_adp_parse -string $table_name] } errmsg] {
	    ns_log Error "portal_display_page tried to evaluate\n\n$table_name\n\nand got hit with\n\n$errmsg\n"
	    # go to the next loop iteration
	    continue
	}

	set html_table "
	$begin_table
	<tr>
	   $header_td [string toupper $parsed_table_name]</td>
	</tr>
	<tr>
	   $normal_td$table_innards</td>
	</tr>
	$end_table"
	
	# Place the HTML table we have just finished creating on either the left or right side of the page
	# by appending the left_side_html or right_side_html string.
	
	append ${page_side}_side_html  "$html_table $table_spacer"


    }

    # we're done evaluating all the elements of a page 
    ns_db releasehandle $db
   
    return "

    <title> $main_title </title>

    $body_tag

    <table cellpadding=3 cellspacing=0 border=0>
    <tr>
       <td colspan=2>$header</td>
    </tr>
    <tr>
       <td $left_side_width  valign=top>$l_side_html</td>
       <td $right_side_width valign=top>$r_side_html</td>
    </tr>
    <tr>
       <td colspan=2>$footer</td>
    </tr>
    </table>"

}

proc_doc portal_display {} {Registered procedure that uses the URL to determine what page to show} {

    set full_url [ns_conn url]
    set portal_extension [ad_parameter PortalExtension portals .ptl]

    if [regexp "/portals/user(.*)-(\[0-9\]+)$portal_extension" $full_url match user_id page_number] {
	ad_maybe_redirect_for_registration
	# memoize a user page for a short time, first check to make sure we're not evaling 
	# anything naughty
	validate_integer "user_id" $user_id
	validate_integer "page_number" $page_number
	ns_return 200 text/html [util_memoize "portal_display_page $user_id $page_number user" 10]
    } elseif [regexp "/portals/(.*)-(\[0-9\]+)$portal_extension" $full_url match group_name page_number] {
	regsub -all -- {-} $group_name { } group_name
	set group_name [string toupper $group_name]
	set db [ns_db gethandle]

	set group_id  [database_to_tcl_string_or_null $db "
	    select group_id 
            from user_groups where upper(group_name)='[DoubleApos $group_name]'"] 
	if { [empty_string_p $group_id] } {
	    # If the group does not exist, we redirect to the
	    # portal list.

	    ad_returnredirect [ad_parameter MainPublicURL portals]
	} else {
	    ns_db releasehandle $db
	    validate_integer "group_id" $group_id
	    validate_integer "page_number" $page_number
	    ns_return 200 text/html [util_memoize "portal_display_page $group_id $page_number group" [ad_parameter CacheTimeout portals 600]]
	}
    } else {
	ad_returnredirect [ad_parameter MainPublicURL portals]
    }

}


proc_doc portal_check_administrator_maybe_redirect {db user_id {group_id ""} {redirect_location ""}} {} {
    
    ad_maybe_redirect_for_registration

    # set up the where clause - a blank group_id results in a more restrictive group check
    if ![empty_string_p $group_id] {
	set group_restriction "and (map.group_id = $group_id or group_name=  'Super Administrators')"
    } else {
	set group_restriction "and group_name=  'Super Administrators'"
    }
    if {[empty_string_p $redirect_location]} {
        # Added by Branimir, Jan 26, 2000, we also need to put URL variables into return_url
        set what_the_user_requested [ns_conn url]
        if { !([ns_getform] == "") } {
	     set url_vars [export_entire_form_as_url_vars]
             append what_the_user_requested ?$url_vars
        }
	set redirect_location "/register/index.tcl?return_url=[ns_urlencode $what_the_user_requested]"
    }

    set count [database_to_tcl_string $db " 
    select count(*) 
    from    user_group_map map, user_groups ug 
    where   map.user_id = $user_id
    and     map.group_id = ug.group_id
    and     ug.group_type = 'portal_group'
    and     role='administrator'
    $group_restriction"]

    if {$count == 0 } {
	ad_returnredirect $redirect_location
        return -code return
    }
    return
}

proc_doc portal_group_name {db group_id} {Quite simply gets the group_name for a group_id.} {
    return [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id = $group_id"]
}



proc portal_system_owner {} {
    return [ad_parameter SystemOwner portals [ad_system_owner]]
}

proc portal_admin_footer {} {
    return "<hr>
<a href=\"mailto:[portal_system_owner]\"><address>[portal_system_owner]</address></a>
</body>
</html>"
}

proc portal_admin_header {title} {
    # Get generic display information
    portal_display_info
    
    return "
    <html>
    <head>
    <title> $title</title>
    </head>
    $body_tag 
    <h2> $title </h2>"
}


proc_doc portal_display_info {} { uplevels all the system specific display information  for the portals system} {
    uplevel {
	set system_name  [ad_parameter SystemName  portals]
	set body_tag     [ad_parameter BodyTag     portals]
	set begin_table  [ad_parameter BeginTable  portals]
	set end_table    [ad_parameter EndTable    portals]
	set font_tag     [ad_parameter FontTag     portals]
	set header_td    [ad_parameter HeaderTD    portals]
	set subheader_td [ad_parameter SubHeaderTD portals]
	set normal_td    [ad_parameter NormalTD    portals]
	set header_bg    [ad_parameter HeaderBGColor portals]
    }
}


proc_doc portal_adp_parse {adp db} { returns a parsed adp string - done here so variables in the adp don't conflict with variables in the main page (except for $db, which we make sure is always a valid connection from the main pool).  Also modifies any <td>s or <th>s in an embedded table (adp) to  have a standard  font tag after it so that this text also will conform to the portal standard font.} {
    
    portal_display_info

    regsub -nocase -all {(<td[^>]*>)} [ns_adp_parse -string $adp] {\1 font_tag} shown_adp
    regsub -nocase -all {(<th[^>]*>)} $shown_adp {\1 font_tag} shown_adp
    regsub -nocase -all {font_tag} $shown_adp $font_tag shown_adp

    return "$shown_adp"
}








