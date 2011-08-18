# $Id: cert-view.tcl,v 3.0.4.1 2000/04/28 15:10:41 carsten Exp $
# cert-view.tcl -- view a certificate's information, and also give them the
#                  option to edit or delete the information

#!!! need large, friendly letters if this cert is expired or near
#!!! expiration


set_form_variables

# Expects cert_id

# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




# snarf the cert information

set db [ns_db gethandle]

set select_sql "
select hostname, issuer, encoded_email, expires,
       trunc(months_between(expires, sysdate), 2) as expire_months
  from glassroom_certificates
 where cert_id=$cert_id"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the cert has been deleted, they can see the list of valid certs)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Certificate for $hostname"]

<h2>Certificate for $hostname</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Certificate"]
<hr>

<h3>The Certificate</h3>

<ul>
    <li> <b>Hostname:</b> $hostname
         <p>

    <li> <b>Issuer:</b> $issuer
         <p>

    <li> <b>Certificate Request:</b> $encoded_email
         <p>

    <li> <b>Expires:</b> [util_AnsiDatetoPrettyDate $expires]
"

if { $expire_months < 0} {
    ns_write "    <font color=red>Certificate has <blink>expired</blink></font>"
} elseif { $expire_months < [ad_parameter CertExpireMonthWarning glassroom 2] } {
    ns_write "    <font color=red>Certificate will soon expire</font>"
}


ns_write "
         <p>

</ul>
"


ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"cert-edit.adp?[export_url_vars cert_id]\">Edit</a>
        <p>

   <li> <a href=\"cert-delete.tcl?[export_url_vars cert_id]\">Delete</a>

</ul>

[glassroom_footer]
"


