<%
# user-search.adp -- allow searching for an individual user
#
# required arguments - the text of what user to look for,
#                      the ultimate page to redirect back to

# assumes that it's being invoked as ns_adp_includ -sameframe ...
# also assumes that it's the first HTML to be written and that
# ns_adp_break will be called afterwards

if { [ns_adp_argc] != 6 } {
    ns_log error "wrong number of arguments passed to user-search.adp.  Expected Looking_for text, search token, target page for search results, list for navigation bar, and passthrough values"
    ns_adp_aabort
}

ns_adp_bind_args looking_for search_token target nav_list passthrough

# emit the page contents


ns_puts "
[ad_header "Search for $looking_for"]
<h2>Search for $looking_for</h2>
in [ad_context_bar [list index.tcl Glassroom] $nav_list "Search for $looking_for"]
<hr>
Locate $looking_for by

<form method=get action=\"/user-search.tcl\">
[export_entire_form]
<input type=hidden name=passthrough value=\"$passthrough\">
<input type=hidden name=target value=\"$target\">
<input type=hidden name=search_token value=\"$search_token\">
"
%>

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>

<center>
<input type=submit value="Search">
</center>
</form>

<%= [glassroom_footer] %>
