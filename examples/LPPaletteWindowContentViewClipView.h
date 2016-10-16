//
//  LPPaletteWindowContentViewClipView.h
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LPProject.h"
#import "LPVisualEffectView.h"
@class LPPaletteModulesDrawnTableView;
@class LPAppModulePrototype;

@interface LPPaletteWindowContentViewClipView : LPVisualEffectView

- (id)initWithFrame:(NSRect)frame projectDependencyHost:(id<LPProjectDependencyHost>)projectDependencyHost;

- (void)setSearchQueryString:(NSString *)searchQueryString;
@property (nonatomic, strong, readonly) LPPaletteModulesDrawnTableView *modulesTableView;
- (LPAppModulePrototype *)currentlySelectedTableRowAppModulePrototype;

@property (nonatomic, copy) void(^dismissPaletteWindowBlock)(void);
@property (nonatomic, copy) void(^searchInputReturnKeyPressedBlock)(void);
@property (nonatomic, copy) void(^rowDoubleClicked_block)(void);

@end
