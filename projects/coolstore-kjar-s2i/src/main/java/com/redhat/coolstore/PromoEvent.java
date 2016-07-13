package com.redhat.coolstore;


public class PromoEvent  implements java.io.Serializable {

static final long serialVersionUID = 1L;
    
   
    private java.lang.String itemId;
    
   
    private java.lang.Double percentOff;

    public PromoEvent() {
    }

    public PromoEvent(java.lang.String itemId, java.lang.Double percentOff) {
        this.itemId = itemId;
        this.percentOff = percentOff;
    }


    
    public java.lang.String getItemId() {
        return this.itemId;
    }

    public void setItemId(  java.lang.String itemId ) {
        this.itemId = itemId;
    }
    
    public java.lang.Double getPercentOff() {
        return this.percentOff;
    }

    public void setPercentOff(  java.lang.Double percentOff ) {
        this.percentOff = percentOff;
    }
}