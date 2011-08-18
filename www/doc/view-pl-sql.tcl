#
# /doc/view-pl-sql.tcl
#
# 
#
# Author: michael@arsdigita.com, 2000-03-05
#
# $Id: view-pl-sql.tcl,v 3.1 2000/03/06 05:37:21 michael Exp $
#

ad_page_variables {
    name
    type
}

set db [ns_db gethandle]

set selection [ns_db select $db "select text
from user_source
where name = upper('$name')
and type = upper('$type')
order by line"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append source_text $text
}

ad_return_top_of_page "[ad_header $name]

<h2>$name</h2>

a PL/SQL $type in this installation of <a href=\"\">the ACS</a>

<hr>

<blockquote>
<pre>
$source_text
</pre>
</blockquote>

[ad_footer]
"
