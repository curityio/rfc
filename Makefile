PIPEFILE=$(PWD)/Pipfile

all:
	export PIPENV_PIPFILE=$(PIPEFILE)
	cd draft-ideskog-assisted-token && $(MAKE) -e
	cd draft-spencer-oauth-claims && $(MAKE) -e

html:
	export PIPENV_PIPFILE=$(PIPEFILE)
	cd draft-ideskog-assisted-token && $(MAKE) -e html
	cd draft-spencer-oauth-claims && $(MAKE) -e html

txt:
	export PIPENV_PIPFILE=$(PIPEFILE)
	cd draft-ideskog-assisted-token && $(MAKE) -e txt
	cd draft-spencer-oauth-claims && $(MAKE) -e txt

clean:
	cd draft-ideskog-assisted-token && $(MAKE) clean
	cd draft-spencer-oauth-claims && $(MAKE) clean	