# $Id: update-adv.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables

# adv_key, target_url, adv_filename

set db [ns_db gethandle]

ns_db dml $db "update advs set 
target_url='$QQtarget_url',
adv_filename='$QQadv_filename',
local_image_p='$QQlocal_image_p'
where adv_key='$QQadv_key'"

ad_returnredirect one-adv.tcl?adv_key=$adv_key

