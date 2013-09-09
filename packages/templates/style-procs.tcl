# /packages/templates/style-procs.tcl
ad_library {

  Determines the URL of a stylized version of the current template,
  and initializes the data for that template.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id style-procs.tcl,v 1.2.2.1 2000/07/18 21:53:28 seb Exp

}

# NB: This is merely a demonstration of how style application works
# No endorsements made for the naming convention used here.

proc ad_template_apply_style { spec urlvar } {

  upvar $urlvar url

  if { $spec == "" } { return }

  ad_util_set_variables $spec style

  if [string match $style {}] { return }

  global errMsg

  if [catch {

    set suffix [eval "uplevel #0 { eval \"$style\" }"]

  } errMsg] {

    error TEMPLATE_STYLE_SELECTION_FAILED
  }

  regsub {\.adp$} $url "-$suffix.adp" style_url

  if { [file exists [ns_url2file $style_url]] } {

    set url $style_url
    ad_template_init url
  }
}

