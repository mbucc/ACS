# $Id: toggle-approved-p.tcl,v 3.0.4.1 2000/04/28 15:08:27 carsten Exp $
# File:     admin/calendar/post-edit.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  calendar item approval toggle page

set_form_variables 0

# calendar_id

set db [ns_db gethandle]

ns_db dml $db "update calendar set approved_p = logical_negation(approved_p) where calendar_id = $calendar_id"

ad_returnredirect "item.tcl?calendar_id=$calendar_id"

