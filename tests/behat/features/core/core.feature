@api
Feature: Core
  In order to know the website is running
  As a website user
  I need to be able to view the site title and login

  @api
    Scenario: Create users
      Given users:
      | name     | mail            | status |
      | Joe User | joe@example.com | 1      |
      And I am logged in as a user with the "administrator" role
      When I visit "admin/people"
      Then I should see the link "Joe User"

    Scenario: Login as a user created during this scenario
      Given users:
      | name      | status |
      | Test user |      1 |
      When I am logged in as "Test user"
      And I visit "user"
      Then I should see the heading "Test user"

    Scenario: Create a term
      Given I am logged in as a user with the "administrator" role
      When I am viewing a "tags" term with the name "My tag"
      Then I should see the heading "My tag"

    Scenario: Create many terms
      Given "tags" terms:
      | name    |
      | Tag one |
      | Tag two |
      And I am logged in as a user with the "administrator" role
      When I go to "admin/structure/taxonomy/manage/tags/overview"
      Then I should see "Tag one"
      And I should see "Tag two"
