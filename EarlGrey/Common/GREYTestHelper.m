//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Common/GREYTestHelper.h"

#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYExposed.h"
#import "Provider/GREYUIWindowProvider.h"

@implementation GREYTestHelper : NSObject

+ (void)enableFastAnimation {
  for (UIWindow *window in [GREYUIWindowProvider allWindows]) {
    [[window layer] setSpeed:100];
  }
}

+ (void)disableFastAnimation {
  for (UIWindow *window in [GREYUIWindowProvider allWindows]) {
    [[window layer] setSpeed:1];
  }
}

+ (BOOL)isSystemAlertShown {
  return [[UIApplication sharedApplication] _isSpringBoardShowingAnAlert];
}

+ (BOOL)isInApplicationProcess {
  return ![[[NSProcessInfo processInfo] processName] isEqualToString:@"XCTRunner"];
}

+ (BOOL)isInRemoteApplicationProcess {
  return ![GREYTestHelper isInXCTestProcess];
}

+ (BOOL)isInXCTestProcess {
  // Odd: autoreleasepool is required here to prevent a crashes in autoreleasepool pop when
  // when exceptions are thrown.
  @autoreleasepool {
    NSDictionary *environmentVars = [[NSProcessInfo processInfo] environment];
    NSAssert(environmentVars, @"should not be nil");
    return environmentVars[@"XCTestConfigurationFilePath"] != nil;
  }
}

+ (NSString *)absoluteXCTestPluginPath {
  I_CHECK_XCTEST_PROCESS();
  
  for (NSBundle *bundle in [NSBundle allBundles]) {
    if ([[bundle executablePath] containsString:@".xctest/"]) {
      return [bundle executablePath];
    }
  }
  NSAssert(NO, @"couldn't find XCTest plugin");
  return nil;
}

+ (NSString *)absoluteEarlGreyPath {
  I_CHECK_XCTEST_PROCESS();
  
  NSString *pluginPath = [GREYTestHelper absoluteXCTestPluginPath];
  NSString *basePath = [pluginPath stringByDeletingLastPathComponent];
  return [basePath stringByAppendingPathComponent:@"EarlGrey.framework/EarlGrey"];
}

+ (NSString *)relativeXCTestPluginPath {
  I_CHECK_XCTEST_PROCESS();
  
  NSString *absolutePath = [GREYTestHelper absoluteXCTestPluginPath];
  NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[absolutePath pathComponents]];
  [pathComponents removeObjectsInRange:NSMakeRange(0, [pathComponents count] - 4)];
  [pathComponents replaceObjectAtIndex:0 withObject:@"@executable_path"];
  return [NSString pathWithComponents:pathComponents];
}

+ (NSString *)relativeEarlGreyPath {
  I_CHECK_XCTEST_PROCESS();

  NSString *pluginPath = [GREYTestHelper relativeXCTestPluginPath];
  NSString *basePath = [pluginPath stringByDeletingLastPathComponent];
  return [basePath stringByAppendingPathComponent:@"EarlGrey.framework/EarlGrey"];
}

+ (NSString *)targetApplicationBundleID {
  I_CHECK_XCTEST_PROCESS();
  
  // If we are in XCTRunner, the target app bundle ID can be found in XCTestConfiguration.
  // If we are in not in XCTRunner but this process is running XCTest, then this must be a unit test
  // target and the target app bundle ID is the current bundle ID.
  NSString *targetAppBundleID =
  [[XCTestConfiguration activeTestConfiguration] targetApplicationBundleID];
  if (!targetAppBundleID) {
    targetAppBundleID = [[NSBundle mainBundle] bundleIdentifier];
  }
  NSAssert(targetAppBundleID, @"EarlGrey wasn't able to determine the bundle ID of the target app");
  return targetAppBundleID;
}

@end
