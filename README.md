# Setup and Editing 

There are two ways to view this document: 

1. As an XML document directly in Firefox
2. By converting it using the same tool that the IETF uses

## Using Firefox

To use Firefox, just open the XML file directly. It will use the referenced XSLT to style the document. If it doesn't, you may need to access `about:config` and set `security.fileuri.strict_origin_policy` to `false`. The rendered result will not look the same way as an RFC published by the IETF. To get that look, you need to use `xml2rfc`.

## Using `xml2rfc`

1. Install `xml2rfc` by doing `pip install --user xml2rfc`
2. Open the XML document in Intellij.
3. Add a new Python run configuration using the following settings:
    
    * *Script path* the path to `xml2rfc` (e.g., `/Users/user22/Library/Python/2.7/bin/xml2rfc`)
    * *Parameters* should be `--html --text whatever.xml` (e.g., `--html draft-ideskog-assisted-token-00.xml`)
    * Pick an interpreter from the `Python interpreter` section
    
4. When the XML of the RFC draft has changed, just run the Python configuration (`^R`)      