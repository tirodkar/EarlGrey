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

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYTestBlock.h>

@interface GREYApplication : NSObject

@property(nonatomic, readonly) NSString *bundleID;
@property(nonatomic, readonly) BOOL isRemote;

- (instancetype)init NS_UNAVAILABLE;

+ (GREYApplication *)targetApplication;
+ (GREYApplication *)applicationWithBundleID:(NSString *)bundleID;

// Objective-C only. Disabled in Swift because block syntax doesn't work with Objective-C blocks.
- (void)executeSyncWithBlock:(GREYTestBlock)block NS_SWIFT_UNAVAILABLE("Use executeSync: instead");
// Swift only. Not for use in Objective-C.
- (void)executeSync:(GREYTestFunction)function;

- (void)launch;
- (void)terminate;

- (BOOL)isHealthy;

@end
