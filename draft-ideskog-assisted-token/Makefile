TITLE=draft-ideskog-assisted-token
VERSION=05
DOC=$(TITLE)-$(VERSION)
XML_DOC=$(DOC).xml
XML_EXP_DOC=$(DOC).exp.xml
HTML_DOC=$(DOC).html
TXT_DOC=$(DOC).txt
METADATA_JS_URL=https://www.rfc-editor.org/js/metadata.min.js
XML2RFC=pipenv run xml2rfc

all: html txt exp

html: $(HTML_DOC)

txt: $(TXT_DOC)

exp: $(XML_EXP_DOC)

$(HTML_DOC): $(XML_DOC)
	$(XML2RFC) --v3 --html --metadata-js-url=$(METADATA_JS_URL) $<

$(TXT_DOC): $(XML_DOC)
	$(XML2RFC) --v3 --text $<

$(XML_EXP_DOC): $(XML_DOC)
	$(XML2RFC) --v3 --expand $<

clean:
	rm -f *.txt *.html *.exp.xml
