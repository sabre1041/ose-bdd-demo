"use strict";

/* Module */

var homeModule = angular.module("homeModule",[]);

/* Config */

/* Controller */

homeModule.controller("HomeCtrl", ["$scope","$http","KieServerService",function($scope,$http,kieSvrSvc) {
	$scope.cart = [];
  $scope.resolvedCart={};
	var jsonString = 
					'{"items": [{"id": 1,"name": "Red Hat Thermos","price": 14.95, "image": "https://lf.staplespromotionalproducts.com/lf?set=scale[300],env[live],output_format[png],sku_number[200231581],sku_dir[200231],view_code[F1]%26call=url[file:san/com/sku.chain]", "description": "BPA/BPS-free polypropylene cup and lid with silicone grip. Flip up closure on lid; barista standard reusable cup; recyclable. Holds 12 oz. Imprint. Gray/Black/Red."},\
								{"id": 2,"name": "Red Hat Golf Polo","price": 55.95, "image": "https://lf.staplespromotionalproducts.com/lf?set=scale[300],env[live],output_format[png],sku_number[200231303],sku_dir[200231],view_code[F1]%26call=url[file:san/com/sku.chain]", "description": "Moisture-wicking, snag resistant, 4.4 oz., 100% micropolyester textured knit. Flat-knit collar; three-button placket with dyed to match buttons; contrast neck tape; shirttail hem. Import. Steel Gray. Transfer."},\
								{"id": 3,"name": "Portable Charger","price": 13.95, "image": "https://lf.staplespromotionalproducts.com/lf?set=scale[300],env[live],output_format[png],sku_number[200231640],sku_dir[200231],view_code[F1]%26call=url[file:san/com/sku.chain]", "description": "Aluminum case holds rechargeable 4,000 mAh lithium-polymer battery. Includes USB to micro USB cable. Charges devices at 1Ah and may not be compatible or ideal for your mobile or tablet device. Please consult your device owners manual to review power consumption requirements.Black. Laser Engrave."},\
								{"id": 4,"name": "Red Hat Swag Box","price": 25.00, "image": "https://lf.staplespromotionalproducts.com/lf?set=scale[300],env[live],output_format[png],sku_number[200234451],sku_dir[200234],view_code[F1]%26call=url[file:san/com/sku.chain]", "description": "Specially designed swag box holds one 16 oz. BPA-free, double-wall tumbler, freezer and top rack dishwasher safe; , with 192 ivory, lined pages; plus a combo pen/stylus. Gift boxed. Imprint. Black."}]}';

  	var itemData=JSON.parse(jsonString);
  	$scope.items=itemData.items;

  	$scope.addToCart = function(item){
  		if($scope.cart.indexOf(item)==-1){
  			$scope.cart.push(item);
  		}
  		
  	}
  	$scope.removeFromCart = function(item){
  		var i = $scope.cart.indexOf(item);
  		if (i > -1) {
    		$scope.cart.splice(i, 1);
		  }
  	}
    
    $scope.checkout = function(){
      console.log("Checkout")
      kieSvrSvc.checkout($scope.cart).then(function(data){
        //Check valid response
        if(!data || !data['data']['result']){
          $scope.resolvedCart={};
        }
        else{
          //Parse out \n from response and convert to JSON obj (defensive check)
          var result = data['data']['result'];
          result = result.replace(/\n/g,"");
          result=JSON.parse(result);
          console.log(result);
          $scope.resolvedCart=result['results'][1]['value']['com.redhat.coolstore.ShoppingCart'];    
        }
        
      });
    }

}]);



