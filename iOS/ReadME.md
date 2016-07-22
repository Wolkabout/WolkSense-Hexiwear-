#Hexiwear iOS



To setup environment you need CocoaPods installed on your computer.
You can install it with the following command:
```sh
$ gem install cocoapods
```
after that, run
```sh
$ pod install
```
this will install necessary dependencies and generate XCode workspace.

Open genarated XCode workspace and make sure that search header files is properly set,
by checking that,

Under Hexiwear PROJECT 'Build Settings'
AND   
Hexiwear TARGET 'Build Settings'

- Search Paths -> Always Search User Paths is Yes
- Search Paths -> User Header Search Paths is Pods/**


LICENSE
-------

This software is released under the GNU General Public License version 3. See LICENSE for details.
