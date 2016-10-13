//
//  LPDrawnTableDocumentView.h
//  Producer
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LPAddressPath.h"
@class LPDrawnTableView;

@interface LPDrawnTableDocumentView : NSView

- (void)setShouldDrawSeparators:(BOOL)shouldDrawSeparators;
- (void)setShouldToggleRowsInsteadOfOnlySelectingOnUponClick:(BOOL)shouldToggleRows;

- (void)reconfigureFromDrawnTableView:(LPDrawnTableView *)parentDrawnTableView; // sets self.parentDrawnTableView and also calls -reconfigureLayoutOnlyFromDrawnTableView
- (void)reconfigureLayoutOnlyFromDrawnTableView;


@property (nonatomic, strong, readonly) LPAddressPath *selectedRowAddressPath;
- (void)selectRowAtAddressPathButDoNotDraw:(LPAddressPath *)path;
- (void)selectRowAtAddressPath:(LPAddressPath *)path andScrollToRow:(BOOL)scrollToRow;

- (void)selectAndScrollToFirstRowIfExists;
- (void)selectAndScrollToLastRowIfExists;
- (void)selectPreviousNonHeaderRow;
- (void)selectNextNonHeaderRow;

- (void)unselectRow;
- (void)unselectRowButDoNotDraw;

- (NSRect)newFrameForRowAtAddressPath:(LPAddressPath *)path;
- (BOOL)isRowVisibleAtAddressPath:(LPAddressPath *)path;
- (BOOL)isRowFullyVisibleAtAddressPath:(LPAddressPath *)path;

@end
