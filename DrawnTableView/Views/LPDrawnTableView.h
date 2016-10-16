//
//  LPDrawnTableView.h
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LPAddressPath.h"
#import "LPDrawnTableDocumentView.h"

@interface LPDrawnTableView : NSScrollView


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frameRect;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization - Data source - Model objects (all of these must be implemented)

@property (nonatomic, copy) NSArray *(^newModelObjectsByRowBySection)(void);
@property (nonatomic, copy) BOOL (^areEqualModelObjects_block)(id obj1, id obj2);


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization - Data source - Cells

@property (nonatomic, copy) CGFloat(^newHeightForRow)(NSUInteger section, NSUInteger row);


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization - Delegation -- Interactions -- implement at will

@property (nonatomic, copy) void(^selectedRow)(id modelObject, LPAddressPath *addressPath);
@property (nonatomic, copy) void(^doubleClickedRow)(id modelObject, LPAddressPath *addressPath);


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Properties

- (NSArray *)modelObjectsByRowBySection;
- (id)modelObjectAtAddressPath:(LPAddressPath *)addressPath;
- (id)modelObjectWithIsEqualBlock:(BOOL(^)(id modelObject))block; // supply your own block to check for equality

- (LPAddressPath *)addressPathOfModelObject:(id)modelObject;

- (CGFloat)currentTotalScrollHeight;
- (LPAddressPath *)currentlySelectedRowAddressPath;
- (id)currentlySelectedRowModelObject;
- (LPDrawnTableDocumentView *)tableDocumentView;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives

- (void)reload; // called at -setup if self.newModelObjectsByRowBySection already set…… i.e. by a subclass

- (void)reload_withoutRedrawing;

- (void)reload_nonMainThreadAspects_withoutRedrawing;
- (void)reload_mainThreadAspects_withoutRedrawing;

- (void)redraw;

- (void)selectFirstRow;
- (void)reselectPreviouslySelectedModelObjectIfStillPresent_orSelectFirstRow:(id)previouslySelected_modelObject;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Methods for subclassers to override provided they are called on super

- (void)setup;
- (void)startObserving;

- (void)_rowSelectionChangedAndScrollToRow:(BOOL)scrollToRow;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - For subclassers to override without the need to call on super

- (void)_subclass_drawModelObject:(id)modelObject atAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame;

- (NSMenu *)new_menuForEvent:(NSEvent *)theEvent onRowAtAddressPath:(LPAddressPath *)path;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private, for document view usage only

- (void)_fromDocumentView_drawModelObjectAtAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame;
- (void)_documentView_selectedRowAtAddressPath:(LPAddressPath *)path andScrollToRow:(BOOL)scrollToRow;
- (void)_documentView_selectedRowAtAddressPathButDoNotDraw:(LPAddressPath *)path;
- (void)_documentView_unselectedRow;
- (void)_documentView_unselectedRowAndDoNotDraw;

- (void)_documentView_doubleClicked_rowAtPath:(LPAddressPath *)path;

@end
