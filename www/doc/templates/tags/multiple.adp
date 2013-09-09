<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Tag Reference: <tt>MULTIPLE</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="include.adp">Previous</a> | 
<a href="var.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>multiple</tt> tag is used to repeat a template section for
each row of a multirow data source.  Datasource variables are reset
with each repetition to the values of the next row of the data source.</p>

<h3>Usage</h3>

<pre><%=[ad_util_get_source "usage/multiple.adp"]%>
</pre>

<h3>Notes</h3>

<p><li>The maxrows attribute may be used to limit the number of rows
that are output from the data source:
</p>

<pre>
  &lt;multiple maxrows="n">
  ...
</pre>

<p>This attribute will terminate processing the data source after the
first <var>n</var> rows have been output.</p>

<p><li>The <tt>%datasource.rownum%</tt> special variable is set
implicitly for each repetition and can be used in conjunction with the
<tt>if</tt> tag to do row banding:

<pre>
  &lt;multiple>

  &lt;if %datasource.rownum% odd>
    &lt;tr bgcolor=#eeeeee>
  &lt;/if>

  &lt;if %datasource.rownum% even>
    &lt;tr bgcolor=#ffffff>
  &lt;/if>

  ...
</pre>

<p><li>The <tt>Last</tt> and <tt>Next</tt> special variables are set
implicitly for each variable and repetition.  They can be used to
create a layout that groups similar rows.  For example, the code to
create a listing of shirts by style and color would look like
this:</p>

<pre><%=[ad_util_get_source "usage/multiple_group.adp"]%>
</pre>

<div align=right><a href="include.adp">Previous</a> | 
<a href="var.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>




