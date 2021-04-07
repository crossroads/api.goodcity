Feature: 'User logging'

    An app user should be allowed the login based only on their roles and permissions

    Scenario: A supervisor cannot login to stock app
    Given I am a supervisor logging into "stock" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: A reviewer cannot login to stock app
    Given I am a reviewer logging into "stock" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: A supervisor can login to admin app
    Given I am a supervisor logging into "admin" app
    And I enter the mobile number
    And I enter the pin
    Then I should be allowed to login

    Scenario: A reviewer can login to admin app
    Given I am a reviewer logging into "admin" app
    And I enter the mobile number
    And I enter the pin
    Then I should be allowed to login

    Scenario: A order_administrator can login to stock app
    Given I am a order_administrator logging into "stock" app
    And I enter the mobile number
    And I enter the pin
    Then I should be allowed to login

    Scenario: A order_administrator cannot login to admin app
    Given I am a order_administrator logging into "admin" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: A stock_administrator cannot login to admin app
    Given I am a stock_administrator logging into "admin" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: A stock_administrator can login to stock app
    Given I am a stock_administrator logging into "stock" app
    And I enter the mobile number
    Then I should be allowed to login

    Scenario: A stock_fulfilment can login to stock app
    Given I am a stock_fulfilment logging into "stock" app
    And I enter the mobile number
    Then I should be allowed to login

    Scenario: An old reviewer [expired role] cannot login to admin app
    Given I am an old reviewer logging into "admin" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: An old stock_fulfilment [expired role] cannot login to stock app
    Given I am an old stock_fulfilment logging into "stock" app
    And I enter the mobile number
    Then I should not be allowed to login

    Scenario: A order_fulfilment (and expired order_administrator role) can login to stock app
    Given I am a order_fulfilment logging into "stock" app
    Given I have expired role order_administrator and permission "can_manage_settings"
    And I enter the mobile number
    And I enter the pin
    Then I should be allowed to login
    And I create GoodcitySetting
    Then I should get unauthorized error
