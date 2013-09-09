# /www/admin/acceptance-tests/vc.tcl

ad_page_contract {

    Acceptance tests for the version-control module

    @author  ron@arsdigita.com
    @created Fri Aug  4 04:41:29 2000
    @cvs-id  vc.tcl,v 1.1.2.1 2000/08/04 09:34:30 ron Exp
}

set page_title "Version Control Acceptance Tests"

# Run various tests using the top-level readme file 

set path [file join [acs_root_dir] readme.txt]

ReturnHeaders

ns_write "
[ad_header $page_title]

<h2>$page_title</h2>

for the ArsDigita Community System
<hr>

<p>The following tests are all run using:

<blockquote>
<pre>
path = $path 
</pre>
</blockquote>

<p>If the version-control module is functioning correctly then you
will see a series of results from vc procedures followed by a success
message.  If there is any problem you should be prompted to submit a
bug report.</p>


<h3>Parameters</h3>

<pre>
CVSROOT=[ad_parameter CVSROOT vc]
CvsPath=[ad_parameter CvsPath vc]
</pre>

<h3>Utilities</h3>

<pre>
vc_path_relative    = [vc_path_relative $path]
vc_path_to_module   = [vc_path_to_module $path]
vc_fetch_repository = [vc_fetch_repository $path]
vc_fetch_root       = [vc_fetch_root $path]
vc_fetch_summary    = [vc_fetch_summary $path]
vc_fetch_date       = [vc_fetch_date $path]
vc_fetch_revision   = [vc_fetch_revision $path]
</pre>

<h3>CVS Wrappers</h3>

<pre>
vc_status = 
[vc_status $path]

vc_log = [vc_log $path]
</pre>

<center>
<h3>All tests passed successfully</h3>
</center>

[ad_footer]
"

