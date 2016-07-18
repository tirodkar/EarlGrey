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

#import "FTRBaseIntegrationTest.h"

@interface FTRPickerViewInteractionTest : FTRBaseIntegrationTest
@end

@implementation FTRPickerViewInteractionTest

- (void)setUp {
  [super setUp];
  
  [targetApp executeSyncWithBlock:^{
    [FTRPickerViewInteractionTest openTestViewNamed:@"Picker Views"];
  }];
}

- (void)testDateOnlyPicker {
  [targetApp executeSyncWithBlock:^{
    NSString *dateString = @"1986/12/26";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY/MM/dd";
    NSDate *desiredDate = [dateFormatter dateFromString:dateString];

    [[EarlGrey selectElementWithMatcher:grey_text(@"Date")] performAction:grey_tap()];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:[GREYActions actionForSetDate:desiredDate]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        assertWithMatcher:grey_datePickerValue(desiredDate)];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
        assertWithMatcher:grey_text(dateString)];
  }];
}

- (void)testDateUpdateCallbackIsNotInvokedIfDateDoesNotChange {
  [targetApp executeSyncWithBlock:^{
    NSString *dateString = @"1986/12/26";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY/MM/dd";
    NSDate *desiredDate = [dateFormatter dateFromString:dateString];

    [[EarlGrey selectElementWithMatcher:grey_text(@"Date")] performAction:grey_tap()];

    // Changing the date must change the label.
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:[GREYActions actionForSetDate:desiredDate]];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        assertWithMatcher:grey_datePickerValue(desiredDate)];

    // Clearing the label to revert the changes.
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClearDateLabelButtonId")]
        performAction:grey_tap()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
        assertWithMatcher:grey_text(@"")];

    // Executing the change date action with the same value should not change the value, thus not
    // invoking the update callback.
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:[GREYActions actionForSetDate:desiredDate]];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
        assertWithMatcher:grey_text(@"")];
  }];
}


- (void)testTimeOnlyPicker {
  [targetApp executeSyncWithBlock:^{
    NSString *timeString = @"19:30:00";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSDate *desiredTime = [dateFormatter dateFromString:timeString];

    [[EarlGrey selectElementWithMatcher:grey_text(@"Time")] performAction:grey_tap()];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:grey_setDate(desiredTime)];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        assertWithMatcher:grey_datePickerValue(desiredTime)];
  }];
}

- (void)testDateTimePicker {
  [targetApp executeSyncWithBlock:^{
    NSString *dateTimeString = @"1986/12/26 19:30:00";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY/MM/dd HH:mm:ss";
    NSDate *desiredDateTime = [dateFormatter dateFromString:dateTimeString];

    [[EarlGrey selectElementWithMatcher:grey_text(@"DateTime")] performAction:grey_tap()];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:grey_setDate(desiredDateTime)];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        assertWithMatcher:grey_datePickerValue(desiredDateTime)];
  }];
}

- (void)testCountdownTimePicker {
  [targetApp executeSyncWithBlock:^{
    NSString *timerString = @"12:30:00";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSDate *desiredTimer = [dateFormatter dateFromString:timerString];

    [[EarlGrey selectElementWithMatcher:grey_text(@"Counter")] performAction:grey_tap()];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        performAction:grey_setDate(desiredTimer)];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
        assertWithMatcher:grey_datePickerValue(desiredTimer)];
  }];
}

- (void)testCustomPicker {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_text(@"Custom")] performAction:grey_tap()];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Blue"]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
        performAction:[GREYActions actionForSetPickerColumn:1 toValue:@"5"]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
        assertWithMatcher:grey_pickerColumnSetToValue(0, @"Blue")];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
        assertWithMatcher:grey_pickerColumnSetToValue(1, @"5")];
  }];
}

- (void)testPickerViewDidSelectRowInComponentIsCalled {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_text(@"Custom")] performAction:grey_tap()];

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Hidden"]]
        assertWithMatcher:grey_notVisible()];
  }];
}

@end
