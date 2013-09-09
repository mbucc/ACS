# /admin/reload/source-file.tcl

ad_page_contract {
    Re-sources a file in the /tcl directory.

    @author Mark Dettinger (mdettinger@arsdigita.com)
    @creation-date 2 August 2000
    @cvs-id source-file.tcl,v 1.1.2.1 2000/08/02 18:40:52 mdetting Exp
    @param file  the name of the file to re-source
} {
    file
}

ns_eval [list source [ad_parameter PathToACS]/tcl/$file]
ad_returnredirect /reload
