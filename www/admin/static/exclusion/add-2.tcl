# $Id: add-2.tcl,v 3.0.4.1 2000/04/28 15:09:23 carsten Exp $
#
# /admin/static/exclusion/add-2.tcl
#
# by philg@mit.edu on November 6, 1999
#
# inserts a row into the static_page_index_exclusion table
#

set_the_usual_form_variables

# match_field, like_or_regexp, pattern, pattern_comment

set db [ns_db gethandle]

ns_db dml $db "insert into static_page_index_exclusion
(exclusion_pattern_id, match_field, like_or_regexp, pattern, pattern_comment, creation_user, creation_date)
values
(static_page_index_excl_seq.nextval, '$QQmatch_field', '$QQlike_or_regexp', '$QQpattern', '$QQpattern_comment', [ad_verify_and_get_user_id], sysdate)"

ad_returnredirect "/admin/static/"
