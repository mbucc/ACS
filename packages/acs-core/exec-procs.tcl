ad_library {
    Contains procs used to execute shell commands.
    Works around the AOL Server issue with handling SIGCHLD.
    
    @author Mark Bucciarelli (mkbucc@gmail.com)
    @creation-date 25 October 2013
}


proc_doc -public ad_image_geometry { width height infile outfile } {

    Resize the image at infile and write the new version to outfile.

    Returns the list [rval emsg].  If rval is non-zero, it's an error
    and the error string will be in emsg.  If zero, the image was
    successfully resized.

} {
    set bin [ad_parameter ConvertBinary "general-portraits"]
    set rval [catch {exec $bin -geometry "${width}x${height}" $infile $outfile} emsg opts]
    if { $rval } {
        if { $rval == 1 } {
            #
            # AOL Server has a SIGCHLD handling issue.  No matter
            # what you run inside exec, you get the error:
            #      
            #      error waiting for process to exit: child process lost 
            #      (is SIGCHLD ignored or trapped?)
            #      
            # The SIGCHLD is the signal back to the parent process that
            # the child is done.  Declare victory.
            if { [string equal "ECHILD" [lindex [dict get $opts -errorcode] 1] ] } {
                 set rval  0
                 set emsg ""
            }
        }
        #else 
            # Exec got a return, break or continue signal.  This is still
            # an error, we just don't have the errorcode key in opts.
    }
    return [list $rval $emsg]
}
