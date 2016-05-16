package com.redhat.runner;

import org.junit.runner.RunWith;

import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;

@RunWith(Cucumber.class)
@CucumberOptions(features = "classpath:features", monochrome = true, glue = "com/redhat/steps/", strict = true, plugin = "json:target/cucumber.json")
public class CucumberRunnerTest {

}