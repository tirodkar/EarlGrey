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

#import "GREYApplicationClient.h"

#import <dlfcn.h>
#import <mach-o/dyld.h>

#import "GREYAssertionDefines.h"
#import "GREYConnection.h"
#import "GREYMessage.h"
#import "GREYPrivate.h"
#import "GREYTestBlock.h"
#import "GREYTestHelper.h"

static GREYConnection *connection = nil;
static BOOL errorMessageSent = NO;
static NSString *const kApplicationClientInternalException = @"kApplicationClientInternalException";

@implementation GREYApplicationClient

+ (void)load {
  if ([GREYTestHelper isInRemoteApplicationProcess]) {
    [GREYApplicationClient connectToServer];
  }
}

+ (void)connectToServer {
  I_CHECK_REMOTE_APPLICATION_PROCESS();

  if (!connection) {
    [GREYConnection requestRemoteConnectionWithName:@"com.google.earlgrey"];
    NSLog(@"GREYApplicationClient sent connection request to the server");
    // Send a connection request again in 1 second if connection isn't estabilished by then.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   ^{
      [GREYApplicationClient connectToServer];
    });
  }
}

+ (void)callbackWithMessage:(GREYMessage *)message {
  I_CHECK_REMOTE_APPLICATION_PROCESS();
  
  switch ([message messageType]) {
    case kGREYMessageAcceptConnection:
      [self handleAcceptConnectionMessage];
      return;
    case kGREYMessageCheckConnection:
      [self handleCheckConnectionMessage];
      return;
    case kGREYMessagePerformCleanUp:
      [self handlePerformCleanUpMessage];
      return;
    case kGREYMessageExecuteBlock:
      [self handleExecuteBlockMessageWithMessage:message];
      return;
    case kGREYMessageConnect:
    case kGREYMessageConnectionOK:
    case kGREYMessageCleanUpWillBegin:
    case kGREYMessageCleanUpDidFinish:
    case kGREYMessageBlockWillBegin:
    case kGREYMessageBlockDidFinish:
    case kGREYMessageError:
    case kGREYMessageException:
      NSAssert(NO, @"message should not have been sent to client");
      return;
  }
}

+ (void)handleAcceptConnectionMessage {
  NSAssert(!connection, @"connection should not have been created yet");
  
  connection = [GREYConnection remoteConnectionWithName:@"com.google.earlgrey"];
  NSLog(@"GREYApplicationClient estabilished a connection to the server");
}

+ (void)handleCheckConnectionMessage {
  NSAssert(connection, @"connection should not be nil");
  
  [connection sendMessage:[GREYMessage messageForConnectionOK]];
}

+ (void)handlePerformCleanUpMessage {
  NSAssert(connection, @"connection should not be nil");

  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
    @try {
      @autoreleasepool {
        NSAssert(!errorMessageSent, @"no error should have been sent");
        
        [connection sendMessage:[GREYMessage messageForCleanUpWillBegin]];
        [[GREYUIThreadExecutor sharedInstance] performForcedCleanUpAfterTimeout:5];
        [connection sendMessage:[GREYMessage messageForCleanUpDidFinish]];
        NSAssert(!errorMessageSent, @"no error should have been sent");
      }
    } @catch (NSException *exception) {
      if (![exception.name isEqualToString:kApplicationClientInternalException]) {
        if (!errorMessageSent) {
          NSString *exceptionName = exception.name ? exception.name : @"<no name provided>";
          NSString *exceptionReason = exception.reason ? exception.reason : @"<no reason provided>";
          NSString *description = [NSString stringWithFormat:@"Exception: %@\nReason: %@\n",
                                                             exceptionName, exceptionReason];
          [connection sendMessage:[GREYMessage messageForExceptionWithDescription:description]];
        }
        @throw;
      } else {
        NSAssert(errorMessageSent, @"error message should be sent if this exception was thrown");
      }
    } @finally {
      errorMessageSent = NO;
    }
  });
}
  
+ (void)handleExecuteBlockMessageWithMessage:(GREYMessage *)message {
  GREYTestFunction function = [GREYApplicationClient grey_functionFromExecuteBlockMessage:message];
  NSAssert(connection, @"connection should not be nil");
  
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
    @try {
      @autoreleasepool {
        NSAssert(!errorMessageSent, @"no error should have been sent");
        
        [connection sendMessage:[GREYMessage messageForBlockWillBegin]];
        function();
        [connection sendMessage:[GREYMessage messageForBlockDidFinish]];
        NSAssert(!errorMessageSent, @"no error should have been sent");
      }
    } @catch (NSException *exception) {
      if (![exception.name isEqualToString:kApplicationClientInternalException]) {
        if (!errorMessageSent) {
          NSString *exceptionName = exception.name ? exception.name : @"<no name provided>";
          NSString *exceptionReason = exception.reason ? exception.reason : @"<no reason provided>";
          NSString *description = [NSString stringWithFormat:@"Exception: %@\nReason: %@\n",
                                                             exceptionName, exceptionReason];
          [connection sendMessage:[GREYMessage messageForExceptionWithDescription:description]];
        }
        @throw;
      } else {
        NSAssert(errorMessageSent, @"error message should be sent if this exception was thrown");
      }
    } @finally {
      errorMessageSent = NO;
    }
  });
}

+ (void)reportFailureAtLine:(NSUInteger)lineNumber
                     inFile:(NSString *)fileName
            withDescription:(NSString *)description {
  [connection sendMessage:[GREYMessage messageForErrorWithDescription:description
                                                               atLine:lineNumber
                                                               inFile:fileName]];
  errorMessageSent = YES;
  [[GREYFrameworkException exceptionWithName:kApplicationClientInternalException
                                      reason:@"Immediately halt execution in client"] raise];
}

#pragma mark - Private

+ (GREYTestFunction)grey_functionFromExecuteBlockMessage:(GREYMessage *)message {
  static NSString *path = nil;
  static intptr_t slide = 0;
  
  // For security reasons path should only be set once during the lifetime of the client.
  if (!path) {
    NSAssert(slide == 0, @"slide must be 0");

    intptr_t newSlide = [GREYApplicationClient grey_slideForFilePath:[message filePath]];
    if (newSlide != 0) {
      path = [message filePath];
      slide = newSlide;
    } else {
      NSAssert(NO, @"error while processing execute block message");
      return NULL;
    }
  } else if (slide == 0 || ![path isEqualToString:[message filePath]]) {
    NSAssert(NO, @"unexpected values while processing execute block message");
    return NULL;
  }
  
  // For security reasons, we must check that the address of the function we are about to execute
  // is in the symbol table, and we are not calling some other unexpected section of code instead.
  GREYTestFunction function = (GREYTestFunction)(slide + [message fileOffset]);
  Dl_info dl_info;
  if (dladdr(function, &dl_info) == 0 || function != (GREYTestFunction)dl_info.dli_saddr) {
    NSAssert(NO, @"error while checking if function matches an existing symbol");
    return NULL;
  }
  return function;
}

+ (intptr_t)grey_slideForFilePath:(NSString *)path {
  NSParameterAssert(path);
  
  const char *pathCString = [path cStringUsingEncoding:NSUTF8StringEncoding];
  NSAssert(pathCString, @"encoding failed");
  
  // DYLD just needs to load the executable into memory, there is no need to expose the symbols
  // to other executables.
  void *handle = dlopen(pathCString, RTLD_LOCAL | RTLD_LAZY);
  NSAssert(handle, @"handle was NULL - dlerror(): %s", dlerror());
  
  NSArray *pathComponents = [path pathComponents];
  for (uint32_t img = 0; img < _dyld_image_count(); img++) {
    NSArray *imgPathComponents = [[NSString stringWithCString:_dyld_get_image_name(img)
                                                     encoding:NSUTF8StringEncoding] pathComponents];
    // The last 3 components must be compared to ensure the path (if it is relative) is the same as
    // the absolute path from the DYLD image.
    BOOL last3Equal = YES;
    for (unsigned long part = 1; part <= 3; part++) {
      NSString *newComponent = pathComponents[[pathComponents count] - part];
      NSString *imageComponent = imgPathComponents[[imgPathComponents count] - part];
      if (![newComponent isEqualToString:imageComponent]) {
        last3Equal = NO;
        break;
      }
    }
    if (last3Equal) {
      return _dyld_get_image_vmaddr_slide(img);
    }
  }
  // Error occured
  return 0;
}

@end
