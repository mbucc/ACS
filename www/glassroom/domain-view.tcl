# $Id: domain-view.tcl,v 3.0.4.1 2000/04/28 15:10:42 carsten Exp $
# domain-view.tcl -- view a domain's information, and also give them the
#                  option to edit or delete the information

#!!! need large, friendly letters if this domain is expired or near
#!!! expiration

set_form_variables

# Expects domain_name


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




# snarf the domain information

set db [ns_db gethandle]

set select_sql "
select by_whom_paid, last_paid, expires,
       trunc(months_between(expires, sysdate), 2) as expire_months
  from glassroom_domains
 where domain_name='$domain_name'"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the domain has been deleted, they can see the list of valid domains)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header "$domain_name"]

<h2>$domain_name</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Domain"]
<hr>

<h3>The Domain</h3>

<ul>
    <li> <b>Domain_Name:</b> $domain_name
         <p>

    <li> <b>Last Paid:</b> [util_AnsiDatetoPrettyDate $last_paid]
         <p>

    <li> <b>Last Paid By:</b> $by_whom_paid
         <p>

    <li> <b>Expires:</b> [util_AnsiDatetoPrettyDate $expires]
"

if { $expire_months < 0} {
    ns_write "    <font color=red>Domain has <blink>expired</blink></font>"
} elseif { $expire_months < [ad_parameter DomainExpireMonthWarning glassroom 2] } {
    ns_write "    <font color=red>Domain will soon expire</font>"
}


ns_write "
         <p>

</ul>
"


ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"domain-edit.adp?[export_url_vars domain_name]\">Edit</a>
        <p>

   <li> <a href=\"domain-delete.tcl?[export_url_vars domain_name]\">Delete</a>

</ul>

[glassroom_footer]
"


