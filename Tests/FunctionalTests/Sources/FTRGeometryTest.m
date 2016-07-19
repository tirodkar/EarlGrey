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

#import <EarlGrey/CGGeometry+GREYAdditions.h>

#import "FTRBaseIntegrationTest.h"

@interface FTRGeometryTest : FTRBaseIntegrationTest
@end

@implementation FTRGeometryTest

#pragma mark - CGRectFixedToVariableScreenCoordinates

- (void)testCGRectFixedToVariableScreenCoordinates_portrait {
  [targetApp executeSyncWithBlock:^{
    CGRect actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(40, 50, 100, 120));
    GREYAssertTrue(CGRectEqualToRect(CGRectMake(40, 50, 100, 120), actualRect), @"should be true");
  }];
}

- (void)testCGRectFixedToVariableScreenCoordinates_portraitUpsideDown {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    CGRect expectedRect = CGRectMake(width - 40 - 100,
                                     height - 50 - 120,
                                     100, 120);
    CGRect actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(40, 50, 100, 120));

    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");
  }];
}

- (void)testCGRectFixedToVariableScreenCoordinates_landscapeRight {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    // Bottom left => Top left
    CGRect rectInFixed = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height) - 20,
                                    10, 20);
    CGRect actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    CGRect expectedRect = CGRectMake(0, 0, 20, 10);
    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");

    // Bottom right => Bottom left
    rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 10,
                             (iOS8_0_OR_ABOVE() ? width : height) - 20,
                             10, 20);
    actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    expectedRect = CGRectMake(0, (iOS8_0_OR_ABOVE() ? height : width) - 10, 20, 10);
    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");

    // Too left => Top right
    rectInFixed = CGRectMake(0, 0, 10, 20);
    actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    expectedRect = CGRectMake((iOS8_0_OR_ABOVE() ? width : height) - 20, 0,
                              20, 10);
    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");

    // Too right => bottom right
    rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 10, 0,
                             10, 20);
    actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    expectedRect = CGRectMake((iOS8_0_OR_ABOVE() ? width : height) - 20,
                              (iOS8_0_OR_ABOVE() ? height : width) - 10,
                              20, 10);
    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");
  }];
}

- (void)testCGRectFixedToVariableScreenCoordinates_landscapeLeft {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    CGRect rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 120, 50, 120, 100);
    CGRect actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    GREYAssertTrue(CGRectEqualToRect(CGRectMake(50, 0, 100, 120), actualRect),
                   @"should be true");

    rectInFixed = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0);
    actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
    GREYAssertTrue(CGRectEqualToRect(CGRectMake((iOS8_0_OR_ABOVE() ? width : height),
                                                (iOS8_0_OR_ABOVE() ? height : width), 0, 0),
                                     actualRect),
                   @"should be true");
  }];
}

#pragma mark - CGRectVariableToFixedScreenCoordinates

- (void)testCGRectVariableToFixedScreenCoordinates_portrait {
  [targetApp executeSyncWithBlock:^{
    CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(40, 50, 100, 120));
    GREYAssertTrue(CGRectEqualToRect(CGRectMake(40, 50, 100, 120), actualRect), @"should be true");
  }];
}

- (void)testCGRectVariableToFixedScreenCoordinates_portraitUpsideDown {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    CGRect expectedRect = CGRectMake(width - 40 - 100,
                                     height - 50 - 120,
                                     100, 120);
    CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(40, 50, 100, 120));

    GREYAssertTrue(CGRectEqualToRect(expectedRect, actualRect), @"should be true");
  }];
}


- (void)testCGRectVariableToFixedScreenCoordinates_landscapeRight {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    CGRect rectInVariable = CGRectMake(0, 0, 0, 0);
    CGRect actualRect = CGRectVariableToFixedScreenCoordinates(rectInVariable);
    GREYAssertTrue(CGRectEqualToRect(CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0),
                                     actualRect),
                   @"should be true");
  }];
}

- (void)testCGRectVariableToFixedScreenCoordinates_landscapeLeft {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);

    CGRect rectInVariable = CGRectMake(50, 0, 100, 120);
    CGRect actualRect = CGRectVariableToFixedScreenCoordinates(rectInVariable);
    GREYAssertTrue(CGRectEqualToRect(CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 120,
                                                50,
                                                120,
                                                100),
                                     actualRect),
                   @"should be true");

    rectInVariable = CGRectMake((iOS8_0_OR_ABOVE() ? width : height),
                                (iOS8_0_OR_ABOVE() ? height : width), 0, 0);
    actualRect = CGRectVariableToFixedScreenCoordinates(rectInVariable);
    GREYAssertTrue(CGRectEqualToRect(CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0),
                                     actualRect),
                   @"should be true");
  }];
}

@end
