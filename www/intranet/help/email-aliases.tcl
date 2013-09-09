# /www/intranet/help/email-aliases.tcl

ad_page_contract {

    Explains the intranet email aliases

    @param short_name If specified, we use this as our example short name

    @author mbryzek@arsdigita.com
    @creation-date Fri Aug 11 12:51:17 2000
    @cvs-id email-aliases.tcl,v 1.1.2.2 2000/09/22 01:38:36 kevin Exp

} {
    { short_name "toolkit" }
    { return_url "" }
}

proc_doc local_im_mail_link { short_name domain { role "" } } {
    Formats the email address in a hyperlink if the EmailDomain
    parameter of the intranet is enabled. Otherwise, returns a simple text
    string.
} { 
    set email "${short_name}[util_decode $role "" "" "-$role"]@$domain"
    if { [empty_string_p [ad_parameter EmailDomain intranet ""]] } {
	return $email
    }
    return "<a href=\"mailto:$email\">$email</a>"
}

set domain [ad_parameter EmailDomain intranet ""]
if { [empty_string_p $domain] } {
    set url [ad_parameter SystemURL]
    regsub {^http://} $url "" url
    regsub {^https://} $url "" url
    set domain "intranet.$url"
}

set page_title "About intranet email aliases"
set context_bar [ad_context_bar_ws "Email aliases"]

doc_return  200 text/html "
[im_header]

You can set up qmail on your box to receive emails sent to your server
and automatically log them with a corresponding project, customer,
partner, or random user group. The idea is to send mail to the
<code>user_groups.short_name@somedomain</code>, and associate the
email messages with the <code>user_groups</code>. This works because
the short_name is unique.  Here's how it works:

<ol>
  <li> Point a domain (like $domain) to the box running your intranet
  <li> Install qmail and pipe all mail to $domain to a perl
script that stuffs the mail into your database. The <a
href=http://software.arsdigita.com/bin>perl scripts</a> to do this
come with acs.
  <li> Use these aliases: (the actual processing is handled through
<a
href=http://software.arsdigita.com/tcl/email-handler-sweeper-procs.tcl>email-handler-sweeper-procs</a>)

  <ul>
    Assume the <code>short_name</code> for our user group is ${short_name}
    <li> [local_im_mail_link $short_name $domain] to simply log the email as a correspondance
    <li> [local_im_mail_link $short_name $domain employees] to log the email as a correspondance and to forward it to all employees associated with the user group
    <li> [local_im_mail_link $short_name $domain customers] to log the email as a correspondance and to forward it to all customers associated with the user group
    <li> [local_im_mail_link $short_name $domain all] to log the email as a correspondance and to forward it to everyone associated with the user group
  </ul>
</ol>

<h3>Configuration</h3>

In addition to installing and configuring QMail, two parameters in the
intranet section must be set in your web server to make email aliases
work: 
<ul>
  <li> Set the <code>EmailDomain</code> parameter to the domain of your server (e.g. $domain)
  <li> Set the <code>LogEmailToGroupsP</code> parameter to 1 to actually log email
send to user group short names.
</ul>

[util_decode $return_url "" "" "<a href=\"$return_url\">Back to where you were</a>"]

[im_footer]
"

