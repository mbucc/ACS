import java.io.*;
import java.net.*;
import java.sql.*; 
import java.math.*;
import java.util.*;

import org.w3c.dom.*;

import oracle.sql.*;
import oracle.xml.parser.v2.*;
import oracle.jdbc.driver.*;
 
public abstract class XMLPublisher { 

  private static PreparedStatement xslStmt, xmlStmt;

  private static String xslQueryString = 
    "select doc from xsldocs where doc_name = ?";
  private static String xmlQueryString =
    "select doc from xmldocs where doc_id = ?";

  static {

    try {  

      Connection conn = new OracleDriver().defaultConnection();
      xslStmt = conn.prepareStatement(xslQueryString);
      xmlStmt = conn.prepareStatement(xmlQueryString);

    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public static void applyXSL(int doc_id, String xslName) throws Exception {

    // Read in the XML document

    xmlStmt.setInt(1, doc_id);

    ResultSet rs = xmlStmt.executeQuery();
    
    if (! rs.next())
      throw new Exception("Could not access CLOB");

    oracle.sql.CLOB clob = (CLOB) rs.getObject(1);

    Reader in = clob.getCharacterStream();

    DOMParser parser = new DOMParser();
    parser.parse(in);
    in.close();
    rs.close();

    XMLDocument xml = parser.getDocument();

    // Apply the XSL transformation

    xml = applyXSL(xml, xslName);

    // Write the transformed document back to the temporary table

    rs = xmlStmt.executeQuery();
    rs.next();
    clob = (CLOB) rs.getObject(1);

    Writer writer = clob.getCharacterOutputStream();
    PrintWriter pw = new PrintWriter(writer);
    xml.print(pw);
    writer.flush();
    writer.close();
    rs.close();
  }

  public static XMLDocument applyXSL(XMLDocument xml, String xslName) 
    throws Exception {

    XSLStylesheet xsl = getXSLStylesheet(xslName);

    return applyXSL(xml, xsl);
  }

  public static XMLDocument applyXSL(XMLDocument xml, XSLStylesheet xsl) 
    throws Exception {

    XSLProcessor processor = new XSLProcessor();

    processor.showWarnings(true);
    processor.setErrorStream(System.err);

    DocumentFragment result = processor.processXSL(xsl, xml);

    XMLDocument out = new XMLDocument();

    Element root = out.createElement("html");
    out.appendChild(root);

    root.appendChild(result);
    
    return out;
  }

  public static XSLStylesheet getXSLStylesheet(String name)
    throws Exception {

    xslStmt.setString(1, name);
    Reader in = readOneCLOB(xslStmt);

    URL xslURL = 
      new URL("http://w3.org/XSL/Transform/1.0/" + name);

    XSLStylesheet xsl = new XSLStylesheet(in, xslURL);

    in.close();

    return xsl;
  }

  private static Reader readOneCLOB(PreparedStatement stmt) 
    throws Exception {

    ResultSet rs = stmt.executeQuery();
    
    if (! rs.next())
      throw new Exception("Could not access CLOB");

    oracle.sql.CLOB clob = (CLOB) rs.getObject(1);
    Reader in = clob.getCharacterStream();

    rs.close();

    return in;
  }
}









