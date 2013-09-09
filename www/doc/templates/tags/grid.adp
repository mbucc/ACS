<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Tag Reference: <tt>GRID</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right>
<a href="if.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>grid</tt> tag is used to output each row of a multirow
datasource as a cell of an <var>n</var> column grid.</p>

<h3>Usage</h3>

<pre><%=[ad_util_get_source "usage/grid.adp"]%>
</pre>

<h3>Notes</h3>

<p><li>Rows from the data source are output in column-first order.
For example, if a datsource has 10 datasources and the grid has 3
columns, the rows from the datasource will appear in the following
order:</p>

<p>
<table cellpadding=2 cellspacing=0 border=1 bgcolor=#eeeeee>
<tr>  <td width=30>1</td>  <td width=30>5</td>  <td width=30>9</td></tr>
<tr>  <td width=30>2</td>  <td width=30>6</td>  <td width=30>10</td></tr>
<tr>  <td width=30>3</td>  <td width=30>7</td>  <td width=30>&nbsp;</td></tr>
<tr>  <td width=30>4</td>  <td width=30>8</td>  <td width=30>&nbsp;</td></tr>
</table>
</p>

<p><li>The <tt>%datasource.row%</tt> variable can be used to band grid
rows:

<pre>
  &lt;if %datasource.col% eq 1 and %datasource.row% odd>
    &lt;tr bgcolor=#eeeeee>
  &lt;/if>

  &lt;if %datasource.col% eq 1 and %datasource.row% even>
    &lt;tr bgcolor=#ffffff>
  &lt;/if>
</pre>

Note that this is different from the <tt>multiple</tt> tag, where
the <tt>%datasource.rownum%</tt> is used for this effect.</p>

<div align=right>
<a href="if.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>


