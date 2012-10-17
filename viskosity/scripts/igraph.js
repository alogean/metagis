/*jslint vars: true, white: true */
/*global jQuery, d3, VISKOSITY */

// interactive graph
VISKOSITY.igraph = (function($) {

"use strict";

var base = VISKOSITY.graph,
	pusher = VISKOSITY.pusher,
	evict = VISKOSITY.evict;

var igraph = Object.create(base);
// `settings.provider` is a function which is used to retrieve additional data -
// it is passed the respective node along with the full data set and a callback,
// to which it should pass an object with arrays for `nodes` and `edges`
igraph.init = function() {
	base.init.apply(this, arguments);
	var settings = arguments[arguments.length - 1];
	this.provider = settings.provider;
	this.history = VISKOSITY.cappedStack(1);
	this.root.on("mousedown", $.proxy(this.toggleHighlight, this));
};
igraph.onClick = function(item) {
	var self = this.graph;
	self.toggleHighlight(this.context);
	var data = { nodes: self.graph.nodes(), edges: self.graph.links() };
	self.provider(item, data, $.proxy(self.addData, self));
};
igraph.toggleHighlight = function(el) { // TODO: rename
	this.root.selectAll(".active").classed("active", false);
	if(el) {
		d3.select(el).classed("active", true);
	}
};
igraph.undo = function() {
	var data = this.history.pop();
	if(!data) {
		return;
	}
	evict(data.nodes, this.graph.nodes());
	evict(data.edges, this.graph.links());
	this.render();
	this.toggleHighlight();
};
igraph.addData = function(data) {
	if(data.nodes.length || data.edges.length) {
		$.each(data.nodes, pusher(this.graph.nodes()));
		$.each(data.edges, pusher(this.graph.links()));
		this.render();
	}
	this.history.push(data);
};

return igraph;

}(jQuery));
