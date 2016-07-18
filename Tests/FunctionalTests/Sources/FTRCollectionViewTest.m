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

@interface FTRCollectionViewTest : FTRBaseIntegrationTest
@end

@implementation FTRCollectionViewTest

- (void)setUp {
  [super setUp];
  
  [targetApp executeSyncWithBlock:^{
    [FTRCollectionViewTest openTestViewNamed:@"Collection Views"];
  }];
}

- (void)testSearchActionWithCollectionViewHorizontalLayout {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"layoutPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Horizontal Layout"]];
    // For reference this is how A, B, C, X, Y and Z are laid out using the horizontal layout:
    // A ... X
    // B ... Y
    // C ... Z
    // . ...
    // This test will search and find A, B, C, X, Y and Z and tap them.

    // Scroll to left to find A, B and C.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionLeft untilInteractableWithChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'B'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'C'];

    // Scroll to right to find X Y and Z.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionRight untilInteractableWithChar:'Z'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'X'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Y'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Z'];
  }];
}

- (void)testSearchActionWithCollectionViewVerticalLayout {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"layoutPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Vertical Layout"]];
    // For reference this is how A, B, C, X, Y and Z are laid out using the vertical layout:
    // A B C .
    // . . . .
    // . . . .
    // . . . .
    // X Y Z
    // This test will search and find A, B, C, X, Y and Z and tap them.

    // Scroll to top to find A, B and C.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionUp untilInteractableWithChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'B'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'C'];

    // Scroll to bottom to find X, Y and Z.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionDown untilInteractableWithChar:'Z'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'X'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Y'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Z'];
  }];
}

- (void)testSearchActionWithCollectionViewCustomLayout {
  [targetApp executeSyncWithBlock:^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"layoutPicker")]
        performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Custom Layout"]];

    // For reference this is how A, B, C, X, Y and Z are laid out using the custom layout:
    // A B C ...
    // ...
    // ...     X
    // Y Z
    // This test will search and find A, B, C, X, Y and Z and tap them.

    // Scroll to top left for A, B and C.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionLeft untilInteractableWithChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'A'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'B'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'C'];

    // Scroll to bottom to find Z.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionDown untilInteractableWithChar:'Z'];

    // Scroll to bottom-right to find X and tap it.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionRight untilInteractableWithChar:'X'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'X'];

    // Scroll to bottom-left to find Y and Z.
    [FTRCollectionViewTest ftr_scrollInDirection:kGREYDirectionLeft untilInteractableWithChar:'Y'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Y'];
    [FTRCollectionViewTest ftr_verifyTapOnChar:'Z'];
  }];
}

#pragma mark - Private

+ (void)ftr_verifyTapOnChar:(char)ch {
  NSString *previous = [NSString stringWithFormat:@"%c", ch];
  NSString *next = [NSString stringWithFormat:@"%d", toupper(ch)];
  [[EarlGrey selectElementWithMatcher:grey_text(previous)] performAction:grey_tap()];
  [EarlGrey selectElementWithMatcher:grey_text(next)];
}

// Scrolls the test CollectionView containing alphabets in the given |direction| until the given
// char is interactable.
+ (void)ftr_scrollInDirection:(GREYDirection)direction untilInteractableWithChar:(char)aChar {
  // Spelling these out separately to align the following code properly making it more readable.
  id<GREYMatcher> charMatcher = grey_text([NSString stringWithFormat:@"%c", aChar]);
  id<GREYAction> scrollAction = grey_scrollInDirection(direction, 50);
  id<GREYMatcher> searchActionElementMatcher = grey_accessibilityID(@"Alphabets");
  [[[EarlGrey selectElementWithMatcher:grey_allOf(charMatcher, grey_interactable(), nil)]
    usingSearchAction:scrollAction onElementWithMatcher:searchActionElementMatcher]
   assertWithMatcher:grey_interactable()];
}

@end
