//
//  LPPaletteModulesDrawnTableView.h
//  Producer
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPDrawnTableView.h"
#import "LPProject.h"

@interface LPPaletteModulesDrawnTableView : LPDrawnTableView

- (id)initWithFrame:(NSRect)frameRect andProjectDependencyHost:(id<LPProjectDependencyHost>)projectDependencyHost;

- (void)setSearchQueryString:(NSString *)searchQueryString;

@end
