Feature: Free Shipping Promo

  Scenario: No free shipping when total cost is under 75
    Given the following shopping cart items:
      | name                  | price |
      | 16 oz. Vortex Tumbler |  6.00 |
    When the shipping is calculated
    Then the shipping cost is 3.99
    And there is no shipping promotion applied

  Scenario: Free shipping when total cost is 75
    Given the following shopping cart items:
      | name                  | price |
      | 16 oz. Vortex Tumbler |  6.00 |
      | Red Hat Back Pack     | 69.00 |
    When the shipping is calculated
    Then the shipping cost is 8.99
    And the shipping total with the promotion applied is 0.00

  Scenario: Free shipping when total cost is over 75
    Given the following shopping cart items:
      | name                  | price |
      | 16 oz. Vortex Tumbler |  6.00 |
      | Red Hat Back Pack     | 69.00 |
      | Forge Laptop Sticker  |  8.50 |
    When the shipping is calculated
    Then the shipping cost is 8.99
    And the shipping total with the promotion applied is 0.00
