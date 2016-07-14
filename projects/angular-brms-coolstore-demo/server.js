var express = require('express');
var bodyParser = require("body-parser");
var http = require("http");
var app = express();

//Load Environment Variables
var namespace=process.env.KIE_SERVER_NAMESPACE;
var port=process.env.KIE_SERVER_PORT;
var appname=process.env.KIE_SERVER_APP_NAME;
var username=process.env.KIE_SERVER_USER;
var password=process.env.KIE_SERVER_PASSWORD;

//Generate Auth string
var auth = 'Basic ' + new Buffer(username + ':' + password).toString('base64');

//Mount dependencies
app.use(express.static(__dirname+'/'));

//Route everything else to AngularJS frontend
app.get('/*',function(req,res){
	res.sendFile(__dirname+'/app/index.html');
});

//Handle API calls
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.post('/api/v1/rest/checkout', function (req, response) {
	reqString = generateRequestString(req);
	var options = {
	  hostname: appname + '.' + namespace + '.svc.cluster.local',
	  port: port,
	  path: '/kie-server/services/rest/server/containers/instances/default',
	  method: 'POST',
	  headers: {
	      'Content-Type': 'application/json',
	      "X-KIE-ContentType": "JSON",
	      "Authorization": auth,
	  }
	};
	var req = http.request(options, function(res) {
		console.log('Status: ' + res.statusCode);
	  	console.log('Headers: ' + JSON.stringify(res.headers));
		res.setEncoding('utf8');
		res.on('data', function (body) {
			console.log('Body: ' + body);
			response.send(body);
	  	});
	});
	req.on('error', function(e) {
		console.log('problem with request: ' + e.message);
		response.status(500).send('Error contacting kie server');
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
