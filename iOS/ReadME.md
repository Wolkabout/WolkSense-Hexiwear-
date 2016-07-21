Hexiwear iOS

To setup environment please run:

pod install

this will install necessary dependencies and generate XCode workspace.

Open genarated XCode workspace and make sure that search header files is properly set,
by checking that,

Under Hexiwear PROJECT 'Build Settings'
AND   
Hexiwear TARGET 'Build Settings'

- Search Paths -> Always Search User Paths is Yes
- Search Paths -> User Header Search Paths is Pods/**
