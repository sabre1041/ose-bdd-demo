var express = require('express');
var bodyParser = require("body-parser");
var http = require("http");
var app = express();
var hostname="localhost";
var port=8080;
var containerName="coolstore3";

//TODO
//Figure out Basic Auth

//Mount dependencies
app.use(express.static(__dirname+'/'));

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

//Route everything else to AngularJS frontend
app.get('/*',function(req,res){
	res.sendFile(__dirname+'/app/index.html');
});

//Handle API calls
app.post('/api/v1/rest/checkout', function (req, res) {
	reqString = generateRequestString(req);
	console.log(reqString);

	var options = {
	  hostname: hostname,
	  port: port,
	  path: '/kie-server/services/rest/server/containers/instances/'+containerName,
	  method: 'POST',
	  headers: {
	      'Content-Type': 'application/json',
	      "X-KIE-ContentType": "JSON",
	      "Authorization": "Basic YnBtc0FkbWluOmpib3NzMDAk"
	  }
	};
	var req = http.request(options, function(res) {
		console.log('Status: ' + res.statusCode);
	  	console.log('Headers: ' + JSON.stringify(res.headers));
	  	console.log(res);
		res.setEncoding('utf8');
		res.on('data', function (body) {
			console.log('Body: ' + body);
	  	});
	});
	req.on('error', function(e) {
		console.log('problem with request: ' + e.message);
	});
	req.write(reqString);
	req.end();

});

app.listen(8080, function () {
	console.log("Started coolstore-app listening on port 8080");
});



function generateRequestString(req){
	var commands = [];
	for(var i=0;i<req.body.length;i++){
		var item=req.body[i];
		var objectToInsert={
			"com.redhat.coolstore.ShoppingCartItem":
				{
					"quantity":1,
					"price":item.price,
					"name":item.name,
					"itemId":item.id,
					"promoSavings":0
				}
		}
		commands.push({"insert":{"object":objectToInsert}});
		
	}
	var shoppingCartToInsert = {
		"com.redhat.coolstore.ShoppingCart": {
						"shippingTotal": 0,
						"cartTotal": 0,
						"shippingPromoSavings": 0,
						"cartItemPromoSavings": 0,
						"cartItemTotal": 0
					}
			}
	commands.push({"insert":{"out-identifier":"shoppingCart","object":shoppingCartToInsert}})
	commands.push({"start-process":{"processId":"com.redhat.coolstore.PriceProcess"}});
	commands.push({"fire-all-rules": ""});

	var request = {};
	request.lookup="defaultStatelessKieSession";
	request.commands=commands;
	return JSON.stringify(request);
}
