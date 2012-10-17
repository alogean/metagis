/*jslint vars: true, unparam: true, white: true */
/*global jQuery, VISKOSITY */

VISKOSITY.skosProvider = (function($) {

"use strict";

var pusher = VISKOSITY.pusher;

var provider = function self(node, data, callback) {
	$.getJSON(node.uri, function(data, status, xhr) {
		data = self.transform(data);
		callback(data);
	});
};

provider.nodeMap = {}; // maps node IDs to the corresponding objects -- XXX: singleton

provider.transform = function(concept) {
	var self = this;
	var nodes = $.map(concept.relations, $.proxy(self.concept2node, self));
	nodes.unshift(this.concept2node(concept));
	nodes = $.map(nodes, function(node) { // filter existing nodes
		if(self.nodeMap[node.id]) {
			return null;
		}
		self.nodeMap[node.id] = node;
		return node;
	});
	// edges must be processed separately to ensure nodes have been registered
	var edges = this.concept2edges(concept);
	$.each(concept.relations, function(i, concept) {
		$.each(self.concept2edges(concept), pusher(edges));
	}); // TODO: filter existing edges
	return { nodes: nodes, edges: edges };
};

provider.concept2node = function(concept) {
	var id = concept.origin;
	var rels = concept.relations;
	var node = {
		id: id,
		uri: "data/" + id + ".json", // XXX: hard-coded
		name: concept.labels[0].value,
		relations: rels.length !== undefined ? rels.length : rels,
		group: 1 // XXX: hard-coded
	};
	return node;
};

provider.concept2edges = function(concept) {
	var self = this;
	var source = this.getNode(concept.origin);
	return $.map(concept.relations, function(rel) {
		var target = self.getNode(rel.origin);
		return {
			source: source,
			target: target,
			value: 1 // XXX: hard-coded
		};
	});
};

provider.getNode = function(id) {
	var node = this.nodeMap[id];
	if(!node) {
		throw "unregistered node: " + id;
	}
	return node;
};

return provider;

}(jQuery));
