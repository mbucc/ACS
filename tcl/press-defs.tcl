# /tcl/press-defs.tcl
#
# Definitions for the press module
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: press-defs.tcl,v 3.0.4.2 2000/03/16 20:57:02 ron Exp $
# -----------------------------------------------------------------------------

util_report_library_entry

# Wrappers for the press module parameters to supply default values in
# case the site administrator leaves them out of the ACS ini file

proc_doc press_active_days {} {returns the maximum number of days that
a press release will remain active on /press/} {
    return [ad_parameter ActiveDays press 60]
}

proc_doc press_display_max {} {returns the maximum number of press
releases to display on /press/} {
    return [ad_parameter DisplayMax press 20]
}

# Everything that's not a proc_doc is a private utility function for
# the press module  

# Sample data for previews, forms, etc.

proc_doc press_coverage_samples {} {sets sample press coverage variables
(sample_publication_name, etc.) in the stack frame of the caller}  {  
    uplevel 1 { 
	set sample_publication_name      "Time" 
	set sample_publication_link      "http://time.com/" 
	set sample_publication_date      "January 1, 2100" 
	set sample_publication_date_desc "January issue" 
	set sample_article_title         "Time's Person of the Year" 
	set sample_article_link          "http://www.pathfinder.com/time/poy/" 
	set sample_article_pages         "pp 50-52"
	set sample_abstract              \
          "Welcome, Jeff Bezos, to TIME's Person of the Year
 	   club. As befits a new-era entrepreneur, at 35 you are
	   the fourth youngest individual ever, preceded by
	   25-year-old Charles Lindbergh in 1927; Queen
	   Elizabeth II, who made the list in 1952 at age 26; and
	   Martin Luther King Jr., who was 34 when he was
	   selected in 1963. A pioneer, royalty and a
	   revolutionary--noble company for the man who is,
	   unquestionably, king of cybercommerce."
    }
}

# Build and optionally initialize an input form element

proc press_entry_widget {name varname size {help ""} } {
    upvar $varname value

    if {[info exists value] && ![empty_string_p $value]} {
	set value_clause "value=\"$value\""
    } else {
	set value_clause ""
    }
	
    return "
    <tr>
    <td align=right><b>$name</b>:</td>
    <td><input name=$varname type=text size=$size $value_clause></td>
    <td>$help</td>
    </tr>"
}

# Build a scope selection menu.  This gives the option of making press
# coverage public or restricted to members of a certain user group.
# The only groups offered are those for which the user is a member.

proc press_scope_widget {db {default_group ""}} {

    # Available groups are specific to each user

    set user_id [ad_verify_and_get_user_id]

    # For group-only administrators just offer the groups for which
    # they have administrative priviledges

    if {[ad_administrator_p $db $user_id] } {
	set restrictions ""
    } else {
	set restrictions "
	and group_id in 
           (select group_id
	    from   user_group_map
            where  user_group_map.user_id     = $user_id
	    and    lower(user_group_map.role) = 'administrator')"
    }

    # Get the list of available user groups for this user

    set selection [ns_db select $db "
    select   group_id, group_name
    from     user_groups
    where    group_type <> 'administration' 
    $restrictions
    order by group_name"]

    if {[empty_string_p $default_group]} {
	set scope_items "<option align=left value=\"\" selected>Public\n"
    } else {
	set scope_items "<option align=left value=\"\">Public\n"
    }

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$group_id == $default_group} {
	    append scope_items \
		    "<option value=$group_id selected>Restricted to $group_name\n"
	} else {
	    append scope_items \
		    "<option value=$group_id>Restricted to $group_name\n"
	}
    }

    return "
    <tr>
    <td align=right><b>Scope</b>:</td>
    <td colspan=2>
    <select name=group_id>$scope_items</select>
    </td>
    </tr>"
}

# Build a template selection menu

proc press_template_widget {db {default_template_id 1}} {

    set selection [ns_db select $db "
    select template_id, template_name
    from   press_templates
    order  by template_name"]

    set template_list ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append template_list "
	<option value=$template_id 
	[expr {$template_id == $default_template_id ? "selected" : ""}]>
	$template_name"
    }

    return "
    <tr>
    <td align=right><b>Template</b>:</td>
    <td>
    <select name=template_id>
    $template_list
    </select>
    </td>
    </tr>"
}

# Build a radio button 

proc press_radio_widget {varname value description} {
    upvar $varname current_value

    if {[info exists current_value] && $current_value == $value} {
	set checked "checked"
    } else {
	set checked ""
    }

    return "<input type=radio name=$varname value=\"$value\" $checked> $description"
}

# -----------------------------------------------------------------------------

# Build a preview list of current templates to use on add/edit pages

proc_doc press_template_list {db} {returns a definition list of available templates} {

    set selection [ns_db select $db "
    select template_name,
           template_adp
    from   press_templates
    order  by template_name"]

    set avail_count 0
    set avail_list ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr avail_count
	append avail_list "
	<dt>$template_name</dt>
	<dd>[press_coverage_preview $template_adp]</dd>
	</tr>"
    }
    
    if {$avail_count == 0} {
	set avail_template_list "
	There are no press coverage templates in the system."
    } else {
	set avail_template_list "
	<dl>$avail_list</dl>"
    }

    return $avail_template_list
}

# Format press coverage
#
# BUG: AolServer 2.x does not throw exceptions for ns_adp_parse.  This
# is supposed to be fixed in AolServer 3.0.

proc_doc press_coverage { \
	publication_name publication_link publication_date \
	article_title article_link article_pages abstract \
	template_adp } \
	{returns a string containing one formatted press item} {
    
    # Insert optional hyperlinks (clickthrough tracking optional)

    set clickthrough_p [ad_parameter ClickThroughP press]

    if {![empty_string_p $publication_link]} {
	if {$clickthrough_p != 0} {
	    set publication_name \
		    "<a href=/ct/press/index.tcl?send_to=$publication_link>$publication_name</a>"
	} else {
	    set publication_name "<a href=$publication_link>$publication_name</a>"
	}

    }

    if {![empty_string_p $article_link]} {
	if {$clickthrough_p != 0} {
	    set article_title "<a href=/ct/press/index.tcl?send_to=$article_link>$article_title</a>"
	} else {
	    set article_title \
		    "<a href=$article_title>$article_title</a>"
	}
    }

    return [ns_adp_parse -string $template_adp]
}

# Build a template preview

proc_doc press_coverage_preview {template_adp} {returns a string
containing a template preview} {
    
    # Grab the sample press item
    press_coverage_samples

    # Format it without links
    return [press_coverage \
	    $sample_publication_name "" \
            $sample_publication_date \
	    $sample_article_title "" \
	    $sample_article_pages $sample_abstract \
	    $template_adp]
}

# Authorization rules

proc_doc press_admin_p {db user_id group_id} {returns 1 if this user is a valid
site-wide or group administrator for press coverage, 0 otherwise} {
    if [ad_administrator_p $db $user_id] {
	# this is a site-wide admin, return true always
	return 1
    } elseif {$user_id != 0} {
	# the person isn't a site-wide admin but maybe he can be authorized
	# because he is a group admin (since this is for a group-specific item)
	return [ad_user_group_authorized_admin $user_id $group_id $db]
    }
    # not authorized via one of the preceding mechanisms
    return 0
}

proc_doc press_admin_any_group_p {db user_id} {returns 1 if this user
is a valid site-wide or group administrator for any group, 0 otherwise} {
    if {[ad_administrator_p $db $user_id]} {
	# this is a site-wide admin, return true always
	return 1
    } elseif {$user_id != 0} {
	# we have an authenticated user, let's see if they have the
	# admin role in ANY group
	if {0 < [database_to_tcl_string $db "
	select count(*)
	from   user_group_map 
	where  user_id     = $user_id
	and    lower(role) = 'administrator'"]} {
	    return 1
	} else {
	    return 0
	}
    }
    # not authorized via one of the preceding mechanisms
    return 0
}

util_report_successful_library_load