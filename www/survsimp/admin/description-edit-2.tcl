#
# /survsimp/admin/description-edit-2.tcl
#
# by jsc@arsdigita.com, February 16, 2000
#
# Carry out the edit, return user to the main survey page.
#
# $Id: description-edit-2.tcl,v 1.1.4.2 2000/04/28 15:11:31 carsten Exp $

ad_page_variables {survey_id description}

set db [ns_db gethandle]

ns_db dml $db "update survsimp_surveys set description = '$QQdescription' where survey_id = $survey_id"

ad_returnredirect "one.tcl?[export_url_vars survey_id]"