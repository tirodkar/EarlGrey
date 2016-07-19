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

#import <EarlGrey/NSError+GREYAdditions.h>

#import "FTRBaseIntegrationTest.h"
#import "FTRFailureHandler.h"

// Expose private action for testing
@interface GREYActions (GREYExposedForTesting)
+ (id<GREYAction>)grey_actionForTypeText:(NSString *)text atUITextPosition:(UITextPosition *)position;
@end

@interface FTRKeyboardKeysTest : FTRBaseIntegrationTest
@end

@implementation FTRKeyboardKeysTest

- (void)setUp {
  [super setUp];
  
  [targetApp executeSyncWithBlock:^{
    [FTRKeyboardKeysTest openTestViewNamed:@"Typing Views"];
  }];
}

- (void)testTypingAtBeginning {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Foo"]]
        performAction:[FTRKeyboardKeysTest ftr_actionForTypingText:@"Bar" atPosition:0]]
        assertWithMatcher:grey_text(@"BarFoo")];
  }];
}

- (void)testTypingAtEnd {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Foo"]]
        performAction:[FTRKeyboardKeysTest ftr_actionForTypingText:@"Bar" atPosition:-1]]
        assertWithMatcher:grey_text(@"FooBar")];
  }];
}

- (void)testTypingInMiddle {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Foo"]]
        performAction:[FTRKeyboardKeysTest ftr_actionForTypingText:@"Bar" atPosition:2]]
        assertWithMatcher:grey_text(@"FoBaro")];
  }];
}

- (void)testTypingInMiddleOfBigString {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:
            [GREYActions actionForTypeText:@"This string is a little too long for this text field!"]]
        performAction:[FTRKeyboardKeysTest ftr_actionForTypingText:@"Foo" atPosition:1]]
        assertWithMatcher:grey_text(@"TFoohis string is a little too long for this text field!")];
  }];
}

- (void)testTypingAfterTappingOnTextField {
  [targetApp executeSyncWithBlock:^{
    [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTap]]
        performAction:[GREYActions actionForTypeText:@"foo"]]
        performAction:[GREYActions actionForClearText]]
        assertWithMatcher:grey_text(@"")];
  }];
}

- (void)testClearAfterTyping {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Foo"]]
        performAction:[GREYActions actionForClearText]]
        assertWithMatcher:grey_text(@"")];
  }];
}

- (void)testClearAfterClearing {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForClearText]]
        performAction:[GREYActions actionForClearText]]
        assertWithMatcher:grey_text(@"")];
  }];
}

- (void)testClearAndType_TypeShort {
  [targetApp executeSyncWithBlock:^{
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForClearText]]
        performAction:[GREYActions actionForTypeText:@"Foo"]]
        assertWithMatcher:grey_text(@"Foo")];
  }];
}

- (void)testTypeAfterClearing_ClearThenType {
  [targetApp executeSyncWithBlock:^{
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"f"]]
        assertWithMatcher:grey_text(@"f")];

    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForClearText]]
        performAction:[GREYActions actionForTypeText:@"g"]]
        assertWithMatcher:grey_text(@"g")];
  }];
}

- (void)testTypeAfterClearing_TypeLong {
  [targetApp executeSyncWithBlock:^{
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTypeText:@"This is a long string"]]
        assertWithMatcher:grey_text(@"This is a long string")];

    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForClearText]]
        performAction:[GREYActions actionForTypeText:@"short string"]]
        assertWithMatcher:grey_text(@"short string")];
  }];
}

- (void)testNonTypistKeyboardInteraction {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:[GREYActions actionForTap]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"a")]
        performAction:[GREYActions actionForTap]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"b")]
        performAction:[GREYActions actionForTap]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"c")]
        performAction:[GREYActions actionForTap]];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")]
        performAction:[GREYActions actionForTap]];
  }];
}

- (void)testNonTypingTextField {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey setFailureHandler:[[FTRFailureHandler alloc] init]];

    @try {
      [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NonTypingTextField")]
          performAction:[GREYActions actionForTypeText:@"Should Fail"]];
      GREYFail(@"Should throw an exception");
    } @catch (NSException *exception) {
      NSRange exceptionRange =
          [[exception reason] rangeOfString:@"Action 'Type \"Should Fail\"' failed."];
      GREYAssertTrue(exceptionRange.length > 0, @"Should throw exception indicating action failure.");
    }
  }];
}

- (void)testTypingWordsThatTriggerAutoCorrect {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"hekp";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_clearText()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
        performAction:grey_clearText()];

    string = @"helko";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_clearText()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
        performAction:grey_clearText()];

    string = @"balk";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_clearText()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
        performAction:grey_clearText()];

    string = @"surr";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testNumbersTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"1234567890";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testSymbolsTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"~!@#$%^&*()_+-={}:;<>?";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testLetterTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"aBc";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testEmailTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"donec.metus+spam@google.com";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testUpperCaseLettersTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"VERYLONGTEXTWITHMANYLETTERS";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testNumbersAndSpacesTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"0 1 2 3 4 5 6 7 8 9";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testSymbolsAndSpacesTyping {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"[ ] # + = _ < > { }";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testSpaceKey {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"a b";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:string];
  }];
}

- (void)testBackspaceKey {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"ab\b";
    NSString *verificationString = @"a";
    [FTRKeyboardKeysTest ftr_typeString:string andVerifyOutput:verificationString];
  }];
}

- (void)testReturnKey {
  [targetApp executeSyncWithBlock:^{
    Class kbViewClass = NSClassFromString(@"UIKeyboardImpl");
    NSString *textFieldString = @"and\n";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(textFieldString)]
        assertWithMatcher:grey_text(@"and")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)] assertWithMatcher:grey_nil()];

    NSString *string = @"and\nand";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(@"and\nand")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
        assertWithMatcher:grey_notNil()];
  }];
}

- (void)testAllReturnKeyTypes {
  [targetApp executeSyncWithBlock:^{
    Class kbViewClass = NSClassFromString(@"UIKeyboardImpl");
    // There are 11 returnKeyTypes; test all of them.
    for (int i = 0; i < 11; i++) {
      [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
          performAction:grey_typeText(@"a\n")]
          assertWithMatcher:grey_text(@"a")];

      [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
          assertWithMatcher:grey_nil()];

      [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
          performAction:grey_typeText(@"*\n")]
          assertWithMatcher:grey_text(@"a*")];

      [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
          assertWithMatcher:grey_nil()];

      [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"next returnKeyType")]
          performAction:grey_tap()];
    }
  }];
}

- (void)testPanelNavigation {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"a1a%a%1%";
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)];
  }];
}

- (void)testKeyplaneIsDetectedCorrectlyWhenSwitchingTextFields {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"$";

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeDefault {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Default"]];

    NSString *string = @":$a8. {T<b@CC";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeASCIICapable {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"ASCIICapable"]];

    NSString *string = @":$a8. {T<b@CC";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeNumbersAndPunctuation {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumbersAndPunctuation"]];

    NSString *string = @":$a8. {T<b@CC";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeURL {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"URL"]];

    NSString *string = @"http://www.google.com/@*s$&T+t?[]#testLabel%foo;";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeNumberPad {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumberPad"]];

    NSString *string = @"\b0123456\b789\b\b";
    NSString *verificationString = @"0123457";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(verificationString)];
  }];
}

- (void)testUIKeyboardTypePhonePad {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"PhonePad"]];

    NSString *string = @"01*23\b\b+45#67,89;";
    NSString *verificationString = @"01*+45#67,89;";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(verificationString)];
  }];
}

- (void)testUIKeyboardTypeEmailAddress {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"EmailAddress"]];

    NSString *string = @"l0rem.ipsum+42@google.com#$_T*-";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testUIKeyboardTypeDecimalPad {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"DecimalPad"]];

    NSString *string = @"\b0123.456\b78..9\b\b";
    NSString *verificationString = @"0123.4578.";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(verificationString)];
  }];
}

- (void)testUIKeyboardTypeTwitter {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Twitter"]];

    NSString *string = @"@earlgrey Your framework is #awesome!!!1$:,eG%g\n";
    NSString *verificationString = @"@earlgrey Your framework is #awesome!!!1$:,eG%g";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(verificationString)];
  }];
}

- (void)testUIKeyboardTypeWebSearch {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"WebSearch"]];

    NSString *string = @":$a8. {T<b@CC";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

- (void)testTypingOnLandscapeLeft {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"Cat")]
        assertWithMatcher:grey_text(@"Cat")];
  }];
}

- (void)testTypingOnLandscapeRight {
  [targetApp executeSyncWithBlock:^{
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"Cat")]
        assertWithMatcher:grey_text(@"Cat")];
  }];
}

- (void)testTogglingShiftByChangingCase {
  [targetApp executeSyncWithBlock:^{
    NSString *multiCaseString = @"aA1a1A1aA1AaAa1A1a";
    id<GREYAction> action =
        [GREYActionBlock actionWithName:@"ToggleShift"
                           performBlock:^(id element, __strong NSError **errorOrNil) {
          NSArray *shiftAXLabels =
              @[ @"shift", @"Shift", @"SHIFT", @"more, symbols", @"more, numbers", @"more", @"MORE" ];
          for (NSString *axLabel in shiftAXLabels) {
            NSError *error;
            [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(axLabel)]
                                performAction:grey_tap()
                                        error:&error];
          }
          return YES;
        }];

    for (NSUInteger i = 0; i < multiCaseString.length; i++) {
      NSString *currentCharacter = [multiCaseString substringWithRange:NSMakeRange(i, 1)];
      [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
          performAction:grey_typeText(currentCharacter)]
          performAction:action]
          assertWithMatcher:grey_text([multiCaseString substringToIndex:i + 1])];
    }

    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
     assertWithMatcher:grey_text(multiCaseString)];
  }];
}

- (void)testSuccessivelyTypingInTheSameTextField {
  [targetApp executeSyncWithBlock:^{
    [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"This ")]
        performAction:grey_typeText(@"Is A ")]
        performAction:grey_typeText(@"Test")]
        assertWithMatcher:grey_text(@"This Is A Test")];
  }];
}

- (void)testTypingBlankString {
  [targetApp executeSyncWithBlock:^{
    NSString *string = @"       ";
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(string)]
        assertWithMatcher:grey_text(string)];
  }];
}

#pragma mark - Private

+ (void)ftr_typeString:(NSString *)string andVerifyOutput:(NSString *)verificationString {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      performAction:grey_typeText(@"\n")]
      assertWithMatcher:grey_text(verificationString)];
  
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
  
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Done")]
      performAction:grey_tap()];
}

// Helper action that converts numeric position to UITextPosition.
+ (id<GREYAction>)ftr_actionForTypingText:(NSString *)text atPosition:(NSInteger)position {
  NSString *actionName =
      [NSString stringWithFormat:@"Test type \"%@\" at position %ld", text, (long)position];
  return [GREYActionBlock actionWithName:actionName
                             constraints:grey_not(grey_systemAlertViewShown())
                            performBlock:^BOOL (id element, __strong NSError **errorOrNil) {
      if ([element conformsToProtocol:@protocol(UITextInput)]) {
        UITextPosition *textPosition;
        if (position >= 0) {
          textPosition = [element positionFromPosition:[element beginningOfDocument]
                                                offset:position];
          if (!textPosition) {
            // Text position will be nil if the computed text position is greater than the length
            // of the backing string or less than zero. Since position is positive, the computed
            // value was past the end of the text field.
            textPosition = [element endOfDocument];
          }
        } else {
          // Position is negative. -1 should map to the end of the text field.
          textPosition = [element positionFromPosition:[element endOfDocument]
                                                offset:position + 1];
          if (!textPosition) {
            // Since position is positive, the computed value was past beginning of the text field.
            textPosition = [element beginningOfDocument];
          }
        }
        return [[GREYActions grey_actionForTypeText:text atUITextPosition:textPosition]
                   perform:element error:errorOrNil];
      } else {
        NSString *description = @"Position provided, but the element %@ does not conform to the "
                                @"UITextInput protocol.";
        [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                        withDomain:kGREYInteractionErrorDomain
                                              code:kGREYInteractionActionFailedErrorCode
                              andDescriptionFormat:description, element];
        return NO;
      }
  }];
}

@end
