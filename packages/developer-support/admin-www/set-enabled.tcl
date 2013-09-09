# File:        set-enabled.tcl
# Package:     developer-support
# Author:      jsalz@mit.edu
# Date:        22 June 2000
# Description: Enables or disables developer support data collection.
#
# set-enabled.tcl,v 1.1.4.1 2000/07/14 04:51:43 jsalz Exp

ad_page_variables {
    enabled_p
}

nsv_set ds_properties enabled_p $enabled_p
ad_returnredirect "index"
