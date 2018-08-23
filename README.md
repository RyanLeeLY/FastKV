# FastKV
[![Platform](https://img.shields.io/cocoapods/p/TinyPart.svg?style=flat)](https://cocoapods.org/?q=tinypart)
[![Version](https://img.shields.io/cocoapods/v/FastKV.svg?style=flat)](https://cocoapods.org/pods/FastKV)
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/RyanLeeLY/TinyPart/blob/master/LICENSE)
[![Gmail](https://img.shields.io/badge/Gmail-@liyaoxjtu2013-red.svg?style=flat)](mail://liyaoxjtu2013@gmail.com)
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/liyaoryan)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Usage
```
[[FastKV defaultFastKV] setBool:YES forKey:@"key"];
[[FastKV defaultFastKV] setInteger:1 forKey:@"key"];
[[FastKV defaultFastKV] setObject:@"value" forKey:@"key"];

[[FastKV defaultFastKV] boolForKey:@"key"];
[[FastKV defaultFastKV] integerForKey:@"key"];
[[FastKV defaultFastKV] objectOfClass:NSString.class forKey:@"key"];
```

## Installation

FastKV is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FastKV'
```

## Author

yao.li, liyaoxjtu2013@gmail.com

## License

FastKV is available under the [MIT](https://github.com/RyanLeeLY/FastKV/blob/master/LICENSE) license. See the LICENSE file for more info.
