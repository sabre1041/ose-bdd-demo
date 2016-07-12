
'use strict';

/* Module */
var itemDetailsDirective = angular.module('itemDetailsDirective', []);

/* Directives */
itemDetailsDirective.directive('myItemDetails', function(){
	return {
		restrict: 'E',
		transclude: true,
		scope: {
			myItemId: '@myItemId'
		},
		templateUrl: 'app/directives/item-details/item-details-template.html'
	};
});