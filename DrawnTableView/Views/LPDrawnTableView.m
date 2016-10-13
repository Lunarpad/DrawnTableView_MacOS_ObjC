//
//  LPDrawnTableView.m
//  Producer
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPDrawnTableView.h"
#import "LPDrawnTableDocumentView.h"
#import <Quartz/Quartz.h>
#import "LPDrawnTableHeaderCellDrawingObject.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Macros



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants



////////////////////////////////////////////////////////////////////////////////
#pragma mark - C



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface LPDrawnTableView ()

@property (nonatomic, strong, readwrite) NSArray *__modelObjectsByRowBySection;
@property (nonatomic) CGFloat __currentTotalScrollHeight;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation LPDrawnTableView


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Entrypoints

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)dealloc
{
    [self teardown];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Setup

- (void)setup
{
    [self setupDocumentView];
    if (self.newModelObjectsByRowBySection) {
        [self reload];
        [self scrollToTop];
    }
    [self startObserving];
}

- (void)setupDocumentView
{
    [self setDocumentView:[[LPDrawnTableDocumentView alloc] initWithFrame:self.bounds]];
}

- (void)startObserving
{
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Teardown

- (void)teardown
{
    [self stopObserving];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Overrides

- (BOOL)canBecomeKeyView
{
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Overridable

- (NSMenu *)new_menuForEvent:(NSEvent *)theEvent onRowAtAddressPath:(LPAddressPath *)path { return nil; } // by default, no menus


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Lookups

- (id)modelObjectAtAddressPath:(LPAddressPath *)addressPath
{
    if (self.__modelObjectsByRowBySection.count > addressPath.section) {
        NSArray *section = self.__modelObjectsByRowBySection[addressPath.section];
        if (section.count > addressPath.row) {
            return section[addressPath.row];
        }
    }
    
    return nil;
}

- (id)modelObjectWithIsEqualBlock:(BOOL(^)(id modelObject))block
{
    for (NSArray *modelObjectsByRow in self.__modelObjectsByRowBySection) {
        for (id modelObject in modelObjectsByRow) {
            if (block(modelObject) == YES) {
                return modelObject;
            }
        }
    }
    
    return nil;
}

- (NSArray *)modelObjectsByRowBySection
{
    return self.__modelObjectsByRowBySection;
}

- (CGFloat)currentTotalScrollHeight
{
    return self.__currentTotalScrollHeight;
}

- (LPDrawnTableDocumentView *)tableDocumentView
{
    return (LPDrawnTableDocumentView *)self.documentView;
}

- (LPAddressPath *)currentlySelectedRowAddressPath
{
    return [self.tableDocumentView selectedRowAddressPath];
}

- (id)currentlySelectedRowModelObject
{
    LPAddressPath *path = [self currentlySelectedRowAddressPath];
    if (path) {
        id object = [self modelObjectAtAddressPath:path];
        if (!object) {
            DDLogError(@"currentlySelectedRowAddressPath exists, but corresponding model object was nil! Unselecting the row.");
            [[self tableDocumentView] unselectRowButDoNotDraw];
        }
        
        return object;
    }
    
    return nil;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Lookups - Factories

- (LPAddressPath *)addressPathOfModelObject:(id)modelObject
{
    NSArray *modelObjectsByRowBySection = self.modelObjectsByRowBySection;
    NSUInteger sectionIndex = 0;
    for (NSArray *section in modelObjectsByRowBySection) {
        NSUInteger numberOfRows = section.count;
        for (NSUInteger rowIndex = 0 ; rowIndex < numberOfRows ; rowIndex++) {
            id thisModelObject = section[rowIndex];
            BOOL areEqual;
            {
                if (self.areEqualModelObjects_block) {
                    areEqual = self.areEqualModelObjects_block(thisModelObject, modelObject);
                } else if ([modelObject respondsToSelector:@selector(isEqual:)]
                           && [thisModelObject respondsToSelector:@selector(isEqual:)]) {
                    areEqual = [thisModelObject isEqual:modelObject];
                } else {
                    DDLogWarn(@"areEqualModelObjects_block not provided, so falling back to model obj reference equality checking.");
                    areEqual = thisModelObject == modelObject; // fallback
                }
                if (areEqual) {
                    LPAddressPath *path = [LPAddressPath new];
                    path.section = sectionIndex;
                    path.row = rowIndex;
                    
                    return path;
                }
            }
        }
        sectionIndex++;
    }
//    DDLogWarn(@"Address path not found for model object %@", modelObject);
    
    return nil;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Factories

- (CGFloat)_new__currentTotalScrollHeight
{
    CGFloat h = 0;
    NSUInteger numberOfSections = self.modelObjectsByRowBySection.count;
    for (NSUInteger section = 0 ; section < numberOfSections ; section++) {
        NSArray *sectionRows = self.modelObjectsByRowBySection[section];
        NSUInteger numberOfRows = sectionRows.count;
        for (NSUInteger row = 0 ; row < numberOfRows ; row++) {
            h += self.newHeightForRow(section, row);
        }
    }
    
    return h;
}

- (NSPoint)_newTopScrollPoint
{
    return NSMakePoint(0, 0);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Loading

- (void)reload
{
    [self reload_withoutRedrawing];
    [self redraw];
}

- (void)reload_withoutRedrawing
{
    [self reload_nonMainThreadAspects_withoutRedrawing];
    [self reload_mainThreadAspects_withoutRedrawing];
}

- (void)reload_nonMainThreadAspects_withoutRedrawing
{
    self.__modelObjectsByRowBySection = self.newModelObjectsByRowBySection();
    self.__currentTotalScrollHeight = [self _new__currentTotalScrollHeight];
}

- (void)reload_mainThreadAspects_withoutRedrawing
{
    [self.tableDocumentView reconfigureFromDrawnTableView:self];
}

- (void)redraw
{
    [self setNeedsDisplay:YES];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Selection - Convenience

- (void)selectFirstRow
{
    if (self.modelObjectsByRowBySection.count != 0) {
        LPAddressPath *addressPath = [LPAddressPath new];
        addressPath.section = 0;
        addressPath.row = 1; // 1 for the header -- so this will select the first app module
        [[self tableDocumentView] selectRowAtAddressPath:addressPath andScrollToRow:YES];
    } else {
        [[self tableDocumentView] unselectRow];
    }
}

- (void)reselectPreviouslySelectedModelObjectIfStillPresent_orSelectFirstRow:(id)previouslySelected_modelObject
{
    if (!previouslySelected_modelObject) {
        [self selectFirstRow];  // nothing was selected before
        
        return;
    }
    NSUInteger section = NSNotFound;
    NSUInteger row = NSNotFound;
    {
        NSUInteger i = 0;
        for (NSArray *rows in self.modelObjectsByRowBySection) {
            if (section != NSNotFound) { // found it - exit
                break;
            }
            NSUInteger j = 0;
            for (id modelObject in rows) {
                if ([modelObject isEqualTo:previouslySelected_modelObject]) {
                    section = i;
                    row = j;
                    
                    break;
                }
                
                j++;
            }
            
            i++;
        }
    }
    if (section != NSNotFound
        && row != NSNotFound) {
        LPAddressPath *addressPath = [LPAddressPath new];
        addressPath.section = section;
        addressPath.row = row;
        
        [[self tableDocumentView] selectRowAtAddressPath:addressPath
                                          andScrollToRow:NO];
    } else {
        DDLogWarn(@"Currently selected object not found in attempt to re-select it.");
        
        [self selectFirstRow];
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Scrolling

- (void)scrollToTop
{
    [self scrollToTopAnimated:NO];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    [self scrollToPoint:[self _newTopScrollPoint] animated:animated];
}

- (void)scrollToPoint:(NSPoint)point animated:(BOOL)animated
{
    if (![NSThread isMainThread]) {
        typeof(self) __weak weakSelf = self;
        [LPConcurrency performBlockOnMainQueue:^
        {
            [weakSelf scrollToPoint:point animated:animated];
        }];
        
        return;
    }
    [NSAnimationContext beginGrouping];
    if (animated) {
        [[NSAnimationContext currentContext] setDuration:0.3];
        [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    } else {
        [[NSAnimationContext currentContext] setDuration:0.05];
        [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    }
    [[self.contentView animator] setBoundsOrigin:point];
    [NSAnimationContext endGrouping];
}

- (void)scrollToRowAtAddressPath:(LPAddressPath *)path
{
    NSRect rowFrame = [self.tableDocumentView newFrameForRowAtAddressPath:path];
    rowFrame.origin.y -= self.frame.size.height/2 - rowFrame.size.height;
    [self scrollToPoint:rowFrame.origin animated:NO];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Cell drawing

- (void)_fromDocumentView_drawModelObjectAtAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame
{
    id modelObject = [self modelObjectAtAddressPath:path];
    [self _subclass_drawModelObject:modelObject atAddressPath:path withFrame:rowFrame];
}

- (void)_subclass_drawModelObject:(id)modelObject atAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame
{
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Overrides

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

- (void)setNeedsDisplay:(BOOL)needsDisplay
{
    [super setNeedsDisplay:needsDisplay];
    
    [self.documentView setNeedsDisplay:needsDisplay];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];

    [[self tableDocumentView] reconfigureLayoutOnlyFromDrawnTableView]; // make it update widths
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Internal

- (void)_rowSelectionChangedAndScrollToRow:(BOOL)scrollToRow
{
    LPAddressPath *path = [self currentlySelectedRowAddressPath];
    if (self.selectedRow) {
        self.selectedRow([self currentlySelectedRowModelObject], path);
    }
    if (path) {
        if (scrollToRow) {
            [self scrollToRowAtAddressPath:path];
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Document view - Interactions

- (void)_documentView_selectedRowAtAddressPath:(LPAddressPath *)path andScrollToRow:(BOOL)scrollToRow
{
    [self redraw];
    [self _rowSelectionChangedAndScrollToRow:scrollToRow];
}

- (void)_documentView_selectedRowAtAddressPathButDoNotDraw:(LPAddressPath *)path
{
    [self _rowSelectionChangedAndScrollToRow:YES];
}

- (void)_documentView_unselectedRow
{
    [self redraw];
    [self _rowSelectionChangedAndScrollToRow:YES];
}

- (void)_documentView_unselectedRowAndDoNotDraw
{
    [self _rowSelectionChangedAndScrollToRow:YES];
}

- (void)_documentView_doubleClicked_rowAtPath:(LPAddressPath *)path
{
    if (path) {
        if (self.doubleClickedRow) {
            id modelObject = [self modelObjectAtAddressPath:path];
            self.doubleClickedRow(modelObject, path);
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Responder

- (void)mouseUp:(NSEvent *)theEvent
{ // this should not override/intercept clicks for the document itself
    [[self tableDocumentView] unselectRow]; // deselection on bg click
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - UI - Interactions

- (void)moveDown:(id)sender
{
    if ([self currentlySelectedRowAddressPath] != nil) {
        [[self tableDocumentView] selectNextNonHeaderRow];
    } else {
        [[self tableDocumentView] selectAndScrollToFirstRowIfExists];
    }
}

- (void)moveUp:(id)sender
{
    if ([self currentlySelectedRowAddressPath] != nil) {
        [[self tableDocumentView] selectPreviousNonHeaderRow];
    } else {
        [[self tableDocumentView] selectAndScrollToLastRowIfExists];
    }
}

@end
