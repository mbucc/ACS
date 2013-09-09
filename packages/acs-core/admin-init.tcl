ad_library {

    procedures used only in admin pages (mostly the user class stuff)

    @creation-date 18 Nov 1998
    @author Philip Greenspun [philg@arsdigita.com]
    @cvs-id admin-init.tcl,v 1.3.2.1 2000/07/10 18:27:15 yon Exp

}

ad_register_filter preauth * "/admin/*" ad_restrict_to_administrator

if { [ad_ssl_available_p] } {
    set admin_ssl_filters_installed_p 1
    # we'd like to use ad_parameter_all_values_as_list here but can't because 
    # it isn't defined until ad-defs.tcl
    set the_set [ns_configsection "ns/server/[ns_info server]/acs"]
    set filter_patterns [list]
    for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
	if { [ns_set key $the_set $i] == "RestrictToSSL" } {
	    lappend filter_patterns [ns_set value $the_set $i]
	}
    }
    foreach pattern $filter_patterns {
	ad_register_filter preauth GET $pattern ad_restrict_to_https
	ns_log Notice "/tcl/ad-admin.tcl is restricting URLs matching \"$pattern\" to SSL"
    }
}
