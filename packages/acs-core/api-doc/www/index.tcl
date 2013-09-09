ad_page_contract {
    
    Offers links to other pages, and lets the user type the name of a specific procedure.
    
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @cvs-id index.tcl,v 1.1.4.12 2000/07/27 21:47:54 tnight Exp
} {}

doc_body_append "
[ad_header "API Browser"]
<h2>API Browser</h2>
[ad_context_bar_ws_or_index "API Browser"]
<hr>

<table align=right border=0 cellspacing=0 cellpadding=15 bgcolor=#DDDDDD> 
"

doc_body_append "
<tr><td>
<form action=proc-search method=get>
<table><tr><td valign=top>
   <b>ACS API Search:</b><br>
   <input type=text name=query_string><br>
   <input type=submit value=Search name=search_type>
   <input type=submit value=\"Feeling Lucky\" name=search_type><br>
   <a href=proc-browse>Browse ACS API</a><br>

 </td>
 <td><font size=-1>
     <table cellspacing=0 cellpadding=0>
      <tr><td align=right>Name:</td>
          <td><input type=checkbox name=name_weight value=5 checked> </td>
      <tr><td align=right>Parameters:</td>
          <td><input type=checkbox name=param_weight value=3 checked></td>
      <tr><td align=right>Documentation:</td>
          <td><input type=checkbox name=doc_weight value=2 checked></td>
      <tr><td align=right>Source:</td>
          <td><input type=checkbox name=source_weight value=1></td>
      </tr></font>
      </table>
 </td>
</form></table>

  <form action=tcl-proc-view method=get>
  <b>AOL Server API EXACT procedure name:</b><br>
  <input type=text name=tcl_proc>
  <input type=submit value=Go><br>
  </form>

</td>
</tr>
</form>
</td>
</table>


<h3>Installed Enabled Packages</h3>
<ul>
"

db_foreach installed_packages "
    select version_id, package_name, version_name
    from apm_package_version_info
    where installed_p = 't'
    and   enabled_p = 't'
    order by upper(package_name)
" {
    doc_body_append "<li><a href=\"package-view?version_id=$version_id\">$package_name $version_name</a>\n"
}

doc_body_append "
</ul>
<h3>Disabled Packages</h3>
<ul>
"

db_foreach installed_packages "
    select version_id, package_name, version_name
    from apm_package_version_info
    where installed_p = 't'
    and   enabled_p = 'f'
    order by upper(package_name)
" {
    doc_body_append "<li>$package_name $version_name\n"
}

doc_body_append "
</ul>
<h3>Uninstalled Packages</h3>
<ul>
"

db_foreach installed_packages "
    select version_id, package_name, version_name
    from apm_package_version_info
    where installed_p = 'f'
    and   enabled_p = 'f'
    order by upper(package_name)
" {
    doc_body_append "<li>$package_name $version_name\n"
}

doc_body_append "</ul>
<br clear=all>

[ad_footer]
"

