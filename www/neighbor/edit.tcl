# /www/neighbor/edit.tcl
ad_page_contract {
    Allows a user to edit their neighbor-to-neighbor entries.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id edit.tcl,v 3.4.2.2 2000/09/22 01:38:55 kevin Exp
} {}

set user_id [ad_maybe_redirect_for_registration]

set page_content "[neighbor_header "Your postings"]

<h2>Your postings</h2>

in <a href=index>[neighbor_system_name]</a>

<hr>

<ul>
"

set sql_query "
    select neighbor_to_neighbor_id, about, one_line, posted
      from neighbor_to_neighbor
     where poster_user_id = :user_id
  order by posted desc"

db_foreach select_entires $sql_query {
    append page_content "<li><a href=\"edit-2?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$about : $one_line</a> (posted $posted)\n"
}

append page_content "</ul>

[neighbor_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content