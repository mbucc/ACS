ad_library {
    Initialization code for the APM administration interface.
    @author jsalz@arsdigita.com
    @date 19 April 2000
    @cvs-id apm-admin-init.tcl,v 1.5.2.1 2000/07/10 00:46:38 bquinn Exp

}

ad_register_proc * /admin/apm/packages apm_serve_tarball
ad_register_proc * /admin/apm/archive  apm_serve_archive
ad_register_proc * /apm/doc            apm_serve_docs /apm/doc

rp_register_directory_map apm acs-core apm
