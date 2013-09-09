# /www/bboard/search-pls-default-main.tcl
ad_page_contract {
    search page for PLS search

    @cvs-id search-pls-default-main.tcl,v 3.3.2.3 2000/09/22 01:36:54 kevin Exp
} {
    query_string:notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

doc_return  200 text/html "
[bboard_header "Search Results Default Main"]

<h2>Search Results</h2>

from looking through 
<a href=\"main-frame?[export_url_vars topic topic_id]\" target=\"_top\">
the \"$topic\" BBoard
</a>
for \"$query_string\"

<hr>

The full text index covers the subject line, body, email address, and
name fields of each posting.

<p>

If the results above aren't what you had in mind, then you can refine
your search...

<p>

<form method=GET action=search-pls target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40 value=\"$query_string\">
</form>

[bboard_footer]"
