# $Id: add-adv-2.tcl,v 3.0.4.1 2000/04/28 15:08:22 carsten Exp $
set_the_usual_form_variables
# adv_key, target_url, local_image_p, track_clickthru_p, adv_filename

set db [ns_db gethandle]

ns_db dml $db "insert into advs (adv_key, target_url, local_image_p, track_clickthru_p, adv_filename) VALUES ('$QQadv_key', '$QQtarget_url', '$QQlocal_image_p', '$QQtrack_clickthru_p', '$QQadv_filename')"

ad_returnredirect one-adv.tcl?adv_key=$adv_key