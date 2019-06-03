//
// Copyright 2017 Google Inc.
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

#import "AppFramework/Additions/NSURLSession+GREYApp.h"

#include <objc/runtime.h>

#import "AppFramework/Additions/NSURL+GREYApp.h"
#import "AppFramework/Additions/__NSCFLocalDataTask_GREYApp.h"
#import "AppFramework/Synchronization/GREYAppStateTracker.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/GREYObjcRuntime.h"
#import "CommonLib/GREYSwizzler.h"

/**
 *  Type of the handlers used as NSURLSessionTask's completion blocks.
 */
typedef void (^GREYTaskCompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

@implementation NSURLSession (GREYAdditions)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
  SEL swizzledSelector = @selector(greyswizzled_dataTaskWithRequest:completionHandler:);
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:originalSelector
                                    withMethod:swizzledSelector];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[NSURLSession %@]",
                             NSStringFromSelector(originalSelector));
}

#pragma mark - Swizzled Implementation

- (NSURLSessionDataTask *)greyswizzled_dataTaskWithRequest:(NSURLRequest *)request
                                         completionHandler:(GREYTaskCompletionBlock)handler {
  SEL swizzledSel = @selector(greyswizzled_URLSession:task:didCompleteWithError:);
  // Swizzle the session delegate class if not yet done.
  id delegate = self.delegate;
  SEL originalSel = @selector(URLSession:task:didCompleteWithError:);
  Class delegateClass =
      [[delegate forwardingTargetForSelector:originalSel] class] ?: [delegate class];

  if (![delegateClass instancesRespondToSelector:swizzledSel]) {
    // If delegate does not exist or if it does not implement the delegate method, then this
    // request need not be tracked as its completion/failure does not trigger any delegate
    // callbacks.
    if ([delegate respondsToSelector:originalSel]) {
      Class selfClass = [self class];
      // Double-checked locking to prevent multiple swizzling attempts of the same class.
      @synchronized(selfClass) {
        if (![delegateClass instancesRespondToSelector:swizzledSel]) {
          [GREYObjcRuntime addInstanceMethodToClass:delegateClass
                                       withSelector:swizzledSel
                                          fromClass:selfClass];
          GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
          BOOL swizzleSuccess = [swizzler swizzleClass:delegateClass
                                 replaceInstanceMethod:originalSel
                                            withMethod:swizzledSel];
          GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[%@ %@] in %@",
                                     delegateClass, NSStringFromSelector(originalSel), delegate);
        }
      }
    }
  }

  GREYTaskCompletionBlock wrappedHandler = nil;
  __weak __block id weakTask;
  // If a handler has been provided then wrap it as delegate methods are not invoked for tasks with
  // completion blocks.
  if (handler) {
    wrappedHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
      handler(data, response, error);
      [weakTask grey_untrack];
    };
  }

  NSURLSessionDataTask *task = INVOKE_ORIGINAL_IMP2(
      NSURLSessionDataTask *, @selector(greyswizzled_dataTaskWithRequest:completionHandler:),
      request, wrappedHandler);
  // Note that if neither the delegate was set nor a completion block provided, it means that the
  // app has made a network request but will not act on the result of it (passed or failed). For
  // example: analytics requests going out from the app. Neither does EarlGrey track such requests
  // as they are not UI altering.
  if (!delegate && !handler) {
    [(id)task grey_neverTrack];
  } else {
    weakTask = task;
  }
  return task;
}

- (void)greyswizzled_URLSession:(NSURLSession *)session
                           task:(NSURLSessionTask *)task
           didCompleteWithError:(NSError *)error {
  INVOKE_ORIGINAL_IMP3(void, @selector(greyswizzled_URLSession:task:didCompleteWithError:), session,
                       task, error);
  // Now untrack *after* the delegate method has been invoked.
  id greyTask = task;
  if ([greyTask respondsToSelector:@selector(grey_untrack)]) {
    [greyTask grey_untrack];
  }
}

@end
