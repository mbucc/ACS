ad_page_contract {
    Example code for table-display.tcl functions.

    @cvs-id table-display-example.tcl,v 3.4.2.4 2000/09/22 01:34:11 kevin Exp
} {
    {page_mode ad_table_display_example_ott} 
    {orderby {}} 
    {customize {}}
    {table_display_example {}}
    {table_display_example_sort {}}
}

proc_doc ad_table_display_example_simple {orderby dummy1 dummy2 dummy3} {
    this is a simple version using
    the dimensional slider and table widgets 
} {
    # set up data for dimensional slider
    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never" {where "last_visit is null"}}
            {1m "Last Month" {where "last_visit + 30 > sysdate"}}
            {1w "Last Week" {where "last_visit + 7 > sysdate"}}
            {1d "Today" {where "last_visit > trunc(sysdate)"}}
        }}
        {lastname "Last name " d {
            {d "starts with d" {where "upper(last_name) like 'D%'"}}
            {notd "does not start with d" {where "upper(last_name) not like 'D%'"}}
            {all "all" {}}
        }}
    }

    # set up the table definition
    set table_def { 
        {email "e-Mail" {} {}}
        {email_bouncing_p "e-Bouncing?" {} tf}
        {user_state "State" {} l}
        {last_visit "Last Visit" {} r}
    }
    set page_content ""
    # spit out the dimensional bar
    append page_content "[ad_dimensional $dimensional_list]<p>\n"

    # generate and submit query then generate the table.
    # the 1 = 1 thing is a hack since ad_dimension_sql wants to 
    # prepend an add.  
    set sql "select * from users where 1 = 1
      [ad_dimensional_sql $dimensional_list where]
      [ad_order_by_from_sort_spec $orderby $table_def]"
      
    append page_content "[ad_table -Torderby $orderby example_table_simple $sql $table_def]"

    # and finally we are done
    append page_content "[ad_footer]"
    return $page_content
}

proc_doc ad_table_display_example_medium_complicated {orderby dummy1 dummy2 dummy3} {
    A slightly more involved example 
} {
    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never" {where "last_visit is null"}}
            {1m "Last Month" {where "last_visit + 30 > sysdate"}}
            {1w "Last Week" {where "last_visit + 7 > sysdate"}}
            {1d "Today" {where "last_visit > trunc(sysdate)"}}
        }}
        {lastname "Last name " d {
            {d "starts with d" {where "upper(last_name) like 'D%'"}}
            {notd "does not start with d" {where "upper(last_name) not like 'D%'"}}
            {all "all" {}}
        }}
    }
    

    # Full Name is an example of a synthetic field for which you have to 
    #      provide the ordering info yourself
    # email simple db column but with formatting 
    # email_bounce_p an example of the built in format of tf="Yes No"
    # last_visit right aligned
    # actions is a non-sorting column

    set table_def { 
        {fullname "Full Name" 
            {upper(last_name) $order, upper(first_names) $order}
            {<td><a href="/admin/users/one?user_id=$user_id">$first_names $last_name</a></td>} }
        {email "e-Mail" {} {<td><a href="mailto:$email">$email</a>}}
        {email_bouncing_p "e-Bouncing?" {} tf}
        {user_state "State" {} {}}
        {last_visit "Last Visit" {} r}
        {actions "Actions" {} 
            {<td><a href="/admin/users/basic-info-update?user_id=$user_id">Edit&nbsp;Info</a> | 
                <a href="/admin/users/password-update?user_id=$user_id">New&nbsp;Password</a> |
                [ad_registration_finite_state_machine_admin_links $user_state $user_id]}}
    }
    
    # generate the SQL query from the dimensional bar
    # and the sort clause from the table
    #
    # once again 1 = 1 is a hack...
    set sql "select * from users where 1 = 1 
      [ad_dimensional_sql $dimensional_list where] 
      [ad_order_by_from_sort_spec $orderby $table_def]"

    # spit out the dimensional bar
    set page_content ""
    append page_content "[ad_dimensional $dimensional_list]<p>\n"
    append page_content "[ad_table -Torderby $orderby example_table_medium $sql $table_def]"
    append page_content "[ad_footer]"
    return $page_content
}

proc_doc ad_table_display_example_ott {orderby customize table_display_example table_display_example_sort} {
    A full example with all the machinery including table customization and 
    full dynamic query generation.
} {
    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never" {where "last_visit is null"}}
            {1m "Last Month" {where "last_visit + 30 > sysdate"}}
            {1w "Last Week" {where "last_visit + 7 > sysdate"}}
            {1d "Today" {where "last_visit > trunc(sysdate)"}}
        }}
        {lastname "Last name " d {
            {d "starts with d" {where "upper(last_name) like 'D%'"}}
            {notd "does not start with d" {where "upper(last_name) not like 'D%'"}}
            {all "all" {}}
        }}
    }

      
    
    # now build the SQL query from the user_class table
    #
    set user_id [ad_get_user_id]
    set class_list {} 
    set page_content ""
    db_foreach all_user_call {
	select * from user_classes
    } {
	lappend class_list [list $user_class_id $name [list query "select users.* $sql_post_select"]]
    } 

    # a query for all users...
    lappend class_list [list all "All" {query "select * from users where 1 = 1"}]
    
    # now put the list of queries into the dimensiona_list
    lappend dimensional_list [list user_class "User Class" all $class_list]
    
    
    # Full Name is an example of a synthetic field for which you have to 
    #      provide the ordering info yourself
    # email simple db column but with formatting 
    # email_bounce_p an example of the built in format of tf="Yes No"
    # last_visit right aligned
    # actions is a non-sorting column w/o 

    set table_def { 
        {fullname "Full Name" 
            {upper(last_name) $order, upper(first_names) $order, upper(email) $order}
            {<td><a href="/admin/users/one?user_id=$user_id">$first_names $last_name</a></td>} }
        {email "e-Mail" {} {<td><a href="mailto:$email">$email</a>}}
        {email_bouncing_p "e-Bouncing?" {} tf}
        {user_state "State" {} {}}
        {last_visit "Last Visit" {} r}
        {priv_name "Priv Name" {} r}
        {priv_email "Priv Email" {} r}
        {converted_p "Converted?" {} tf}
	{second_to_last_visit "Visit-2" {} {}}
	{n_sessions "Visits" {} r}
	{registration_date "Registered On" {} {}}
	{registration_ip "Registration IP" {} {<td><a href="/admin/host?ip=[ns_urlencode $registration_ip]">$registration_ip</a></td>}}
        {approved_date "Approved On" {} {}}
        {approving_user "By UID" {} {}}
	{approving_note "Note" {} {}}
	{email_verified_date "E-Mail Verified On" {} {}}
	{banning_note "Ban Note" {} {}}
	{crm_state "CRM State" {} {}}
	{crm_state_entered_date	"CRM State As Of" {} {}}
	{portrait_upload_date "Portrait Uploaded" {} {}}
	{portrait_file_type "Portrait MIME" {} {}}
	{portrait_original_width "Portrait Width" {} {}}
	{portrait_original_height "Portrait Height" {} {}}
        {actions "Actions" {} 
            {<td><a href="/admin/users/basic-info-update?user_id=$user_id">Edit&nbsp;Info</a> | 
                <a href="/admin/users/password-update?user_id=$user_id">New&nbsp;Password</a> |
                [ad_registration_finite_state_machine_admin_links $user_state $user_id]}}
    }
    
    # load the current customized table and sort if needed 
    set columns {}
    if { ! [empty_string_p $table_display_example] } { 
        set columns [ad_custom_load $user_id table_display_example $table_display_example table_view]
    }
    if {[empty_string_p $columns]} { 
        # if we did not have a custom set of columns set a default
        set columns {fullname email approved_date registration_ip actions}
    }

    if {[empty_string_p $orderby]} {
        if { ![empty_string_p $table_display_example_sort]} { 
            set orderby [ad_custom_load $user_id table_display_example_sort $table_display_example_sort table_sort]
        }
    } else { 
        # if we have orderby then we have updated the sort...
        set table_display_example_sort {} 
    }
        
    if { $customize == "table" } { 

        # If we are in table customization mode generate the form 
        set return_url "[ns_conn url]?[export_ns_set_vars url [list table_display_example customize]]"
        append page_content "[ad_table_form $table_def select $return_url table_display_example $table_display_example $columns]"

    } elseif { $customize == "sort" } {

        set return_url "[ns_conn url]?[export_ns_set_vars url [list orderby table_display_example_sort customize]]"
        append page_content "[ad_table_sort_form $table_def select $return_url table_display_example_sort $table_display_example_sort $orderby]"

    } else { 
        # The normal table

        # spit out the dimensional bar
        append page_content "[ad_dimensional $dimensional_list]<p>\n"

        # now the table views
        set customize_url "[ns_conn url]?[export_ns_set_vars url [list customize table_display_example]]&customize=table&table_display_example="
        set use_url "[ns_conn url]?[export_ns_set_vars url table_display_example]&table_display_example="
        append page_content "Table Views: [ad_custom_list $user_id table_display_example $table_display_example table_view $use_url $customize_url]<br>"

        # now the sorts
        set customize_url "[ns_conn url]?[export_ns_set_vars url [list customize orderby table_display_example_sort]]&customize=sort&table_display_example_sort="
        set use_url "[ns_conn url]?[export_ns_set_vars url [list orderby table_display_example_sort]]&table_display_example_sort="
        append page_content "Sorts: [ad_custom_list $user_id table_display_example_sort $table_display_example_sort table_sort $use_url $customize_url "new sort"]<br>"

        # Generate the query
        set sql "[ad_dimensional_sql $dimensional_list query {}] 
         [ad_dimensional_sql $dimensional_list where]
         [ad_order_by_from_sort_spec $orderby $table_def]"

        #pull out the actual data
        append page_content "[ad_table -Torderby $orderby -Tcolumns $columns table_complicated $sql $table_def]"
    }

    # and finally we are done
    append page_content "[ad_footer]"
    return $page_content
}

#
# Main driver for the page 
#

set page_content ""


append page_content [ad_header "Table and dimensional bar example"]
    
append page_content "<H1>JD table and dimensional bar example</H1>
 Code:<ul>
 <LI> <a href=\"/doc/proc-one?proc_name=ad_dimensional\">ad_dimensional</a>
 <LI> <a href=\"/doc/proc-one?proc_name=ad_dimensional_sql\">ad_dimensional_sql</a>
 <LI> <a href=\"/doc/proc-one?proc_name=ad_dimensional_set_variables\">ad_dimensional_set_variables</a>
 <LI> <a href=\"/doc/proc-one?proc_name=ad_table\">ad_table</a>
  <br>
 </UL><p><p>Page mode: "

set exports [export_ns_set_vars url page_mode]
set url [ns_conn url]

foreach mode {ad_table_display_example_simple ad_table_display_example_medium_complicated ad_table_display_example_ott} {
    if {[string compare $mode $page_mode] == 0} {
	append page_content "<strong>($mode <a href=\"/doc/proc-one?proc_name=$page_mode\">CODE</a>)</strong>&nbsp;&nbsp;"
    } else { 
	append page_content "<a href=\"$url?page_mode=[ns_urlencode $mode]\">$mode</a>&nbsp;&nbsp"
    }
}
append page_content "<p>note the User Class field in the ad_table_display_example_ott is built dynamically from 
the database and if you have a lot of user classes it will look stupid.  It is just there to demonstrate 
the functionality...<br><br>"

append page_content [eval [list $page_mode $orderby $customize $table_display_example $table_display_example_sort]]


doc_return  200 text/html $page_content
		     
