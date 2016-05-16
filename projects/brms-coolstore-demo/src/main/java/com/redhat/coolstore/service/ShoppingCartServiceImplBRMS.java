package com.redhat.coolstore.service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.ejb.Stateful;
import javax.inject.Inject;

import org.kie.api.command.BatchExecutionCommand;
import org.kie.api.command.Command;
import org.kie.internal.command.CommandFactory;
import org.kie.internal.runtime.helper.BatchExecutionHelper;
import org.kie.server.api.marshalling.MarshallingFormat;
import org.kie.server.api.model.ServiceResponse;
import org.kie.server.client.KieServicesConfiguration;
import org.kie.server.client.KieServicesFactory;
import org.kie.server.client.RuleServicesClient;

import com.redhat.coolstore.PromoEvent;
import com.redhat.coolstore.Promotion;
import com.redhat.coolstore.ShoppingCart;
import com.redhat.coolstore.ShoppingCartItem;

@Stateful
public class ShoppingCartServiceImplBRMS implements ShoppingCartService, Serializable {

	private static final long serialVersionUID = 6821952169434330759L;

	
	@Inject
	private PromoService promoService;
	
	private static final String SERVICE_CONTEXT = "kie-server/services/rest/server";
	
	private String kieHost;
	private String kieUser;
	private String kiePassword;

	public ShoppingCartServiceImplBRMS() {

	}
	
	@PostConstruct()
	public void init() {
		String kieAppName = (System.getenv("KIE_SERVER_APP_NAME") == null) ? "coolstore" : System.getenv("KIE_SERVER_APP_NAME");
		String kieNamespace = (System.getenv("KIE_SERVER_NAMESPACE") == null) ? "coolstore-bdd" : System.getenv("KIE_SERVER_NAMESPACE");
		String kiePort = (System.getenv("KIE_SERVER_PORT") == null) ? "8080" : System.getenv("KIE_SERVER_PORT");
		
		kieUser = (System.getenv("KIE_SERVER_USER") == null) ? "admin" : System.getenv("KIE_SERVER_USER");
		kiePassword = (System.getenv("KIE_SERVER_PASSWORD") == null) ? "admin" : System.getenv("KIE_SERVER_PASSWORD");
		
		kieHost = String.format("http://%s.%s.svc.cluster.local:%s/%s", kieAppName, kieNamespace, kiePort, SERVICE_CONTEXT);
		

	}

	@Override
	public void priceShoppingCart(ShoppingCart sc) {

		if (sc != null) {

			ShoppingCart factShoppingCart = new ShoppingCart();

			factShoppingCart.setCartItemPromoSavings(0d);
			factShoppingCart.setCartItemTotal(0d);
			factShoppingCart.setCartTotal(0d);
			factShoppingCart.setShippingPromoSavings(0d);
			factShoppingCart.setShippingTotal(0d);
			
			// HelloRulesClient.java
			KieServicesConfiguration config = KieServicesFactory.newRestConfiguration(
					kieHost, kieUser,
					kiePassword);
			config.setMarshallingFormat(MarshallingFormat.XSTREAM);
			RuleServicesClient client = KieServicesFactory.newKieServicesClient(config)
					.getServicesClient(RuleServicesClient.class);
			List<Command> commands = new ArrayList<Command>();

			// if at least one shopping cart item exist
			if (sc.getShoppingCartItemList().size() > 0) {

				for (Promotion promo : promoService.getPromotions()) {

					PromoEvent pv = new PromoEvent(promo.getItemId(), promo.getPercentOff());

					commands.add(CommandFactory.newInsert(pv));

				}

				commands.add(CommandFactory.newInsert(factShoppingCart, "shoppingCart"));

				for (ShoppingCartItem sci : sc.getShoppingCartItemList()) {

					com.redhat.coolstore.ShoppingCartItem factShoppingCartItem = new com.redhat.coolstore.ShoppingCartItem();
					factShoppingCartItem.setItemId(sci.getProduct().getItemId());
					factShoppingCartItem.setName(sci.getProduct().getName());
					factShoppingCartItem.setPrice(sci.getProduct().getPrice());
					factShoppingCartItem.setQuantity(sci.getQuantity());
					factShoppingCartItem.setShoppingCart(factShoppingCart);
					factShoppingCartItem.setPromoSavings(0d);

					commands.add(CommandFactory.newInsert(factShoppingCartItem));

				}

				commands.add(CommandFactory.newStartProcess("com.redhat.coolstore.PriceProcess"));
				commands.add(CommandFactory.newFireAllRules());
				BatchExecutionCommand myCommands = CommandFactory.newBatchExecution(commands,
						"defaultStatelessKieSession");
				System.out.println(BatchExecutionHelper.newXStreamMarshaller().toXML(myCommands));
				ServiceResponse<String> response = client.executeCommands("default", myCommands);
				System.out.print(response.getResult());
				System.out.print(response.getMsg());
				
				
				sc.setCartItemTotal(getValueFromXml(response.getResult(), "cartItemTotal"));
				sc.setCartItemPromoSavings(getValueFromXml(response.getResult(), "cartItemPromoSavings"));
				sc.setShippingTotal(getValueFromXml(response.getResult(), "shippingTotal"));
				sc.setShippingPromoSavings(getValueFromXml(response.getResult(), "shippingPromoSavings"));
				sc.setCartTotal(getValueFromXml(response.getResult(), "cartTotal"));


			}

			

		}

	}
	
	public Double getValueFromXml(String result, String key){
		
		if(result.contains(key)){
			int start = result.indexOf("<" + key + ">") + key.length() + 2;
			int end = result.indexOf("</" + key + ">");
			String value = result.substring(start, end);
			return Double.parseDouble(value);
		}
		
		return 0D;
		
		
	}

}
