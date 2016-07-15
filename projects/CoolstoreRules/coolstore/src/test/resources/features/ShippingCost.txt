Feature: Calculate Shipping Costs

  Scenario: Shipping cost single item under 25 dollars
    Given the following shopping cart items:
      | name                  | price |
      | 16 oz. Vortex Tumbler |  6.00 |
    When the shipping is calculated
    Then the shipping cost is 3.99

  Scenario: Shipping cost multiple items - total under 25 dollars
    Given the following shopping cart items:
      | name                  | price |
      | 16 oz. Vortex Tumbler |  6.00 |
      | Forge Laptop Sticker  |  8.50 |
    When the shipping is calculated
    Then the shipping cost is 3.99

  @wip
  Scenario: Item cost equal to 25 dollars
    Given the following shopping cart items:
      | name          | price |
      | Red Hat Shirt | 25.00 |
    When the shipping is calculated
    Then the shipping cost is 4.99

  Scenario: Shopping cart cost greater than 25 dollars less then 50 dollars
    Given the following shopping cart items:
      | name              | price |
      | Ogio Caliber Polo | 28.75 |
    When the shipping is calculated
    Then the shipping cost is 4.99

  Scenario: Shopping cart cost equal to 50 dollars
    Given the following shopping cart items:
      | name               | price |
      | Ogio Caliber Polo  | 28.75 |
      | Red Hat Coffee Mug | 21.25 |
    When the shipping is calculated
    Then the shipping cost is 6.99

  Scenario: Shopping cart cost greater than 50 less than 75
    Given the following shopping cart items:
      | name                 | price |
      | Ogio Caliber Polo    | 28.75 |
      | Red Hat Coffee Mug   | 21.25 |
      | Forge Laptop Sticker |  8.50 |
    When the shipping is calculated
    Then the shipping cost is 6.99

  Scenario: Shopping cart cost equal to 75 dollars
    Given the following shopping cart items:
      | name               | price |
      | Ogio Caliber Polo  | 28.75 |
      | Red Hat Coffee Mug | 21.25 |
      | Red Hat Shirt      | 25.00 |
    When the shipping is calculated
    Then the shipping cost is 8.99

  Scenario: Shopping cart cost greater than 75 less than 100
    Given the following shopping cart items:
      | name                 | price |
      | Ogio Caliber Polo    | 28.75 |
      | Red Hat Coffee Mug   | 21.25 |
      | Forge Laptop Sticker |  8.50 |
      | Red Hat Shirt        | 25.00 |
    When the shipping is calculated
    Then the shipping cost is 8.99

  Scenario: Shopping cart cost equal to 100 dollars
    Given the following shopping cart items:
      | name               | price |
      | Ogio Caliber Polo  | 28.75 |
      | Red Hat Coffee Mug | 21.25 |
      | Red Hat Shirt      | 25.00 |
      | Red Hat Shirt      | 25.00 |
    When the shipping is calculated
    Then the shipping cost is 10.99

  Scenario: Shopping cart cost greater than 100
    Given the following shopping cart items:
      | name                 | price |
      | Ogio Caliber Polo    | 28.75 |
      | Red Hat Coffee Mug   | 21.25 |
      | Forge Laptop Sticker |  8.50 |
      | Red Hat Shirt        | 25.00 |
      | Red Hat Shirt        | 25.00 |
    When the shipping is calculated
    Then the shipping cost is 10.99
