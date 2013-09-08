# developer-support-init.tcl,v 1.5.2.2 2000/07/14 04:51:41 jsalz Exp
# File:        developer-support-init.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        22 Apr 2000
# Description: Provides routines used to aggregate request/response information for debugging.

ad_register_filter -critical t -priority 999999 trace * /* ds_trace_filter
ad_schedule_proc [ad_parameter DataSweepInterval "developer-support" 900] ds_sweep_data
nsv_array set ds_request [list]

nsv_set ds_properties enabled_p [ad_parameter EnabledOnStartupP developer-support 0]
nsv_set ds_properties enabled_ips [ad_parameter_all_values_as_list EnabledIPs developer-support]
