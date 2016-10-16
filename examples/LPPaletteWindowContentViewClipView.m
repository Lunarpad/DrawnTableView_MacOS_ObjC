//
//  LPPaletteWindowContentViewClipView.m
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPPaletteWindowContentViewClipView.h"
#import "LPPaletteModulesDrawnTableView.h"
#import "LPPaletteWindowContentWebView.h"
#import "LPAppModulePrototype.h"
#import "LPProject.h"
#import "LPAppModulesController.h"
#import "LPPaletteSearchInputTextField.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Macros



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants



////////////////////////////////////////////////////////////////////////////////
#pragma mark - C



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface LPPaletteWindowContentViewClipView ()
<
    NSTextFieldDelegate,
    WebPolicyDelegate
>

@property (nonatomic, weak) id<LPProjectDependencyHost> projectDependencyHost;

@property (nonatomic, strong) LPPaletteSearchInputTextField *searchInputTextField;
@property (nonatomic, strong, readwrite) LPPaletteModulesDrawnTableView *modulesTableView;
@property (nonatomic, strong) LPPaletteWindowContentWebView *contentWebView;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation LPPaletteWindowContentViewClipView


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle - Imperatives - Entrypoints

- (id)initWithFrame:(NSRect)frame projectDependencyHost:(id<LPProjectDependencyHost>)projectDependencyHost
{
    self = [super initWithFrame:frame];
    if (self) {
        self.projectDependencyHost = projectDependencyHost;
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
    self.wantsLayer = YES;

    self.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:1].CGColor;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4;
        
    [self setup_searchInputTextField];
    [self setup_modulesTableView];
    [self setup_contentWebView];
    
    [self startObserving];
}

- (void)setup_searchInputTextField
{
    LPPaletteSearchInputTextField *view = [[LPPaletteSearchInputTextField alloc] initWithFrame:[self _new_searchInputTextField_frame]];
    view.focusRingType = NSFocusRingTypeNone;
    view.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:22];
    view.textColor = [NSColor colorWithWhite:0.1 alpha:1];
    view.placeholderString = NSLocalizedString(@"Search Elements Library", nil);
    view.bezeled = NO;
    [view setBordered:NO];
    view.delegate = self;
    view.action = @selector(searchInputReturnKeyPressed);
    view.target = self;
    
    self.searchInputTextField = view;
    [self addSubview:view];
}

- (void)setup_modulesTableView
{
    typeof(self) __weak weakSelf = self;
    LPPaletteModulesDrawnTableView *view = [[LPPaletteModulesDrawnTableView alloc] initWithFrame:[self _newModulesTableViewFrame] andProjectDependencyHost:self.projectDependencyHost];
    view.selectedRow = ^(id modelObject, LPAddressPath *path)
    {
        if (modelObject && [modelObject isKindOfClass:[LPAppModulePrototype class]]) {
            [weakSelf.contentWebView configureContentWithAppModulePrototype:(LPAppModulePrototype *)modelObject];
        } else {
            [weakSelf.contentWebView clearContent];
        }
    };
    view.doubleClickedRow = ^(id modelObject, LPAddressPath *path)
    {
        [weakSelf rowDoubleClicked];
    };
    self.modulesTableView = view;
    [self addSubview:view];
}

- (void)setup_contentWebView
{
    LPPaletteWindowContentWebView *view = [[LPPaletteWindowContentWebView alloc] initWithFrame:[self _new_contentWebView_frame] frameName:nil groupName:nil];
    view.policyDelegate = self;
    self.contentWebView = view;
    [self addSubview:view];
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
#pragma mark - Runtime - Accessors - Lookups

- (LPAppModulePrototype *)currentlySelectedTableRowAppModulePrototype
{
    return [self.modulesTableView currentlySelectedRowModelObject];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Accessors - Factories

- (NSRect)_newModulesTableViewFrame
{
    CGFloat y = 0;
    CGFloat w = [self _modulesTableViewWidth];
    
    return NSMakeRect(0, y, w, self.frame.size.height - [self _newModalContentHeaderHeight]);
}

- (CGFloat)_modulesTableViewWidth
{
    return 320;
}

- (NSRect)_new_searchInputTextField_frame
{
    CGFloat xMargin = 6;
    CGFloat h = [self searchInputTextFieldHeight];
    CGFloat y = self.frame.size.height - h - 4;
    CGFloat w = self.frame.size.width - 2*xMargin;
    
    return NSMakeRect(xMargin, y, w, h);
}

- (NSRect)_new_contentWebView_frame
{
    CGFloat xMargin = 6;
    CGFloat h = self.frame.size.height - [self _newModalContentHeaderHeight];
    CGFloat y = 0;
    CGFloat w = self.frame.size.width - 2*xMargin - self._modulesTableViewWidth;
    
    return NSMakeRect(xMargin + [self _modulesTableViewWidth], y, w, h);
}

- (CGFloat)searchInputTextFieldHeight
{
    return 30;
}

- (CGFloat)_newModalContentHeaderHeight
{
    return 38;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives - Overrides

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    [NSGraphicsContext saveGraphicsState];
    {
        NSBezierPath *searchInputBarBottomBorderPath = [NSBezierPath bezierPath];
        CGFloat y = self.frame.size.height - [self _newModalContentHeaderHeight] + 0.5;
        [searchInputBarBottomBorderPath moveToPoint:NSMakePoint(0, y)];
        [searchInputBarBottomBorderPath lineToPoint:NSMakePoint(self.frame.size.width, y)];
        
        [[NSColor colorWithWhite:0 alpha:0.2] set];
        [searchInputBarBottomBorderPath stroke];
    }
    [NSGraphicsContext restoreGraphicsState];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Imperatives

- (void)setSearchQueryString:(NSString *)searchQueryString
{
    self.searchInputTextField.stringValue = searchQueryString.length ? searchQueryString : @"";
    [self.modulesTableView setSearchQueryString:searchQueryString];
}

- (void)dismissPaletteWindow
{
    if (self.dismissPaletteWindowBlock) {
        self.dismissPaletteWindowBlock();
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Search input text field

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSString *newSearchQuery = self.searchInputTextField.stringValue;
    [self.modulesTableView setSearchQueryString:newSearchQuery];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(moveUp:)) {
        [[self.modulesTableView tableDocumentView] selectPreviousNonHeaderRow];
        
        return YES;
    }
    if (commandSelector == @selector(moveDown:)) {
        [[self.modulesTableView tableDocumentView] selectNextNonHeaderRow];
        
        return YES;
    }
    
    return NO;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation - Internal

- (void)searchInputReturnKeyPressed
{
    if (self.searchInputReturnKeyPressedBlock) {
        self.searchInputReturnKeyPressedBlock();
    }
}

- (void)rowDoubleClicked
{
    if (self.rowDoubleClicked_block) {
        self.rowDoubleClicked_block();
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime - Delegation

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    { //Here we handle whether to load this or open it in Safari/Chrome/whatever default browser they use
        NSString *host = [[request URL] host];
        if (host) {
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        } else {
            [listener use];
        }
    }
}

@end
