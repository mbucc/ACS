# $Id: merge-from-search.tcl,v 3.0.4.1 2000/04/28 15:09:38 carsten Exp $
#
# merge-from-search.tcl
# 
# by philg@mit.edu on October 30, 1999
#
# exists to redirect to merge.tcl after /user-search.tcl
# or /admin/users/search.tcl 

set_the_usual_form_variables 

# u1, user_id_from_search

ad_returnredirect "merge.tcl?u1=$u1&u2=$user_id_from_search"
