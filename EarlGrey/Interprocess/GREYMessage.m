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

#import "GREYMessage.h"

@implementation GREYMessage {
  NSDictionary *dict;
}

+ (instancetype)messageFromData:(NSData *)data {
  return [[GREYMessage alloc] initWithData:data];
}

+ (instancetype)messageForConnect {
  return [[GREYMessage alloc] initWithType:kGREYMessageConnect dictionary:@{}];
}

+ (instancetype)messageForAcceptConnection {
  return [[GREYMessage alloc] initWithType:kGREYMessageAcceptConnection dictionary:@{}];
}

+ (instancetype)messageForCheckConnection {
  return [[GREYMessage alloc] initWithType:kGREYMessageCheckConnection dictionary:@{}];
}

+ (instancetype)messageForConnectionOK {
  return [[GREYMessage alloc] initWithType:kGREYMessageConnectionOK dictionary:@{}];
}

+ (instancetype)messageForBlockWillBegin {
  return [[GREYMessage alloc] initWithType:kGREYMessageBlockWillBegin dictionary:@{}];
}

+ (instancetype)messageForBlockDidFinish {
  return [[GREYMessage alloc] initWithType:kGREYMessageBlockDidFinish dictionary:@{}];
}

+ (instancetype)messageForErrorWithDescription:(NSString *)description
                                        atLine:(NSUInteger)lineNumber
                                        inFile:(NSString *)fileName {
  return [[GREYMessage alloc] initWithType:kGREYMessageError
                                dictionary:@{@"errorDescription" : description,
                                             @"errorLineNumber"  : @(lineNumber),
                                             @"errorFileName"    : fileName}];
}

+ (instancetype)messageForExceptionWithDescription:(NSString *)description {
  return [[GREYMessage alloc] initWithType:kGREYMessageException
                                dictionary:@{@"exceptionDescription" : description}];
}

+ (instancetype)messageForPerformCleanUp {
  return [[GREYMessage alloc] initWithType:kGREYMessagePerformCleanUp dictionary:@{}];
}

+ (instancetype)messageForCleanUpWillBegin {
  return [[GREYMessage alloc] initWithType:kGREYMessageCleanUpWillBegin dictionary:@{}];
}

+ (instancetype)messageForCleanUpDidFinish {
  return [[GREYMessage alloc] initWithType:kGREYMessageCleanUpDidFinish dictionary:@{}];
}

+ (instancetype)messageForExecuteBlockWithFilePath:(NSString *)path fileOffset:(intptr_t)offset {
  NSParameterAssert(path);
  NSParameterAssert(offset != 0);
  
  NSData *offsetData = [NSMutableData dataWithBytes:&offset length:sizeof(offset)];
  return [[GREYMessage alloc] initWithType:kGREYMessageExecuteBlock
                                dictionary:@{@"filePath"       : path,
                                             @"fileOffsetData" : offsetData}];
}

- (NSData *)data {
  NSError *error = nil;
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict
                                                            format:NSPropertyListBinaryFormat_v1_0
                                                           options:0
                                                             error:&error];
  NSAssert(!error, @"error should be nil");
  
  return data;
}

- (GREYMessageType)messageType {
  GREYMessageType messageType;
  NSData *messageTypeData = dict[@"messageTypeData"];
  [messageTypeData getBytes:&messageType length:sizeof(messageType)];
  return messageType;
}

- (NSString *)bundleID {
  NSAssert(dict[@"bundleID"], @"bundleID must not be nil");

  return dict[@"bundleID"];
}

- (intptr_t)fileOffset {
  NSAssert([self messageType] == kGREYMessageExecuteBlock, @"only valid for execute block");
  NSAssert(dict[@"fileOffsetData"], @"fileOffsetData must not be nil");
  
  NSData *offsetData = dict[@"fileOffsetData"];
  intptr_t offset = 0;
  [offsetData getBytes:&offset length:sizeof(offset)];
  return offset;
}

- (NSString *)filePath {
  NSAssert([self messageType] == kGREYMessageExecuteBlock, @"only valid for execute block");
  NSAssert(dict[@"filePath"], @"filePath must not be nil");

  return dict[@"filePath"];
}

- (NSString *)exceptionDescription {
  NSAssert([self messageType] == kGREYMessageException, @"only valid for exception message");
  
  return dict[@"exceptionDescription"];
}

- (NSString *)errorDescription {
  NSAssert([self messageType] == kGREYMessageError, @"only valid for error message");
  
  return dict[@"errorDescription"];
}

- (NSUInteger)errorLineNumber {
  NSAssert([self messageType] == kGREYMessageError, @"only valid for error message");
  
  return [dict[@"errorLineNumber"] unsignedIntegerValue];
}

- (NSString *)errorFileName {
  NSAssert([self messageType] == kGREYMessageError, @"only valid for error message");
  
  return dict[@"errorFileName"];
}

#pragma mark - Private

- (instancetype)initWithData:(NSData *)data {
  NSParameterAssert(data);
  
  self = [super init];
  if (self) {
    NSError *error = nil;
    NSPropertyListFormat format = 0;
    dict = [NSPropertyListSerialization propertyListWithData:data
                                                     options:NSPropertyListImmutable
                                                      format:&format
                                                       error:&error];
    NSAssert(!error, @"error should be nil");
    NSAssert(format == NSPropertyListBinaryFormat_v1_0, @"should be binary");
    NSAssert(dict[@"messageTypeData"], @"messageTypeData must not be nil");
    NSAssert(dict[@"bundleID"], @"bundleID must not be nil");
  }
  return self;
}

- (instancetype)initWithType:(GREYMessageType)messageType dictionary:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  
  self = [super init];
  if (self) {
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    mutableDict[@"messageTypeData"] = [NSData dataWithBytes:&messageType
                                                     length:sizeof(messageType)];
    // Always set this to the application bundleID that created the message
    mutableDict[@"bundleID"] = [[NSBundle mainBundle] bundleIdentifier];
    dict = mutableDict;
    NSAssert(dict[@"messageTypeData"], @"messageTypeData must not be nil");
    NSAssert(dict[@"bundleID"], @"bundleID must not be nil");
  }
  return self;
}

@end
