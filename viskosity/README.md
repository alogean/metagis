ViSKOSity - visual SKOS browser
https://github.com/innoq/viskosity


Getting Started
===============

* `make dependencies` downloads third-party libraries
* open `index.html`


Architecture
============

* `graph.js` provides the basic visualization, based on [D3](http://d3js.org)
* `igraph.js` extends this module to provide interactive features
* data retrieval occurs through so-called providers - this adapter mechanism is
  documented in `sample_provider.js`


License
=======

Copyright 2012 innoQ Deutschland GmbH

Licensed under the Apache License, Version 2.0
