#
# This no longer does anything and instead redirects to 
# index.tcl which does all the things project top did.
#

# Original inputs were -- 
#
# form vars:
# project_id
#
# (these are all optional args which have defaults)
#
# filter conditions
#
# Assignments:
# view_assignment    { user unassigned all }
#
# Status:
# view_status  { open closed deferred created_by_you }
#
# Creation time
# view_created { last_24 last_week last_month all}
#
#
# order_by       column name to sort table by

# set_form_variables

ad_returnredirect {/ticket/index.tcl}
