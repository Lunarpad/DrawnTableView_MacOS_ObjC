//
//  LPPaletteModulesDrawnTableView.m
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPPaletteModulesDrawnTableView.h"
#import "LPAppModulesPrototypesDirectory.h"
#import "LPAppModulePrototype.h"
#import "LPDrawnTableHeaderCellDrawingObject.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Macros



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants



////////////////////////////////////////////////////////////////////////////////
#pragma mark - C



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface LPPaletteModulesDrawnTableView ()

@property (nonatomic, weak) id<LPProjectDependencyHost> projectDependencyHost;
@property (nonatomic, strong) LPAppModulesPrototypesDirectory *prototypesDirectory;

@property (nonatomic, strong) NSArray *modelObjectsByRowBySection;

@property (nonatomic, strong) NSDictionary *cached_appModuleTitleStringAttributes;
@property (nonatomic, strong) NSDictionary *cached_selectedRowAppModuleTitleStringAttributes;
@property (nonatomic, strong) NSString *_searchQueryString;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation LPPaletteModulesDrawnTableView


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Entrypoints

- (id)initWithFrame:(NSRect)frameRect andProjectDependencyHost:(id<LPProjectDependencyHost>)projectDependencyHost
{
    self = [super initWithFrame:frameRect preSetupBlock:^(LPDrawnTableView *preSetupSelf)
    {
        LPPaletteModulesDrawnTableView *this = (LPPaletteModulesDrawnTableView *)preSetupSelf;
        this.projectDependencyHost = projectDependencyHost;
    }];
    
    return self;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Setup

- (void)setup
{
    { // Caches
        [self setupModel];
        [self setupDrawingCaches];
    }
    { // Table view
        typeof(self) __weak weakSelf = self;
        self.newModelObjectsByRowBySection = ^NSArray *
        {
            NSArray *array = weakSelf.modelObjectsByRowBySection;
            
            return array;
        };
        self.newHeightForRow = ^CGFloat(NSUInteger section, NSUInteger row)
        {
            if (row == 0) { // That's a header
                return 19;
            } else {
                return 29; // that's a cell
            }
        };
    }
    { // Scroll view
        self.hasVerticalScroller = YES;
    }
    
    [super setup];
}

- (void)setupModel
{
    self.prototypesDirectory = [[LPAppModulesPrototypesDirectory alloc] initWithHostProject:self.projectDependencyHost];
    // ^ this must exist
    
    [self regenerateModelObjects];
}

- (void)setupDrawingCaches
{
    self.cached_appModuleTitleStringAttributes = @
    {
        NSForegroundColorAttributeName : [NSColor colorWithWhite:0 alpha:1],
        NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue-Light" size:16]
    };
    self.cached_selectedRowAppModuleTitleStringAttributes = @
    {
        NSForegroundColorAttributeName : [NSColor colorWithWhite:1 alpha:1],
        NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue-Light" size:16]
    };
}

- (void)startObserving
{
    [super startObserving];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LPAppModulesPrototypesDirectory_notification_modelRegenerated) name:LPAppModulesPrototypesDirectory_notification_modelRegenerated object:nil];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors

- (NSArray *)_new_modelObjectsByRowBySection
{
    NSDictionary *prototypesByAppModuleTypeNumber = self.prototypesDirectory.insertableAppModulePrototypesByAppModuleTypeNumber;
    NSMutableArray *array = [NSMutableArray new];
    typeof(self) __weak weakSelf = self;
    [self.prototypesDirectory enumerateOrderedInsertableAppModuleTypesWithBlock:^(LPAppModuleType appModuleType, NSNumber *appModuleTypeNumber)
    {
        NSArray *prototypes = prototypesByAppModuleTypeNumber[appModuleTypeNumber];
        NSMutableArray *prototypesToAdd = nil;
        if (!weakSelf._searchQueryString.length) {
            prototypesToAdd = [prototypes mutableCopy];
        } else {
            prototypesToAdd = [NSMutableArray new];
            for (LPAppModulePrototype *prototype in prototypes) {
                if ([prototype matchesSearchQueryString:weakSelf._searchQueryString]) {
                    [prototypesToAdd addObject:prototype];
                }
            }
        }
        if (prototypesToAdd.count) {
            [prototypesToAdd insertObject:[weakSelf _newHeaderModelObjectForSectionOfAppModuleType:appModuleType]
                                  atIndex:0]; // Insert this header cell. Eventually, add internal table view support for headers
            [array addObject:prototypesToAdd];
        }
    }];
    
    return array;
}

- (id)_newHeaderModelObjectForSectionOfAppModuleType:(LPAppModuleType)appModuleType
{
    LPDrawnTableHeaderCellDrawingObject *object = [[LPDrawnTableHeaderCellDrawingObject alloc] init];
    object.backgroundColor = [NSColor blackColor];
    object.titleDisplayString = NSStringForCategoryDisplayFromAppModuleType(appModuleType);
    object.titleLabelTextColor = [NSColor whiteColor];
    object.titleLabelFont = [NSFont fontWithName:@"HelveticaNeue-Light" size:14];
    
    return object;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Overrides

- (void)_subclass_drawModelObject:(id)modelObject atAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame
{
    if ([modelObject isKindOfClass:[LPAppModulePrototype class]]) {
        [self _drawAppModulePrototype:(LPAppModulePrototype *)modelObject inRowCellFrame:rowFrame];
    } else if ([modelObject isKindOfClass:[LPDrawnTableHeaderCellDrawingObject class]]) {
        [self _drawTableHeaderCellDrawingObject:(LPDrawnTableHeaderCellDrawingObject *)modelObject inHeaderFrame:rowFrame];
    } else {
        DDLogInfo(@"I don't know how to draw this!! %@", modelObject);
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Drawing

- (void)_drawAppModulePrototype:(LPAppModulePrototype *)prototype inRowCellFrame:(NSRect)rowFrame
{
    BOOL isSelectedRow = NO;
    if ([self currentlySelectedRowModelObject] == prototype) {
        isSelectedRow = YES;
    }
    if (isSelectedRow) {
        [NSGraphicsContext saveGraphicsState];
        {
            NSRect backgroundFrame = NSMakeRect(rowFrame.origin.x, rowFrame.origin.y + 1, rowFrame.size.width, rowFrame.size.height - 1); // the 1 accounts for the preceeding cell's separator line width
            NSBezierPath *backgroundBezierPath = [NSBezierPath bezierPathWithRect:backgroundFrame];
            [[NSColor colorWithHexString:@"3874d6"] set];
            [backgroundBezierPath fill];
        }
        [NSGraphicsContext restoreGraphicsState];
    }
    
    CGFloat leftMargin = 25;
    NSRect stringDrawingFrame = NSMakeRect(rowFrame.origin.x + leftMargin, rowFrame.origin.y + 2, rowFrame.size.width - leftMargin, rowFrame.size.height);
    NSDictionary *stringDrawingAttributes = isSelectedRow ? self.cached_selectedRowAppModuleTitleStringAttributes : self.cached_appModuleTitleStringAttributes;
    NSAttributedString *drawingString = [[NSAttributedString alloc] initWithString:prototype.displayNameString attributes:stringDrawingAttributes];
    [drawingString drawInRect:stringDrawingFrame];
}

- (void)_drawTableHeaderCellDrawingObject:(LPDrawnTableHeaderCellDrawingObject *)headerCellDrawingObject inHeaderFrame:(NSRect)rowFrame
{
    CGFloat leftMargin = 6;
    NSRect drawingFrame = NSMakeRect(rowFrame.origin.x + leftMargin, rowFrame.origin.y - 4, rowFrame.size.width - leftMargin, rowFrame.size.height);
    [NSGraphicsContext saveGraphicsState];
    {
        if (headerCellDrawingObject.backgroundColor) {
            [headerCellDrawingObject.backgroundColor set];
            NSRectFill(rowFrame);
        }
        
        NSBezierPath *backgroundBezierPath = [NSBezierPath bezierPathWithRect:rowFrame];
        NSColor *startingColor;
        NSColor *endingColor;
        startingColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
        endingColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
        NSGradient *borderGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
        [borderGradient drawInBezierPath:backgroundBezierPath angle:-90];
        
        NSShadow *theShadow = [[NSShadow alloc] init];
        [theShadow setShadowOffset:CGSizeMake(0, 1)];
        [theShadow setShadowBlurRadius:0];
        [theShadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.2]];
        [theShadow set];
        
        [headerCellDrawingObject.titleLabelAttributeString drawInRect:drawingFrame]; // Drawing twice for 'strong' effect
    }
    [NSGraphicsContext restoreGraphicsState];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Data - Filtering

- (void)regenerateModelObjects
{
    self.modelObjectsByRowBySection = [self _new_modelObjectsByRowBySection];
}

- (void)setSearchQueryString:(NSString *)searchQueryString
{
    self._searchQueryString = searchQueryString;
    [[self tableDocumentView] unselectRowButDoNotDraw];
    [self regenerateModelObjects];
    [self reload]; // table view refresh method
    [self selectFirstRow];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Notifications

- (void)LPAppModulesPrototypesDirectory_notification_modelRegenerated
{
    id soonToBeStale_currentlySelectedModelObject = self.currentlySelectedRowModelObject;
    {
        [self regenerateModelObjects];
        [self reload];
    }
    [self reselectPreviouslySelectedModelObjectIfStillPresent_orSelectFirstRow:soonToBeStale_currentlySelectedModelObject];
}

@end
