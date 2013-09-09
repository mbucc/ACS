# /www/patch/what-to-do.tcl
#
# Eve's opinion on how people should go about patching their sites.
#
# eveander@arsdigita.com, July 5, 2000.
# 
# what-to-do.tcl,v 1.1.2.2 2000/09/22 01:37:24 kevin Exp


doc_return 200 text/html "

<html>
<head><title>How to patch your site</title></head>
<body bgcolor=white text=black>

<h2>How to patch your site</h2>

by <a href=\"http://eve.arsdigita.com/\">Eve Andersson</a>

<hr>
This document tells you how to patch all known security holes in ACS 3.3 and earlier.  It contains two filters and 13 patches, as well as notes on how to fix your custom code.

<p>

<h3>Follow these Steps to Secure Your Site:</h3>

<ol>

<b><li>Prevent users from constructing unauthorized SQL statements.</b>
<p>
<b>The problem:</b> if a programmer forgets to DoubleApos a variable used as part of a SQL
statement (it happens all the time), it is often possible for a user of the site to
pass in fragments of SQL, thereby constructing arbitrary queries that let them get
any information they want from the database.
<p>
<b>The immediate solution:</b> install <a href=\"http://acs-staging.arsdigita.com/doc/core-arch-guide/security-sql-smuggling.html\">Branimir and Carsten's SQL Smuggling Filter</a>.
<p>
<b>The permanent solution:</b> as soon as the new database API is ready in <a href=\"http://www.arsdigita.com/pages/plans/acs-3.4\">ACS 3.4</a> (within the next two weeks) change all queries to use it.  The new API uses bind variables, making it impossible for users to construct SQL.  It also relieves you
of the need to get and release database handles.
<p>
Once all queries have been converted to the new API (you'll know everything is converted as soon as there are no more occurrences of \"set db \" in your code), you can remove Branimir and Carsten's filter (thus saving your server from the hardship of doing a regexp on every single form input passed in).


<p>

<b><li>Prevent users from setting tmpfile during file upload.</b>

<p>

<b>The problem:</b> unless we prevent the user from doing so, the user can set a variable called tmpfile when they're doing a file upload.  The value of tmpfile is supposed to be set by our scripts to be the location where AOLserver temporary places the file upon upload.  Then, typically, tmpfile is copied to a permanent file or to the database.  We don't want the user manually setting tmpfile to /etc/passwd.

<p>

<b>Solution:</b> put the procedure check_for_form_variable_naughtiness (<a href=\"patch12.txt\">Patch 12</a>) into your private tcl directory or into /packages/acs-core/utilities-procs.tcl.  Then, modify all procedures that set variables (<a href=\"patch13.txt\">Patch 13</a>) to use this procedure.

<p>

<b><li>Prevent users from specifying invalid directory names.</b>

<p>
<b>The problem:</b> users may have access to more files in your filesystem than you intended.  If they specify a directory name that contains one or more occurrences of \"../\" -- and if you forget to check for it -- scripts that display (or even \"rm\") files on your server may allow access to or modification of any file that nsadmin has permissions to read, write, and/or execute.
<p>
<b>The immediate solution:</b> install <a href=\"http://evedev.arsdigita.com/patch/dvrfilter.html\">DVR's User Input Filter</a> (this filter will only work after you've installed the procedures in Step 2).  The filters included in the script check the directory names for all known ACS variables that are directories.  However, if your custom module includes user specification of directories, you'll have to add a line like \"ad_set_typed_form_variable_filter /your_module/* {your_variable dirname}\".
<p>
<b>The long-term solution:</b> Chrooting your web server will limit the files that can be accessed.  It's also probably best to keep DVR's script in place long-term because it does a number of useful things in addition to directory name checking.  However, now that the glorious Oracle8i makes it so easy to handle BLOB/CLOB storage, there's not much reason to put files in the file system instead of into Oracle.  We should modify the modules of the ACS (e.g. ecommerce) that store things in the file system and put everything feasible into the database.

<p>

<b><li>Prevent users from executing arbitrary commands in ADP pages.</b>

<p>
<b>The problem:</b> ADP pages allow the execution of any command that can be executed from within a Tcl script.  (This includes commands like \[exec rm ...\].)  Many sites allow users to edit ADP pages.  Even if these users are admin users, you don't want them executing arbitrary SQL statements or shell commands (on some sites, not even administrators are supposed to see the credit card numbers).  Also, you never know how careful administrators are with keeping their passwords private.
<p>
<b>The solution:</b> Disallow command execution in ADP pages.  If you want an ADP page to contain the output of a procedure, set a variable to have that value (which will work as long as the ADP page is ns_adp_parse'd from a Tcl script).  Then the editor of the page can refer to the value of the variable with &lt;%= \$variable_name %&gt;.  The removal of command execution ability is accomplished via <a href=\"patch1.txt\">Patch 1</a>.  Note: your current ADP pages will also have to be edited to remove function calls.  (If you want to be a little less string, modify the patch to include a list of acceptable functions.)

<p>
<b><li>Prevent user_id (and similar variables that are set from cookies) from being overwritten.</b>

<p>

<b>The problem:</b> if you <code>set user_id \[ad_verify_and_get_user_id\]</code> and then, one line later, <code>set_the_usual_form_variables</code>, it is possible that user_id will be overwritten by a form variable called user_id.  This can give the user access to see information and perform actions allowed to a different registered user (e.g., a site administrator).

<p>

<b>The immediate solution:</b> unfortuately a simple filter on the whole site to prevent overwriting of user_id is inadequate because sometimes the user_id from the cookie is set to be admin_id (<bode>set admin_id \[ad_verify_and_get_user_id\]) or something else.  Fortunately, DVR's User Input Script (which you installed in Step 3) contains filters for all known problems of this sort in the ACS.  What about your custom code?  Michael Cleverly has written a very handy shell script, <a href=\"check-sfv.txt\">check-sfv</a>, that will dig through your code and tell you which files pose the possibility of variables being overwritten.   For the files that come up, you can either call <code>set_the_usual_form_variables</code> before setting any other variables, or you can add a DVR filter.

<p>

<b>The long-term solution:</b> We should be using ad_page_variables everywhere.  Not only is it more convenient (you can set default values for unsupplied variables in one step) and self-documenting (each variable is listed as an argument), it's <i>much</i> safer: no variables can be set unless you allow them to be set.

<p>

<b><li>Don't let bad values slip by if ns_queryget is used</b>

<p>

<b>The problem:</b> the naughtiness filter is not applied if form input comes through ns_queryget (an AOLserver function) instead of through our own variable-setting procedures.  Note: Branimir and Carsten's SQL Smuggling Filter <i>will</i> catch dangerous SQL fragments, so we only have to worry about values that are \"naughty\" in some other way.

<p>

<b>The immediate solution:</b> apply <a href=\"patch2.txt\">Patch 2</a> to get rid of the one dangerous ns_queryget in the ACS and grep for occurrences of ns_queryget in your custom code.

<p>

<b>The long-term solution:</b> Avoid or rewrite ns_queryget.

<p>

<b><li>Apply remaining patches.</b>

<p>

These are patches that are not be covered by the above sections, so go ahead and apply them:

<p>

<ul>
<li><a href=\"patch3.txt\">3</a> (ecommerce)
<li><a href=\"patch4.txt\">4</a> (form-manager)
<li><a href=\"patch5.txt\">5</a> (bboard)
<li><a href=\"patch6.txt\">6</a> (search)
<li><a href=\"patch7.txt\">7</a> (search)
<li><a href=\"patch8.txt\">8</a> (bboard)
<li><a href=\"patch9.txt\">9</a> (bboard)
<li><a href=\"patch10.txt\">10</a> (template)
<li><a href=\"patch11.txt\">11</a> (acs-core -- doc/sql)
</ul>


</ol>



<hr>
<a href=\"mailto:eveander@arsdigita.com\">eveander@arsdigita.com</a>
"
