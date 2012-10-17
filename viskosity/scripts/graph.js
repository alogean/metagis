/*jslint vars: true, white: true */
/*global jQuery, d3, VISKOSITY */

VISKOSITY.graph = (function($) {

"use strict";

var prop = VISKOSITY.getProp,
	setContext = VISKOSITY.setContext,
	collide, drawLine, drawArc;

var graph = {
	charge: -500,
	linkDistance: 100,
	linkStrength: 0.5,
	colorize: (function(fn) { // TODO: rename
		return function(item) { return fn(item.group || 0); };
	}(d3.scale.category20())), // XXX: bad default?
	identity: prop("id")
};
// `container` may be a DOM node, selector or jQuery object
// `data` is the initial data set, an object with arrays for `nodes` and `edges`
// `settings` is an optional set of key-value pairs for width and height
graph.init = function(container, data, settings) {
	settings = settings || {};

	// XXX: unnecessary jQuery dependency?
	container = container.jquery ? container : $(container);
	container.addClass("viz");
	this.width = settings.width || container.width();
	this.height = settings.height || container.height();

	this.root = d3.select(container[0]).append("svg").
			attr("width", this.width).attr("height", this.height);
	this.graph = d3.layout.force(). // TODO: (re)calculate settings dynamically to account for graph size
			charge(this.charge).
			linkDistance(this.linkDistance).
			linkStrength(this.linkStrength).
			size([this.width, this.height]);

	this.graph.nodes(data.nodes).links(data.edges);
	this.render();

	this.graph.on("tick", $.proxy(this.onTick, this));
};
graph.onTick = function(ev) {
	var self = this;

	// collision detection
	var nodes = this.graph.nodes();
	var q = d3.geom.quadtree(nodes);
	var i = 0;
	var l = nodes.length;
	while(++i < l) {
		q.visit(collide(nodes[i]));
	}

	this.root.selectAll("path.link").attr("d", function(item) {
		var src = item.source,
			tgt = item.target,
			fn = item.arced ? drawArc : drawLine; // XXX: `arced` undocumented, presentational
		return fn(src, tgt);
	});

	this.root.selectAll("g.node").attr("transform", function(item) {
		// bounding box
		item.x = Math.max(item.size, Math.min(self.width - item.size, item.x));
		item.y = Math.max(item.size, Math.min(self.height - item.size, item.y));
		return "translate(" + item.x + "," + item.y + ")";
	});
};
graph.render = function() { // TODO: rename?
	var edges = this.root.selectAll("line.link").
			data(this.graph.links());
	edges.exit().remove(); // TODO: animate
	edges.enter().
			append("path"). // TODO: customizable appearance
				attr("class", "edge link").
				style("stroke-width", function(item) {
					var value = item.value || 0;
					return Math.sqrt(value * 3);
				});

	var nodes = this.root.selectAll("g.node").
			data(this.graph.nodes(), this.identity);
	nodes.exit().remove(); // TODO: animate
	var newNodes = nodes.enter().
			append("g").attr("class", "node").
			call(this.graph.drag); // XXX: unnecessary!?
	newNodes.append("path").
			attr("d", this.shape()).
			style("fill", this.colorize);
	newNodes.append("a").attr("xlink:href", prop("url")).
			append("text").text(prop("name"));
	nodes.select("text").text(prop("name")); // update existing nodes
	if(this.onClick) {
		newNodes.on("click", setContext(this.onClick, { graph: this }));
	}

	this.graph.start();

	this.root.selectAll("g.node").classed("extensible", function(item) {
		return item.weight < item.relations;
	});
};
graph.shape = function() { // TODO: rename
	return d3.svg.symbol().
			type(function(item) { return item.type || "circle"; }).
			size(function(item) {
				var size = (item.relations || 1) * 10 + 100;
				item.size = Math.sqrt(size); // shape size is in px²
				return size;
			});
};

// adapted from http://mbostock.github.com/d3/talk/20110921/collision.html
collide = function(node) {
	var s = node.size + 16, // TODO: use `getBBox` for actual dimensions
		nx1 = node.x - s,
		nx2 = node.x + s,
		ny1 = node.y - s,
		ny2 = node.y + s;
	return function(quad, x1, y1, x2, y2) {
		if(quad.point && (quad.point !== node)) {
			var x = node.x - quad.point.x,
				y = node.y - quad.point.y,
				l = Math.sqrt(x * x + y * y),
				s = node.size + quad.point.size;
			if(l < s) {
				l = (l - s) / l * 0.5;
				node.x -= x *= l;
				node.y -= y *= l;
				quad.point.x += x;
				quad.point.y += y;
			}
		}
		return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
	};
};

drawLine = function(src, tgt) {
	return "M" + src.x + "," + src.y + "L" + tgt.x + "," + tgt.y;
};
drawArc = function(src, tgt) {
	var dx = tgt.x - src.x,
		dy = tgt.y - src.y,
		dr = Math.sqrt(dx * dx + dy * dy);
	return "M" + src.x + "," + src.y + "A" + dr + "," + dr +
			" 0 0,1 " + tgt.x + "," + tgt.y;
};

return graph;

}(jQuery));
