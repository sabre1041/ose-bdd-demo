package com.redhat.coolstore.web.ui.events;

import java.util.Set;

import com.redhat.coolstore.Product;

public class UpdateShopppingCartEvent {

	private Set<Product> selectedProducts;

	public UpdateShopppingCartEvent(Set<Product> selectedProducts) {
		this.selectedProducts = selectedProducts;
	}

	public Set<Product> getSelectedProducts() {
		return selectedProducts;
	}
}
