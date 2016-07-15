"use strict";

var module = angular.module('kie.server.service', []);


module.factory('KieServerService', ['$http',function($http) {

	var service = {
		checkout:checkout
	};
	return service;

	function checkout(cart) {	
	    var kieServerLocationUrl = '/api/v1/rest/checkout';

	    return $http({
		    url: kieServerLocationUrl,
		    method: "POST",
		    headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-KIE-ContentType': 'JSON'
            },
		    data: JSON.stringify(cart)
		}).then(function(response) {
			console.log(response);
			return response;
		},
		function(error){
			console.log(error);
			return null;
		});	
	}
    
    
}]);
