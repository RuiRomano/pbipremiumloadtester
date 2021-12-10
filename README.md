# Intro

- Configure the reports you want to test on the [Config File](./Config.json) 
- Run the [run File](./run.ps1) 

# Config Parameters

<img width="416" alt="image" src="https://user-images.githubusercontent.com/10808715/145500939-e3086cce-3a3c-4527-9c91-0b2488db06c9.png">

## reportId & workspaceId

Id of the report & workspace to test

## instances

Number of Browser windows to launch

## sleepSeconds

Number of seconds between refresh or filter change

## filtersScramble

You need to configure Page Level filters and manually select the values:

<img width="215" alt="image" src="https://user-images.githubusercontent.com/10808715/145501071-a7a1abfa-0542-48a9-adcf-dfda6a142370.png">

This will allow the tool to get the filter values and randomly change the filter.

