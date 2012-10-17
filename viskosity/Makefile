.PHONY: dependencies

jquery_version = 1.8

download = \
	curl --output $(1) --time-cond $(1) --remote-time $(2)

dependencies:
	mkdir -p lib
	$(call download, "lib/jquery.js", \
		"http://ajax.googleapis.com/ajax/libs/jquery/$(jquery_version)/jquery.min.js")
	$(call download, "lib/d3.js", "http://d3js.org/d3.v2.min.js")
	$(call download, "lib/d3_pack.css", "http://mbostock.github.com/d3/ex/pack.css")
