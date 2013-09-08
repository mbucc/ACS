# /www/admin/partner/partner-ae.tcl

ad_page_contract {
    Adds/Edits a new partner

    @param partner_id specifies partner we're editing. If blank, we're adding
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-ae.tcl,v 3.2.2.6 2000/09/22 01:35:45 kevin Exp
} {
    { partner_id:naturalnum "" }
    { return_url "" }
}

# What variables are we pulling out?
set partner_vars [ad_partner_list_all_vars]       


if  {![empty_string_p $partner_id]} {

    # Build a list of the tcl variable names. group_id is a default that is always selected
    set sql_variables [list "group_id"]
    foreach var_triplet $partner_vars {
	lappend sql_variables [lindex $var_triplet 0]
    }
    
    db_1row partner_star_from_ad_partner "
    select [join $sql_variables ","]
    from ad_partner
    where partner_id=:partner_id"
    
    set page_title "Edit partner"
    set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] "$page_title"]
    
} else {

    set partner_id [db_nextval "ad_partner_partner_id_seq"]
    set page_title "Add partner"
    set group_id ""
    set context_bar [ad_context_bar_ws [list "index" "Partner manager"] $page_title]

}


set default_form_size 40

## Generate the form
foreach var_triplet $partner_vars {

    ## Each triplet in $partner_vars is:
    
    set variable_name [lindex $var_triplet 0] 
    set pretty_name [lindex $var_triplet 1]   
    set var_maxlength [lindex $var_triplet 2] 
    
    ## If the SQL maxlength is smaller than the default form size, then use a smaller form!

    if {![empty_string_p $var_maxlength] && $var_maxlength < $default_form_size} {
	set form_size $var_maxlength
    } else {
	set form_size $default_form_size
    }

    append table_body "
    <tr>
    <td>$pretty_name</td>
    <td><INPUT TYPE=text SIZE=$form_size NAME=\"$variable_name\" [util_decode $var_maxlength "" "" "MAXLENGTH=$var_maxlength"] [export_form_value $variable_name]></td>
    </tr>
    
    "
}




set sql "select ug.group_id as id, ug.group_name
           from user_groups ug
          order by lower(ug.group_name)"
set inner [list ""]
set outer [list "-- Please Select --"]

db_foreach parent_group_id_name_list $sql {
    lappend inner $id
    lappend outer $group_name
}


set page_body "
<form method=post action=\"partner-ae-2\">
[export_form_vars return_url]
[export_form_vars -sign partner_id]

<table>
$table_body
<tr>
  <td>Group</td>
  <td><select name=group_id>
[ad_generic_optionlist $outer $inner $group_id]
</select></td>
</tr>

</table>

<center><input type=submit value=\" $page_title \"></center>
</form>

"

doc_return 200 text/html [ad_partner_return_template]
