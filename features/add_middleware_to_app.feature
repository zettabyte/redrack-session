Feature: Add middleware to app

  In order to persist my web session data in a redis database
  As a developer of a rack-based web application
  I want to add the redrack-session middleware to my rack app

  Scenario: Add redrack-session middleware to rack app

    Given a rack app that uses sessions
    And a redis server at "localhost:6379"
    When I configure my rack app to use the redrack-session middleware
    Then my app's session data is stored in my redis database


