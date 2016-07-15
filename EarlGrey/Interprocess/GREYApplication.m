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

#import "GREYApplication.h"

#import <dlfcn.h>

#import "GREYAnalytics.h"
#import "GREYAssertionDefines.h"
#import "GREYConnection.h"
#import "GREYExposed.h"
#import "GREYMessage.h"
#import "GREYPrivate.h"
#import "GREYTestHelper.h"
#import "XCTestCase+GREYAdditions.h"

static NSMutableSet *apps = nil;
static NSMutableSet *appsNeedingCleanUp = nil;

static const CFTimeInterval kResponseTimeoutSeconds = 10;
static const CFTimeInterval kExecutionTimeoutSeconds = 120;
static const CFTimeInterval kPollIntervalSeconds = 0.01;

typedef NS_ENUM(NSInteger, GREYApplicationState) {
  kGREYApplicationStateUnknown = 1,
  kGREYApplicationStateLaunched,
  kGREYApplicationStateReady,
  kGREYApplicationStatePendingResponse,
  kGREYApplicationStateExecutingBlock,
  kGREYApplicationStatePerformingCleanUp,
  kGREYApplicationStateNotResponding,
  kGREYApplicationStateTerminated,
  kGREYApplicationStateCrashed,
};

@implementation GREYApplication {
  GREYConnection *_connection;
  GREYApplicationState _state;
}

@synthesize bundleID = _bundleID;
@synthesize isRemote = _isRemote;

+ (GREYApplication *)targetApplication {
  I_CHECK_XCTEST_PROCESS();
  
  return [GREYApplication grey_existingAppForBundleID:[GREYTestHelper targetApplicationBundleID]];
}

+ (GREYApplication *)applicationWithBundleID:(NSString *)bundleID {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(bundleID);

  GREYApplication *app = [GREYApplication grey_existingAppForBundleID:bundleID];
  NSAssert(app, @"application %@ is not available", bundleID);
  return app;
}

+ (void)load {
  if ([GREYTestHelper isInXCTestProcess]) {
    apps = [[NSMutableSet alloc] init];
    [apps addObject:[[GREYApplication alloc] initTargetApplication]];
    appsNeedingCleanUp = [[NSMutableSet alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
      if ([GREYTestHelper isInApplicationProcess]) {
        [appsNeedingCleanUp addObject:[GREYApplication targetApplication]];
      }
      for (GREYApplication *app in appsNeedingCleanUp) {
        [app grey_performCleanUp];
      }
    }];
  }
}

- (BOOL)isHealthy {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_state != kGREYApplicationStateLaunched &&
           _state != kGREYApplicationStatePendingResponse &&
           _state != kGREYApplicationStateExecutingBlock &&
           _state != kGREYApplicationStatePerformingCleanUp, @"app should not be in these states");
  
  if (!_isRemote) {
    return YES;
  }
  if (!_connection) {
    return NO;
  }
  _state = kGREYApplicationStatePendingResponse;
  [_connection sendMessage:[GREYMessage messageForCheckConnection]];
  // Wait for response.
  return [self grey_waitForStateChangeFromState:kGREYApplicationStatePendingResponse
                                    withTimeout:kResponseTimeoutSeconds];
}

- (void)launch {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_isRemote, @"launch not supported for local applications");
  NSAssert([_bundleID isEqualToString:[GREYTestHelper targetApplicationBundleID]],
           @"launch only supported for target application");
  
  XCUIApplication *app = [[XCUIApplication alloc] init];
  NSMutableDictionary *d = [app.launchEnvironment mutableCopy];
  d[@"DYLD_INSERT_LIBRARIES"] = [GREYTestHelper relativeEarlGreyPath];
  app.launchEnvironment = d;
  _state = kGREYApplicationStateLaunched;
  [app launch];
  // Wait for app to connect.
  BOOL timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStateLaunched
                                             withTimeout:kExecutionTimeoutSeconds];
  if (timedOut) {
    GREYFail(@"launch timed out waiting for app to connect");
  }
}

- (void)terminate {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_isRemote, @"terminate not supported for local applications");
  NSAssert([_bundleID isEqualToString:[GREYTestHelper targetApplicationBundleID]],
           @"terminate only supported for target application");
  
  XCUIApplication *app = [[XCUIApplication alloc] init];
  _state = kGREYApplicationStateTerminated;
  [app terminate];
}

- (void)executeSyncWithBlock:(GREYTestBlock)block {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(block);
  
  [self executeSync:[GREYApplication grey_functionForBlock:block]];
}

- (void)executeSync:(GREYTestFunction)function {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(function);
  
  [GREYAnalytics didInvokeEarlGrey];
  [appsNeedingCleanUp addObject:self];
  
  if (!_isRemote) {
    function();
    return;
  }
  
  NSAssert(_state == kGREYApplicationStateReady, @"application should be ready");

  Dl_info dl_info;
  int result = dladdr(function, &dl_info);
  
  NSAssert(result != 0, @"failed getting address info");
  NSAssert(function == (GREYTestFunction)dl_info.dli_saddr, @"symbol address must match exactly");
  
  NSString *path = [NSString stringWithCString:dl_info.dli_fname encoding:NSUTF8StringEncoding];
  NSRange xctestRange = [path rangeOfString:@".xctest/"];
  NSAssert(xctestRange.location != NSNotFound, @"function should be in xctest plugin");

  // Use relative path for target app, because on devices the path must stay inside the sandbox.
  if ([[self bundleID] isEqualToString:[GREYTestHelper targetApplicationBundleID]]) {
    path = [GREYTestHelper relativeXCTestPluginPath];
  }
  
  GREYMessage *executeBlockMessage =
      [GREYMessage messageForExecuteBlockWithFilePath:path
                                           fileOffset:dl_info.dli_saddr - dl_info.dli_fbase];
  _state = kGREYApplicationStatePendingResponse;
  [_connection sendMessage:executeBlockMessage];
  
  // Wait for app to send block will begin.
  BOOL timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStatePendingResponse
                                              withTimeout:kResponseTimeoutSeconds];
  if (timedOut) {
    GREYFail(@"executeSync: timed out waiting for block to begin");
  }
  // Wait for app to send block did finish.
  timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStateExecutingBlock
                                         withTimeout:kExecutionTimeoutSeconds];
  if (timedOut) {
    GREYFail(@"executeSync: timed out waiting for block to finish");
  }
}

#pragma mark - Private

+ (void)grey_callbackWithMessage:(GREYMessage *)message {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(message);
  
  GREYApplication *app = [GREYApplication grey_existingAppForBundleID:[message bundleID]];
  if (!app) {
    NSAssert([message messageType] == kGREYMessageConnect, @"new app must send connect first");

    NSLog(@"GREYApplication %@ connected", [message bundleID]);
    [apps addObject:[[GREYApplication alloc] initRemoteApplicationWithBundleID:[message bundleID]]];
  } else {
    [app grey_callbackWithMessage:message];
  }
}

+ (GREYApplication *)grey_existingAppForBundleID:(NSString *)bundleID {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(bundleID);

  for (id app in apps) {
    if ([bundleID isEqualToString:[app bundleID]]) {
      return app;
    }
  }
  return nil;
}

+ (GREYTestFunction)grey_functionForBlock:(GREYTestBlock)block {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(block);

  NSAssert([block class] == NSClassFromString(@"__NSGlobalBlock__"),
           @"Block captured a variable or object from local scope, which EarlGrey cannot support.");
  return ((__bridge struct Block_layout *)block)->invoke;
}

- (instancetype)initTargetApplication {
  I_CHECK_XCTEST_PROCESS();

  self = [super init];
  if (self) {
    _connection = nil;
    _bundleID = [GREYTestHelper targetApplicationBundleID];
    _isRemote = ![_bundleID isEqualToString:[[NSBundle mainBundle] bundleIdentifier]];
    _state = _isRemote ? kGREYApplicationStateUnknown : kGREYApplicationStateReady;
  }
  return self;
}

- (instancetype)initRemoteApplicationWithBundleID:(NSString *)bundleID {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(bundleID);
  
  self = [super init];
  if (self) {
    _state = kGREYApplicationStateReady;
    _isRemote = YES;
    _bundleID = bundleID;
    NSString *name = [NSString stringWithFormat:@"com.google.earlgrey.app.%@", _bundleID];
    _connection = [GREYConnection remoteConnectionWithName:name];
    NSAssert(_connection, @"connection must have been created");
    
    [_connection sendMessage:[GREYMessage messageForAcceptConnection]];
  }
  return self;
}

- (void)grey_callbackWithMessage:(GREYMessage *)message {
  I_CHECK_XCTEST_PROCESS();
  NSParameterAssert(message);

  NSAssert(_isRemote, @"should not be called on a local application");
  
  switch ([message messageType]) {
    case kGREYMessageConnect:
      if (!_connection) {
        NSLog(@"GREYApplication %@ connected", [message bundleID]);
        NSString *name = [NSString stringWithFormat:@"com.google.earlgrey.app.%@", _bundleID];
        _connection = [GREYConnection remoteConnectionWithName:name];
      }
      
      // Application must have been launched; accept connection and reset state.
      [_connection sendMessage:[GREYMessage messageForAcceptConnection]];
      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageConnectionOK:
      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageCleanUpWillBegin:
      _state = kGREYApplicationStatePerformingCleanUp;
      return;
    case kGREYMessageCleanUpDidFinish:
      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageBlockWillBegin:
      _state = kGREYApplicationStateExecutingBlock;
      return;
    case kGREYMessageBlockDidFinish:
      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageError:
      _state = kGREYApplicationStateReady;
      [[XCTestCase grey_currentTestCase] grey_markAsFailedAtLine:[message errorLineNumber]
                                                          inFile:[message errorFileName]
                                                 withDescription:[message errorDescription]];
      return;
    case kGREYMessageException:
      _state = kGREYApplicationStateCrashed;
      [[XCTestCase grey_currentTestCase] grey_markAsFailedAtLine:0
                                                          inFile:nil
                                                 withDescription:[message exceptionDescription]];
      return;
    case kGREYMessageAcceptConnection:
    case kGREYMessageCheckConnection:
    case kGREYMessagePerformCleanUp:
    case kGREYMessageExecuteBlock:
      NSAssert(NO, @"server should never receive this message");
      return;
  }
}

- (void)grey_performCleanUp {
  I_CHECK_XCTEST_PROCESS();

  if (!_isRemote) {
    [[GREYUIThreadExecutor sharedInstance] performForcedCleanUpAfterTimeout:5];
    return;
  }
  
  // Only perform cleanup if app is in ready state.
  if (_state == kGREYApplicationStateReady) {
    _state = kGREYApplicationStatePendingResponse;
    [_connection sendMessage:[GREYMessage messageForPerformCleanUp]];
    
    // Wait for app to send cleanup will begin.
    BOOL timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStatePendingResponse
                                                withTimeout:kResponseTimeoutSeconds];
    if (timedOut) {
      GREYFail(@"grey_performCleanUp timed out waiting for cleanup to begin");
    }
    // Wait for app to send cleanup did finish.
    timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStatePerformingCleanUp
                                           withTimeout:kExecutionTimeoutSeconds];
    if (timedOut) {
      GREYFail(@"grey_performCleanUp timed out waiting for cleanup to finish");
    }
  }
}

- (BOOL)grey_waitForStateChangeFromState:(GREYApplicationState)oldState
                             withTimeout:(CFTimeInterval)timeoutSeconds {
  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeoutSeconds;
  while (_state == oldState) {
    if (CACurrentMediaTime() > timeoutTime) {
      _state = kGREYApplicationStateNotResponding;
      return NO;
    }
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, kPollIntervalSeconds, false);
  }
  return YES;
}

@end
