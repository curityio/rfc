all:
	cd draft-ideskog-assisted-token && $(MAKE)
	cd draft-spencer-oauth-claims && $(MAKE)

html:
	cd draft-ideskog-assisted-token && $(MAKE) html
	cd draft-spencer-oauth-claims && $(MAKE) html

txt:
	cd draft-ideskog-assisted-token && $(MAKE) txt
	cd draft-spencer-oauth-claims && $(MAKE) txt