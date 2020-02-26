@supervisor
Feature: Changing the states of an order
  As a Stock user, I transition the orders through multiple states

  Scenario: Cannot dispatch a package from a Submitted order
    Given I have an order of state "submitted"
    And It has an orders_package of state "designated"
    Then Dispatching the orders_package should "fail"

  Scenario: Cannot dispatch a package from a Processing order
    Given I have an order of state "processing"
    And It has an orders_package of state "designated"
    Then Dispatching the orders_package should "fail"

  Scenario: Dispatching a package of a Scheduled order changes the state of the order to Dispatching
    Given I have an order of state "awaiting_dispatch"
    And It has an orders_package of state "designated"
    When I dispatch the orders_package
    Then The order transitions to the "dispatching" state

  Scenario: An order with dispatched packages should not be cancellable
    Given I have an order of state "dispatching"
    And It has an orders_package of state "dispatched"
    Then Applying the "cancel" transition to the order "fails"




