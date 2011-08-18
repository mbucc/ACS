# $Id: more.tcl,v 3.0.4.1 2000/04/28 15:09:39 carsten Exp $
set_the_usual_form_variables

# idea_id, more_url

ad_returnredirect $more_url

ns_conn close 

# we're offline as far as the user is concerned but let's log the click

set db [banner_ideas_gethandle]

ns_db dml $db "update bannerideas 
set clickthroughs = clickthroughs + 1
where idea_id = $idea_id"


