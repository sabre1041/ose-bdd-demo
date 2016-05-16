package com.redhat.steps;

import static com.redhat.utils.StepUtils.getKieServerPassword;
import static com.redhat.utils.StepUtils.getKieServerUrl;
import static com.redhat.utils.StepUtils.getKieServerUser;

import java.util.ArrayList;
import java.util.List;

import org.junit.Assert;
import org.kie.api.command.BatchExecutionCommand;
import org.kie.api.command.Command;
import org.kie.internal.command.CommandFactory;
import org.kie.server.api.marshalling.MarshallingFormat;
import org.kie.server.api.model.ServiceResponse;
import org.kie.server.client.KieServicesConfiguration;
import org.kie.server.client.KieServicesFactory;
import org.kie.server.client.RuleServicesClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.redhat.coolstore.ShoppingCart;
import com.redhat.coolstore.ShoppingCartItem;

import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

public class CoolstoreSetps {

	private List<ShoppingCartItem> shoppingCartItems;
	private ShoppingCart shoppingCart;
	
	@Given("^the following shopping cart items:$")
	public void the_following_shopping_cart_items(List<ShoppingCartItem> shoppingCartItems) throws Throwable {
		this.shoppingCartItems = shoppingCartItems;
		shoppingCart = null;
	}

	@When("^the shipping is calculated$")
	public void the_shipping_is_calculated() throws Throwable {
		
		KieServicesConfiguration config = KieServicesFactory.newRestConfiguration(
				getKieServerUrl(), getKieServerUser(),
				getKieServerPassword());
		config.setMarshallingFormat(MarshallingFormat.XSTREAM);
		RuleServicesClient client = KieServicesFactory.newKieServicesClient(config)
				.getServicesClient(RuleServicesClient.class);
		List<Command> commands = new ArrayList<Command>();

		ShoppingCart factShoppingCart = new ShoppingCart();

		factShoppingCart.setCartItemPromoSavings(0d);
		factShoppingCart.setCartItemTotal(0d);
		factShoppingCart.setCartTotal(0d);
		factShoppingCart.setShippingPromoSavings(0d);
		factShoppingCart.setShippingTotal(0d);

		commands.add(CommandFactory.newInsert(factShoppingCart, "shoppingCart"));

		for (ShoppingCartItem item : shoppingCartItems) {
			item.setQuantity(1);
			item.setShoppingCart(factShoppingCart);
			item.setPromoSavings(0d);
			commands.add(CommandFactory.newInsert(item));
		}

		commands.add(CommandFactory.newStartProcess("com.redhat.coolstore.PriceProcess"));
		commands.add(CommandFactory.newFireAllRules());
		
		BatchExecutionCommand myCommands = CommandFactory.newBatchExecution(commands, "defaultStatelessKieSession");
		//System.out.println(BatchExecutionHelper.newXStreamMarshaller().toXML(myCommands));

		ServiceResponse<String> response = client.executeCommands("default", myCommands);
		//System.out.println(response.getResult());

		factShoppingCart.setCartItemTotal(getValueFromXml(response.getResult(), "cartItemTotal"));
		factShoppingCart.setCartItemPromoSavings(getValueFromXml(response.getResult(), "cartItemPromoSavings"));
		factShoppingCart.setShippingTotal(getValueFromXml(response.getResult(), "shippingTotal"));
		factShoppingCart.setShippingPromoSavings(getValueFromXml(response.getResult(), "shippingPromoSavings"));
		factShoppingCart.setCartTotal(getValueFromXml(response.getResult(), "cartTotal"));
		shoppingCart = factShoppingCart;

	}

	@Then("^the shipping cost is (\\d+.\\d+)$")
	public void the_shipping_cost_is(double shippingCost) throws Throwable {
		Assert.assertTrue(shoppingCart.getShippingTotal().doubleValue() == shippingCost);
	}

	@Then("^there is no shipping promotion applied$")
	public void there_is_no_shipping_promotion_applied() throws Throwable {
		Assert.assertTrue(shoppingCart.getShippingPromoSavings().doubleValue() == 0);
	}

	@Then("^the shipping total with the promotion applied is (\\d+.\\d+)$")
	public void the_shipping_total_with_the_promotion_applied_is(double shippingPromo) throws Throwable {
		Assert.assertTrue(shoppingCart.getShippingPromoSavings().doubleValue() != 0);
		Assert.assertTrue(shoppingCart.getShippingPromoSavings().doubleValue() +  shoppingCart.getShippingTotal().doubleValue() == 0);

	}

	private Double getValueFromXml(String result, String key) {

		if (result.contains(key)) {
			int start = result.indexOf("<" + key + ">") + key.length() + 2;
			int end = result.indexOf("</" + key + ">");
			String value = result.substring(start, end);
			return Double.parseDouble(value);
		}

		return 0D;

	}

}
