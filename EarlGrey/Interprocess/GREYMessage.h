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

typedef NS_ENUM(NSInteger, GREYMessageType) {
  /* Client to Server */
  kGREYMessageConnect = 1,
  kGREYMessageConnectionOK,
  kGREYMessageBlockWillBegin,
  kGREYMessageBlockDidFinish,
  kGREYMessageError,
  kGREYMessageException,
  kGREYMessageCleanUpWillBegin,
  kGREYMessageCleanUpDidFinish,
  
  /* Server to Client */
  kGREYMessageAcceptConnection,
  kGREYMessageCheckConnection,
  kGREYMessageExecuteBlock,
  kGREYMessagePerformCleanUp,
};

@interface GREYMessage : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)messageFromData:(NSData *)data;

/* Client to Server */
+ (instancetype)messageForConnect;
+ (instancetype)messageForConnectionOK;
+ (instancetype)messageForBlockWillBegin;
+ (instancetype)messageForBlockDidFinish;
+ (instancetype)messageForErrorWithDescription:(NSString *)description
                                        atLine:(NSUInteger)lineNumber
                                        inFile:(NSString *)fileName;
+ (instancetype)messageForExceptionWithDescription:(NSString *)description;
+ (instancetype)messageForCleanUpWillBegin;
+ (instancetype)messageForCleanUpDidFinish;

/* Server to Client */
+ (instancetype)messageForAcceptConnection;
+ (instancetype)messageForCheckConnection;
+ (instancetype)messageForExecuteBlockWithFilePath:(NSString *)path fileOffset:(intptr_t)offset;
+ (instancetype)messageForPerformCleanUp;

- (NSData *)data;

- (GREYMessageType)messageType;
- (NSString *)bundleID;
- (intptr_t)fileOffset;
- (NSString *)filePath;
- (NSString *)errorDescription;
- (NSString *)errorFileName;
- (NSUInteger)errorLineNumber;
- (NSString *)exceptionDescription;

@end
