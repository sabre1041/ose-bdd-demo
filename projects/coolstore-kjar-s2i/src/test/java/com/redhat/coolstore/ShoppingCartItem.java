package com.redhat.coolstore;


public class ShoppingCartItem  implements java.io.Serializable {

static final long serialVersionUID = 1L;
    
 
    private java.lang.String itemId;
    
   
    private java.lang.String name;
    
    
    private java.lang.Double price;
    
   
    private java.lang.Double promoSavings;
    
   
    private java.lang.Integer quantity;
    
    private Product product;
    
   
    private com.redhat.coolstore.ShoppingCart shoppingCart;

    public ShoppingCartItem() {
    }

    public ShoppingCartItem(java.lang.String itemId, java.lang.String name, java.lang.Double price, java.lang.Integer quantity, java.lang.Double promoSavings, com.redhat.coolstore.ShoppingCart shoppingCart) {
        this.itemId = itemId;
        this.name = name;
        this.price = price;
        this.quantity = quantity;
        this.promoSavings = promoSavings;
        this.shoppingCart = shoppingCart;
    }


    
    public java.lang.String getItemId() {
        return this.itemId;
    }

    public void setItemId(  java.lang.String itemId ) {
        this.itemId = itemId;
    }
    
    public java.lang.String getName() {
        return this.name;
    }

    public void setName(  java.lang.String name ) {
        this.name = name;
    }
    
    public java.lang.Double getPrice() {
        return this.price;
    }

    public void setPrice(  java.lang.Double price ) {
        this.price = price;
    }
    
    public java.lang.Double getPromoSavings() {
        return this.promoSavings;
    }

    public void setPromoSavings(  java.lang.Double promoSavings ) {
        this.promoSavings = promoSavings;
    }
    
    public java.lang.Integer getQuantity() {
        return this.quantity;
    }

    public void setQuantity(  java.lang.Integer quantity ) {
        this.quantity = quantity;
    }
    
    public com.redhat.coolstore.ShoppingCart getShoppingCart() {
        return this.shoppingCart;
    }

    public void setShoppingCart(  com.redhat.coolstore.ShoppingCart shoppingCart ) {
        this.shoppingCart = shoppingCart;
    }

	public Product getProduct() {
		return product;
	}

	/**
	 * @param product the product to set
	 */
	public void setProduct(Product product) {
		this.product = product;
	}

	@Override
	public String toString() {
		return "ShoppingCartItem [itemId=" + itemId + ", name=" + name + ", price=" + price + ", promoSavings="
				+ promoSavings + ", quantity=" + quantity + ", product=" + product + ", shoppingCart=" + shoppingCart
				+ "]";
	}
	
	
}