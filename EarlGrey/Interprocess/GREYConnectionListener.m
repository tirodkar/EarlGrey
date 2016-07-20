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

#import "GREYConnectionListener.h"

#import "GREYApplicationClient.h"
#import "GREYApplication.h"
#import "GREYConnection.h"
#import "GREYExposed.h"
#import "GREYPrivate.h"
#import "GREYMessage.h"
#import "GREYTestHelper.h"

static NSString *listenerName;
static NSString *defaultListenerName = @"com.google.earlgrey";

@implementation GREYConnectionListener

+ (void)load {
  if ([GREYTestHelper isInXCTestProcess]) {
    [GREYConnectionListener createListenerWithName:defaultListenerName];
  } else if ([GREYTestHelper isInRemoteApplicationProcess]) {
    NSString *listenerName = [NSString stringWithFormat:@"com.google.earlgrey.app.%@",
                              [[NSBundle mainBundle] bundleIdentifier]];
    [GREYConnectionListener createListenerWithName:listenerName];
  }
}

+ (void)createListenerWithName:(NSString *)name {
  NSParameterAssert(name);
  NSAssert(!listenerName, @"should be nil, because this method must only be called once");
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(pasteboardChangedNotification)
                                               name:UIPasteboardChangedNotification
                                             object:nil];
}

+ (void)pasteboardChangedNotification {
  NSString *name = listenerName ? listenerName : defaultListenerName;
  NSData *data = [[UIPasteboard generalPasteboard] dataForPasteboardType:name];
  NSArray *unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  NSString *connectionRequesterName =
      [NSKeyedUnarchiver unarchiveObjectWithData:[unarchivedData firstObject]];
  if (![connectionRequesterName isEqualToString:name]) {
    return;
  }
  GREYMessage *message = [GREYMessage messageFromData:[unarchivedData lastObject]];
  [[UIPasteboard generalPasteboard] setData:[[NSData alloc] init]
                          forPasteboardType:listenerName];
  switch ([message messageType]) {
    case kGREYMessageConnect:
    case kGREYMessageConnectionOK:
    case kGREYMessageBlockWillBegin:
    case kGREYMessageBlockDidFinish:
    case kGREYMessageError:
    case kGREYMessageException:
    case kGREYMessageCleanUpWillBegin:
    case kGREYMessageCleanUpDidFinish:
      [GREYApplication grey_callbackWithMessage:message];
      return;
    case kGREYMessageAcceptConnection:
    case kGREYMessageCheckConnection:
    case kGREYMessagePerformCleanUp:
    case kGREYMessageExecuteBlock:
      [GREYApplicationClient callbackWithMessage:message];
      return;
  }
}

@end