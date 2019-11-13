Feature: Listing OrdersPackage available actions
  As a Stock user, I retrieve the different operations
  I can apply to an orders package through the API

  Scenario: For inactive orders
    Given I have Orders with states of type: "INACTIVE_STATES"
    And Their OrdersPackages are of state "cancelled"
    Then They should have no actions available

  Scenario: For active orders with designated orders_package
    Given I have Orders with states of type: "ACTIVE_STATES"
    And Their OrdersPackages are of state "designated"
    Then They should have the "edit_quantity|cancel|dispatch" actions enabled

  Scenario: Editing quantity for active orders with designated orders_package
    Given I have Orders with states of type: "ACTIVE_STATES"
    And Their OrdersPackages have the following stock properties
      | State        | Requested Quantity   | Remaining Quantity  | Received Quantity |
      | designated 	 | 1                    | 1                   | 2                 |
      | designated 	 | 1                    | 0                   | 1                 |
      | designated 	 | 2                    | 1                   | 3                 |
      | designated 	 | 2                    | 0                   | 2                 |
    Then They should respectively have the following action status
      | Action          | Enabled   |
      | edit_quantity 	| true      |
      | edit_quantity 	| false     |
      | edit_quantity 	| true      |
      | edit_quantity 	| true      |

  Scenario: For dispatching orders with dispatched orders_package
    Given I have Orders of state "dispatching"
    And Their OrdersPackages are of state "dispatched"
    Then They should have the "undispatch" actions enabled

  Scenario: For active orders with cancelled orders_package
    Given I have Orders with states of type: "ACTIVE_STATES"
    And Their OrdersPackages are of state "cancelled"
    Then They should have the "redesignate" actions enabled

  Scenario: Redesignating a cancelled orders_package based on remaining qty
    Given I have Orders with states of type: "ACTIVE_STATES"
    And Their OrdersPackages have the following stock properties
      | State        | Requested Quantity   | Remaining Quantity  | Received Quantity |
      | cancelled 	 | 1                    | 1                   | 1                 |
      | cancelled 	 | 1                    | 0                   | 1                 |
      | cancelled 	 | 2                    | 1                   | 1                 |
      | cancelled 	 | 2                    | 0                   | 1                 |
      | cancelled 	 | 0                    | 1                   | 1                 |
    Then They should respectively have the following action status
      | Action          | Enabled   |
      | redesignate 	  | true      |
      | redesignate 	  | false     |
      | redesignate 	  | true      |
      | redesignate 	  | false     |
      | redesignate 	  | false     |