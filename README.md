# Setup and Editing 

1. Install `xml2rfc` by doing `pip install --user xml2rfc`
2. Open the XML document in Intellij.
3. Add a new Python run configuration using the following settings:
    
    * *Script path* the path to `xml2rfc` (e.g., `/Users/user22/Library/Python/2.7/bin/xml2rfc`)
    * *Parameters* should be `--html whatever.xml` (e.g., `--html assisted-token-rfc.xml`)
    * Pick an interpreter from the `Python interpreter` section
    
4. When the XML of the RFC draft has changed, just run the Python configuration (`^R`)      