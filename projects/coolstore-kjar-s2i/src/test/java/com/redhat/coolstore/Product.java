package com.redhat.coolstore;


public class Product  implements java.io.Serializable {

static final long serialVersionUID = 1L;
    
  
    private java.lang.String desc;
    
   
    private java.lang.String itemId;
    
  
    private java.lang.String name;
    
   
    private java.lang.Double price;

    public Product() {
    }

    public Product(java.lang.String itemId, java.lang.String name, java.lang.String desc, java.lang.Double price) {
        this.itemId = itemId;
        this.name = name;
        this.desc = desc;
        this.price = price;
    }


    
    public java.lang.String getDesc() {
        return this.desc;
    }

    public void setDesc(  java.lang.String desc ) {
        this.desc = desc;
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
}