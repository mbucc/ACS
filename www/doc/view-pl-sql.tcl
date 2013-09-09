# /doc/view-pl-sql.tcl
ad_page_contract {
    Returns the specification for a given PL/SQL package, procedure, or
    function.

    @param name
    @param type

    @author Michael Yoon (michael@arsdigita.com)
    @creation-date 2000-03-05
    @cvs-id view-pl-sql.tcl,v 3.3.2.3 2000/08/01 02:02:22 chiao Exp
} {
    name:sql_identifier
    type:sql_identifier
}

set source_text ""

db_foreach source_text "select text
from user_source
where name = upper(:name)
and type = upper(:type)
order by line" {
    append source_text $text
}

doc_body_append "[ad_header $name]

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
db_release_unused_handles