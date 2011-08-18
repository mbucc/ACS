# domain-add.tcl
# Add a new mail domain.
# Written by jsc@arsdigita.com.

ns_return 200 text/html "[ad_admin_header "Add a Domain"]
<h2>Add a Domain</h2>

[ad_admin_context_bar [list "index.tcl" "WebMail Admin"] "Add Domain"]


<hr>

<form action=\"domain-add-2.tcl\">

Short name should be a short, descriptive name made up only of lower case letters
 (no spaces or punctuation). Example: arsdigita.

<p>

Short Name: <input type=text name=short_name size=20>

<p>

The domain name should be a fully qualified domain name to which mail will get sent.
DNS and qmail must be set up separately to handle mail for this domain.
Example: arsdigita.com.

<p>

Domain Name: <input type=text name=full_name size=50>

<center>
<input type=submit value=\"Add Domain\">
</center>

</form>

[ad_admin_footer]
"
