'use strict';

/* Bootstrapping app's modules */

var app = angular.module('coolstoreApp', [
	'homeModule',
	'ngRoute',
	'kie.server.service',
	'itemDetailsDirective'
]);

app.config(['$routeProvider',function($routeProvider){
	$routeProvider
		.when('/',{
			templateUrl: 'app/templates/home.html',
			controller: 'HomeCtrl',
			controllerAs: 'homeCtrl'
		});
}])
