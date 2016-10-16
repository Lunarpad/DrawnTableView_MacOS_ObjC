//
//  LPDrawnTableDocumentView.m
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPDrawnTableDocumentView.h"
#import "LPDrawnTableView.h"
#import "LPDrawnTableHeaderCellDrawingObject.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Macros



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants



////////////////////////////////////////////////////////////////////////////////
#pragma mark - C



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface LPDrawnTableDocumentView ()

@property (nonatomic) BOOL shouldNOTDrawSeparators;
@property (nonatomic) BOOL shouldToggleRowsOnClick;

@property (nonatomic, weak) LPDrawnTableView *parentDrawnTableView;
@property (nonatomic, strong, readwrite) LPAddressPath *selectedRowAddressPath;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation LPDrawnTableDocumentView


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Overrides

- (BOOL)isFlipped
{
    return YES;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors

- (NSArray *)modelObjectsByRowBySection
{
    return self.parentDrawnTableView.modelObjectsByRowBySection;
}

- (NSArray *)addressPathsOfModelObjectsInRect:(NSRect)rect
{
    NSArray *modelObjectsByRowBySection = self.parentDrawnTableView.modelObjectsByRowBySection;
    NSMutableArray *addressPaths = [NSMutableArray new];
    NSUInteger sectionIndex = 0;
    for (NSArray *section in modelObjectsByRowBySection) {
        NSUInteger numberOfRows = section.count;
        for (NSUInteger rowIndex = 0 ; rowIndex < numberOfRows ; rowIndex++) {
            LPAddressPath *path = [LPAddressPath new];
            path.section = sectionIndex;
            path.row = rowIndex;
            if ([self _isRowAtAddressPath:path inRect:rect]) {
                
                [addressPaths addObject:path];
            }
        }
        sectionIndex++;
    }
    
    return addressPaths;
}

- (LPAddressPath *)addressPathOfModelObjectUnderMousePoint:(NSPoint)point
{
    NSArray *modelObjectsByRowBySection = self.parentDrawnTableView.modelObjectsByRowBySection;
    NSUInteger sectionIndex = 0;
    for (NSArray *section in modelObjectsByRowBySection) {
        NSUInteger numberOfRows = section.count;
        for (NSUInteger rowIndex = 0 ; rowIndex < numberOfRows ; rowIndex++) {
            LPAddressPath *path = [LPAddressPath new];
            path.section = sectionIndex;
            path.row = rowIndex;
            NSRect rowFrame = [self _newFrameForRowAtAddressPath:path];
            if (NSMouseInRect(point, rowFrame, YES)) {
                return path;
            }
        }
        sectionIndex++;
    }
    
    return nil;
}

- (BOOL)_isRowAtAddressPath:(LPAddressPath *)path inRect:(NSRect)rect
{
    NSRect rowFrame = [self _newFrameForRowAtAddressPath:path];
    
    return NSIntersectsRect(rect, rowFrame);
}

- (BOOL)isRowVisibleAtAddressPath:(LPAddressPath *)path
{
    return [self _isRowAtAddressPath:path inRect:self.parentDrawnTableView.documentVisibleRect];
}

- (BOOL)isRowFullyVisibleAtAddressPath:(LPAddressPath *)path
{
    NSRect rowFrame = [self _newFrameForRowAtAddressPath:path];
    rowFrame.origin.y -= 2; // in case there's a false positive by something being basically on screen but not quite
    rowFrame.size.height -= 4;
    rowFrame.size.width = 10; // to account with great margin for any width changed by the insertion of the scroll bar
    
    return NSContainsRect(self.parentDrawnTableView.documentVisibleRect, rowFrame);
}

- (NSRect)_newFrameForRowAtAddressPath:(LPAddressPath *)addressPath
{
    LPDrawnTableView *parentDrawnTableView = self.parentDrawnTableView;
    CGFloat(^newHeightForRow_block)(NSUInteger section, NSUInteger row) = parentDrawnTableView.newHeightForRow;
    NSArray *modelObjectsByRowBySection = parentDrawnTableView.modelObjectsByRowBySection;
    
    CGFloat y = 0;
    NSUInteger addressPathSection = addressPath.section;
    NSUInteger addressPathRow = addressPath.row;

    for (NSUInteger section = 0 ; section <= addressPathSection ; section++) { // inclusive
        NSUInteger numberOfRowsInSection = ((NSArray *)modelObjectsByRowBySection[section]).count;
        for (NSUInteger row = 0 ; row < numberOfRowsInSection ; row++) { // not inclusive
            if (addressPathSection == section) {
                if (row >= addressPathRow) {
                    break; // early terminate so as not to add the H of the addressPath row to the y
                }
            }
            CGFloat precedingRowHeight = newHeightForRow_block(section, row);
            y += precedingRowHeight;
        }
    }
    CGFloat h = newHeightForRow_block(addressPathSection, addressPathRow);
    
    return NSMakeRect(0, y, self.frame.size.width, h);
}

- (NSRect)newFrameForRowAtAddressPath:(LPAddressPath *)path
{
    return [self _newFrameForRowAtAddressPath:path];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Overridable



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives

- (void)reconfigureFromDrawnTableView:(LPDrawnTableView *)parentDrawnTableView
{
    self.parentDrawnTableView = parentDrawnTableView;
    [self reconfigureLayoutOnlyFromDrawnTableView];
}

- (void)reconfigureLayoutOnlyFromDrawnTableView
{
    [self setFrame:NSMakeRect(0, 0, self.parentDrawnTableView.frame.size.width, self.parentDrawnTableView.currentTotalScrollHeight)];
}

- (void)setShouldDrawSeparators:(BOOL)shouldDrawSeparators
{
    self.shouldNOTDrawSeparators = !shouldDrawSeparators;
}

- (void)setShouldToggleRowsInsteadOfOnlySelectingOnUponClick:(BOOL)shouldToggleRows
{
    self.shouldToggleRowsOnClick = shouldToggleRows;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Row selection

- (void)_toggleSelectOfRowUnderPoint:(NSPoint)point
{
    LPAddressPath *path = [self addressPathOfModelObjectUnderMousePoint:point];
    if (self.selectedRowAddressPath && [self.selectedRowAddressPath isEqualToPath:path]) {
        [self unselectRow];
    } else {
        [self selectRowAtAddressPath:path andScrollToRow:NO]; // do not scroll, or it will move from under the point!
    }
}

- (void)_selectRowUnderPoint:(NSPoint)point
{
    LPAddressPath *path = [self addressPathOfModelObjectUnderMousePoint:point];
    if (self.selectedRowAddressPath && [self.selectedRowAddressPath isEqualToPath:path]) {
        // nothing to do here
    } else {
        [self selectRowAtAddressPath:path andScrollToRow:NO]; // do not scroll, or it will move from under the point!
    }
}

- (void)selectRowAtAddressPath:(LPAddressPath *)path andScrollToRow:(BOOL)scrollToRow
{
    if ([self.parentDrawnTableView modelObjectAtAddressPath:path] == nil) {
        DDLogWarn(@"No table row at path (s%lu, r%lu).", path.section, path.row);
        NSBeep();
        
        return;
    }
    self.selectedRowAddressPath = path;
    [self.parentDrawnTableView _documentView_selectedRowAtAddressPath:path andScrollToRow:scrollToRow];
}

- (void)selectRowAtAddressPathButDoNotDraw:(LPAddressPath *)path
{
    self.selectedRowAddressPath = path;
    [self.parentDrawnTableView _documentView_selectedRowAtAddressPathButDoNotDraw:path];
}

- (void)unselectRow
{
    self.selectedRowAddressPath = nil;
    [self.parentDrawnTableView _documentView_unselectedRow];
}

- (void)unselectRowButDoNotDraw
{
    self.selectedRowAddressPath = nil;
    [self.parentDrawnTableView _documentView_unselectedRowAndDoNotDraw];
}

- (void)selectPreviousNonHeaderRow
{
    LPAddressPath *currentlySelectedPath = self.selectedRowAddressPath;
    if (!currentlySelectedPath) {
        NSBeep();
        
        return;
    }
    NSInteger newSection = currentlySelectedPath.section;
    NSInteger newRow = currentlySelectedPath.row - 1;
    while (newRow < 0) {
        newSection--;
        if (newSection < 0) {
            return; // can't go back further
        }
        newRow = [self.parentDrawnTableView.modelObjectsByRowBySection[newSection] count] - 1;
    }
    while ([self.parentDrawnTableView.modelObjectsByRowBySection[newSection][newRow] isKindOfClass:[LPDrawnTableHeaderCellDrawingObject class]]) {
        newRow--;
        while (newRow <= 0) {
            newSection--;
            if (newSection < 0) {
                return; // can't go back further
            }
            newRow = [self.parentDrawnTableView.modelObjectsByRowBySection[newSection] count] - 1;
        }
    }
    LPAddressPath *newPath = [[LPAddressPath alloc] init];
    newPath.section = newSection;
    newPath.row = newRow;
    [self selectRowAtAddressPath:newPath andScrollToRow:YES];
}

- (void)selectNextNonHeaderRow
{
    LPAddressPath *currentlySelectedPath = self.selectedRowAddressPath;
    if (!currentlySelectedPath) {
        NSBeep();
        
        return;
    }
    NSInteger newSection = currentlySelectedPath.section;
    NSInteger newRow = currentlySelectedPath.row + 1;
    { // Advance sections until we find one with elements
        while (newRow >= [self.parentDrawnTableView.modelObjectsByRowBySection[newSection] count]) {
            newSection++;
            if (newSection == self.parentDrawnTableView.modelObjectsByRowBySection.count) {
                return; // can't go forward any further
            }
            newRow = 0;
        }
    }
    while ([self.parentDrawnTableView.modelObjectsByRowBySection[newSection][newRow] isKindOfClass:[LPDrawnTableHeaderCellDrawingObject class]]) {
        newRow++;
        while (newRow >= [self.parentDrawnTableView.modelObjectsByRowBySection[newSection] count]) {
            newSection++;
            if (newSection == self.parentDrawnTableView.modelObjectsByRowBySection.count) {
                return; // can't go forward any further
            }
            newRow = 0;
        }
    }
    LPAddressPath *newPath = [[LPAddressPath alloc] init];
    newPath.section = newSection;
    newPath.row = newRow;
    [self selectRowAtAddressPath:newPath andScrollToRow:YES];
}

- (void)selectAndScrollToFirstRowIfExists
{
    LPAddressPath *path = [LPAddressPath new];
    {
        path.section = 0;
        path.row = 0;
    }
    [self selectRowAtAddressPath:path andScrollToRow:YES];
}

- (void)selectAndScrollToLastRowIfExists
{
    NSArray *modelObjectsByRowsBySection = self.parentDrawnTableView.modelObjectsByRowBySection;
    NSUInteger indexOfLastSection = modelObjectsByRowsBySection.count ? modelObjectsByRowsBySection.count - 1 : NSNotFound;
    if (indexOfLastSection == NSNotFound) {
        NSBeep();
        
        return;
    }
    NSArray *modelObjectsByRowInLastSection = modelObjectsByRowsBySection[indexOfLastSection];
    NSUInteger indexOfLastRowInLastSection = modelObjectsByRowInLastSection.count ? modelObjectsByRowInLastSection.count - 1 : NSNotFound;
    if (indexOfLastRowInLastSection == NSNotFound) {
        DDLogWarn(@"tech debt: %@ does not know how to skip to a previous section if the last section has no rows in it in %@.", [self class], NSStringFromSelector(_cmd));
        NSBeep();
        
        return;
    }
    LPAddressPath *path = [LPAddressPath new];
    {
        path.section = indexOfLastSection;
        path.row = indexOfLastRowInLastSection;
    }
    [self selectRowAtAddressPath:path andScrollToRow:YES];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Overrides

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    { // Draw any row cells which are visible
        NSArray *addressPaths = [self addressPathsOfModelObjectsInRect:dirtyRect];
        for (id addressPath in addressPaths) {
            [self _drawModelObjectAtAddressPath:addressPath inRect:dirtyRect];
        }
    }
}

- (void)_drawModelObjectAtAddressPath:(LPAddressPath *)addressPath inRect:(NSRect)dirtyRect
{
    NSRect rowFrame = [self _newFrameForRowAtAddressPath:addressPath];
    { // Bottom separator
        if (!self.shouldNOTDrawSeparators) {
            NSColor *separatorColor = [NSColor colorWithWhite:0 alpha:0.2];
            if (separatorColor) {
                NSBezierPath *path = [[NSBezierPath alloc] init];
                CGFloat separatorY = rowFrame.origin.y + rowFrame.size.height + 0.5;
                [path moveToPoint:NSMakePoint(0, separatorY)];
                [path lineToPoint:NSMakePoint(rowFrame.size.width, separatorY)];
                path.lineWidth = 1;
                [separatorColor set];
                [path stroke];
            }
        }
    }
    { // Allow the table view to dictate cell contents drawing
        [self.parentDrawnTableView _fromDocumentView_drawModelObjectAtAddressPath:addressPath withFrame:rowFrame];
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Overrides

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSPoint locationInWindow = theEvent.locationInWindow;
    NSPoint locationInView = [self.superview convertPoint:locationInWindow fromView:nil];
    { // Select the item
        if (theEvent.clickCount == 1) { // just select it
            [self handleSingleClickAtLocationInView:locationInView];
        }
    }
    LPAddressPath *path = [self addressPathOfModelObjectUnderMousePoint:locationInView];
    if (path != nil) {
        return [self.parentDrawnTableView new_menuForEvent:theEvent onRowAtAddressPath:path];
    }
    
    return nil;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint locationInWindow = theEvent.locationInWindow;
    NSPoint locationInView = [self.superview convertPoint:locationInWindow fromView:nil];
    if (theEvent.clickCount == 1) {
        [self handleSingleClickAtLocationInView:locationInView];
    } else if (theEvent.clickCount == 2) {
        [self handleDoubleClickAtLocationInView:locationInView];
    } else {
        DDLogWarn(@"Unhandled number of clicks %ld in %@.", theEvent.clickCount, [self class]);
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

- (void)handleSingleClickAtLocationInView:(NSPoint)locationInView
{
    if (self.shouldToggleRowsOnClick) {
        [self _toggleSelectOfRowUnderPoint:locationInView];
    } else { // default behavior
        [self _selectRowUnderPoint:locationInView];
    }
}

- (void)handleDoubleClickAtLocationInView:(NSPoint)locationInView
{
    LPAddressPath *path = [self addressPathOfModelObjectUnderMousePoint:locationInView];
    [self.parentDrawnTableView _documentView_doubleClicked_rowAtPath:path];
}

@end
