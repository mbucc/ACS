# /www/admin/content-sections/index.tcl
ad_page_contract {
    Content Section administration main page 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  tarik@arsdigita.com
    @creation-date 22/12/99
    @cvs-id index.tcl,v 3.2.2.6 2000/09/22 01:34:34 kevin Exp

} { }

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set page_title "Content Sections"

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar $page_title ]
<hr>
"

if { $scope=="group" } {
    # if scope is group, let's see what is the level of module administration allowed by 
    # system administrator for this group. 

    set group_module_administration [db_string content_get_group_mod_admin "
    select group_module_administration 
 from user_group_types 
 where group_type = user_group_group_type(:group_id)"]

    # let's see if custom section module is installed 

    set custom_sections_p [db_0or1row content_get_content_sections "
    select scope as dummy from content_sections 
 where scope = 'group' and group_id = :group_id and module_key = 'custom-sections'"]
 
    # let's get the group public url
    set group_public_url [ns_set get $group_vars_set group_public_url]
}

set sql_query  "
select section_key, section_pretty_name, section_type, module_key, 
 section_url_stub, decode (enabled_p, 't', 1, 0) as enabled_p 
 from content_sections 
 where [ad_scope_sql]
 order by enabled_p desc, sort_key asc"

set system_section_counter 0
set enabled_system_section_counter 0
set disabled_system_section_counter 0
set custom_section_counter 0
set enabled_custom_section_counter 0
set disabled_custom_section_counter 0
set static_section_counter 0
set enabled_static_section_counter 0
set disabled_static_section_counter 0

db_foreach select_query $sql_query  {

    if { $section_type=="system" || $section_type=="admin" } {
	
	# for now, we only support system and admin sections for scope group
	if { $scope=="group" && $group_module_administration!="none" } {

	    set system_sections_html "
	    <li>$section_pretty_name 
	    [ad_space 1](<a href=\"content-section-edit?[export_url_vars section_key]\">properties</a>"	
	    # notice that in special case of custom-section module, there are no public pages, so we will not 
	    # offer view link
	    if { $section_type=="system" && $module_key!="custom-sections" && $enabled_p} {
		append system_sections_html " | 
		<a href=\"$group_public_url/[ad_urlencode $section_key]/\">view</a>)
		"
	    } else {
		append system_sections_html ")"
	    }

	    # if groups have full module administration, we can allow them to completely remove the module
	    if { $group_module_administration=="full" } {
		
	    }
	    
	    if { $enabled_p } {
		append enabled_system_sections_html $system_sections_html
		incr enabled_system_section_counter
	    } else {
		append disabled_system_sections_html $system_sections_html
		incr disabled_system_section_counter
	    }
	    incr system_section_counter
	    
	}
    }

    if { [string compare $section_type custom]==0 } {
	
	# for now, we only support custom sections for the scope group
	if { $scope=="group" && $custom_sections_p } {
	    
	    set custom_sections_html "
	    <li>$section_pretty_name 
	    [ad_space 1]<a href=\"content-section-edit?[export_url_vars section_key]\">(properties</a>	
	    "
	    
	    if { $enabled_p } {
		append custom_sections_html " |
		<a href=\"$group_public_url/[ad_urlencode $section_key]/\">view</a>)
		" 
		append enabled_custom_sections_html $custom_sections_html
		incr enabled_custom_section_counter
	    } else {
		append custom_sections_html ")"
		append disabled_custom_sections_html $custom_sections_html
		incr disabled_custom_section_counter
	    }

	    incr custom_section_counter
	}
    }
    
    if { [string compare $section_type static]==0 } {
	
	set static_sections_html "
	<li>$section_pretty_name 
  	[ad_space 1](<a href=\"content-section-edit?[export_url_vars section_key]\">properties</a>	
	"
	if { $enabled_p } {
	    switch $scope {
		public {
		    append static_sections_html " |
		    <a href=\"$section_url_stub\">view</a>)
		    "
		}
		group {
		    append static_sections_html " |
		    <a href=\"$group_public_url/[ad_urlencode $section_key]/\">view</a>)
		    "    
		}
	    }
	    append enabled_static_sections_html $static_sections_html
	    incr enabled_static_section_counter
	} else {
	    append static_sections_html ")"
	    append disabled_static_sections_html $static_sections_html
	    incr disabled_static_section_counter
	}
	    

	incr static_section_counter
    }
}

if { $system_section_counter>0 } {
    append html "
    <h4>Modules</h4>
    <p>
    "
}

if { $enabled_system_section_counter>0 } {
    append html "
    enabled <p>
    <ul>
    $enabled_system_sections_html
    </ul>
    <p>
    "
}

if { $disabled_system_section_counter>0 } {
    append html "
    disabled<p>
    <ul>
    $disabled_system_sections_html
    </ul>
    <p>   
    "
}

if { $custom_section_counter>0 } {
    append html "
    <h4>Custom Sections</h4>
    <p>
    "
}
if { $enabled_custom_section_counter>0 } {
    append html "
    enabled <p>
    <ul>
    $enabled_custom_sections_html
    </ul>
    <p>
    "
}

if { $disabled_custom_section_counter>0 } {
    append html "
    disabled<p>
    <ul>
    $disabled_custom_sections_html
    </ul>
    <p>   
    "
}

if { $static_section_counter>0 } {
    append html "
    <h4>Static Sections</h4>
    <p>
    "
}
if { $enabled_static_section_counter>0 } {
    append html "
    enabled <p>
    <ul>
    $enabled_static_sections_html
    </ul>
    <p>
    "
}

if { $disabled_static_section_counter>0 } {
    append html "
    disabled<p>
    <ul>
    $disabled_static_sections_html
    </ul>
    <p>   
    "
}
if { [expr $system_section_counter + $custom_section_counter + $static_section_counter] == 0 } {
    append html "There are no Content Sections in the database right now.<p>"
}

# for now, we only support system and admin sections for scope group
if { $scope=="group" && $group_module_administration=="full" } {

    # let's see if there are any modules to be associated with this group
    set return_count [db_0or1row content_get_1_scope_p "
    select sysdate from dual 
 where exists (select 1
 from acs_modules 
 where supports_scoping_p = 't' 
 and module_key not in (select module_key 
 from content_sections 
 where [ad_scope_sql]
 and (section_type = 'system' or section_type = 'admin')))"]
    
    set module_available_p $return_count
 
    if { $module_available_p } {
	append html "
	<p>
	<li><a href=\"content-section-add?type=module\">Add Module</a><br>
	"
    }
}

# for now, linking sections, system and custom sections are supported only for the group scope 
if { $scope=="group" } {
    append html "
    <li><a href=\"link\">Section Navigation</a><br>
    "
}

append html "
<li><a href=\"content-section-add?type=static\">Add Static Section</a><br>
"
# for now, we only support custom sections for the scope group
if { $scope=="group" && $custom_sections_p } {
    append html "
    <li><a href=\"content-section-add?type=custom\">Add Custom Section</a><p>
    "
}

db_release_unused_handles

append page_body "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_body

