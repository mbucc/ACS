# /www/admin/comments/index.tcl

ad_page_contract {
    @param none

    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:34:32 kevin Exp
} {
    
}


if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

set day_list {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21}

set html "[ad_admin_header "Comments on Static Pages"]

<h2>Comments</h2>

[ad_admin_context_bar "Comments"]

<hr>

<ul>
<li><form action=recent method=post>
last
<select name=num_days>
[ad_generic_optionlist $day_list $day_list 7]
</select> days <input type=submit name=submit value=\"Go\">
</form>
<li><a href=\"by-page\">by page</a>
<li><a href=\"by-user\">by user</a>
<li><a href=\"recent?num_days=all\">all</a>
<p>

<form method=GET action=\"find\">
<li>Search for substring: <input type=text name=query_string size=30>
</form>

</ul>

"



# -- comment_type is generally one of the following:
# --   alternative_perspective
# --   private_message_to_page_authors 
# --   rating
# --   unanswered_question

db_1row count_types "
  select
  count(*) as n_total, 
  sum(decode(comment_type,'alternative_perspective',1,0)) as n_alternative_perspectives, 
  sum(decode(comment_type,'rating',1,0)) as n_ratings,
  sum(decode(comment_type,'unanswered_question',1,0)) as n_unanswered_questions,
  sum(decode(comment_type,'private_message_to_page_authors',1,0)) as n_private_messages
from comments"

append html "
<h3>Statistics</h3>

<ul>
<li>private messages:  $n_private_messages
<li>unanswered questions:  <a href=\"by-page?only_unanswered_questions_p=1\">$n_unanswered_questions</a>
<li>ratings:  $n_ratings
<li>alternative perspectives:  $n_alternative_perspectives

<p>
<li>total:  $n_total

</ul>

Note that these are only comments on <a href=\"/admin/static/\">static .html pages</a>.  If
you want to view comments on other commentable items, e.g., news or calendar postings, visit
<a href=\"/admin/general-comments/\">the general comments admin pages</a>.

[ad_admin_footer]
"




doc_return  200 text/html $html