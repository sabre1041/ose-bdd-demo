package com.redhat.coolstore;

import java.util.ArrayList;

public class ShoppingCart implements java.io.Serializable {

	static final long serialVersionUID = 1L;

	private java.lang.Double cartItemPromoSavings;

	private java.lang.Double cartItemTotal;

	private java.lang.Double cartTotal;

	private java.lang.Double shippingPromoSavings;

	private java.lang.Double shippingTotal;

	private java.util.List<com.redhat.coolstore.ShoppingCartItem> shoppingCartItemList = new ArrayList<ShoppingCartItem>();;

	public ShoppingCart() {
	}

	public ShoppingCart(java.lang.Double cartItemTotal, java.lang.Double cartItemPromoSavings,
			java.lang.Double shippingTotal, java.lang.Double shippingPromoSavings, java.lang.Double cartTotal,
			java.util.List<com.redhat.coolstore.ShoppingCartItem> shoppingCartItemList) {
		this.cartItemTotal = cartItemTotal;
		this.cartItemPromoSavings = cartItemPromoSavings;
		this.shippingTotal = shippingTotal;
		this.shippingPromoSavings = shippingPromoSavings;
		this.cartTotal = cartTotal;
		this.shoppingCartItemList = shoppingCartItemList;
	}

	public java.lang.Double getCartItemPromoSavings() {
		return this.cartItemPromoSavings;
	}

	public void setCartItemPromoSavings(java.lang.Double cartItemPromoSavings) {
		this.cartItemPromoSavings = cartItemPromoSavings;
	}

	public java.lang.Double getCartItemTotal() {
		return this.cartItemTotal;
	}

	public void setCartItemTotal(java.lang.Double cartItemTotal) {
		this.cartItemTotal = cartItemTotal;
	}

	public java.lang.Double getCartTotal() {
		return this.cartTotal;
	}

	public void setCartTotal(java.lang.Double cartTotal) {
		this.cartTotal = cartTotal;
	}

	public java.lang.Double getShippingPromoSavings() {
		return this.shippingPromoSavings;
	}

	public void setShippingPromoSavings(java.lang.Double shippingPromoSavings) {
		this.shippingPromoSavings = shippingPromoSavings;
	}

	public java.lang.Double getShippingTotal() {
		return this.shippingTotal;
	}

	public void setShippingTotal(java.lang.Double shippingTotal) {
		this.shippingTotal = shippingTotal;
	}

	public java.util.List<com.redhat.coolstore.ShoppingCartItem> getShoppingCartItemList() {
		return this.shoppingCartItemList;
	}

	public void setShoppingCartItemList(java.util.List<com.redhat.coolstore.ShoppingCartItem> shoppingCartItemList) {
		this.shoppingCartItemList = shoppingCartItemList;
	}

	public void resetShoppingCartItemList() {
		shoppingCartItemList = new ArrayList<ShoppingCartItem>();

	}

	public void addShoppingCartItem(ShoppingCartItem sci) {

		if (sci != null) {

			shoppingCartItemList.add(sci);

		}

	}

	public boolean removeShoppingCartItem(ShoppingCartItem sci) {

		boolean removed = false;

		if (sci != null) {

			removed = shoppingCartItemList.remove(sci);

		}

		return removed;

	}
}