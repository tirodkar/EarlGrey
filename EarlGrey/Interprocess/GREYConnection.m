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

#import "GREYConnection.h"

#import "GREYExposed.h"
#import "GREYMessage.h"

static NSString *requestedRemoteConnectionName = nil;

@implementation GREYConnection {
  NSString *remoteName;
}

+ (instancetype)remoteConnectionWithName:(NSString *)name {
  NSParameterAssert(name);
  NSAssert(!requestedRemoteConnectionName || [requestedRemoteConnectionName isEqualToString:name],
           @"if set, remoteName must remain the same during the lifetime of the process");
  
  return [[GREYConnection alloc] initWithRemoteName:name];
}

+ (void)requestRemoteConnectionWithName:(NSString *)name {
  NSAssert(!requestedRemoteConnectionName || [requestedRemoteConnectionName isEqualToString:name],
           @"if set, remoteName must remain the same during the lifetime of the process");
  
  GREYConnection *connection = [[GREYConnection alloc] initWithRemoteName:name];
  requestedRemoteConnectionName = name;
  [connection sendMessage:[GREYMessage messageForConnect]];
}

- (void)sendMessage:(GREYMessage *)message {
  NSParameterAssert(message);
  NSData *remoteNameAsData = [NSKeyedArchiver archivedDataWithRootObject:remoteName];
  NSArray *dataToSend = @[remoteNameAsData, [message data]];
  [[UIPasteboard generalPasteboard] setData:[NSKeyedArchiver archivedDataWithRootObject:dataToSend]
                          forPasteboardType:remoteName];
}

#pragma mark - Private

- (instancetype)initWithRemoteName:(NSString *)name {
  NSParameterAssert(name);
  
  self = [super init];
  if (self) {
    remoteName = name;
  }
  return self;
}

@end
