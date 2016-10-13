//
//  LPDrawnTableHeaderCellDrawingObject.h
//  Producer
//
//  Created by Paul Shapiro on 10/30/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPDrawnTableHeaderCellDrawingObject : NSObject

@property (nonatomic, strong) NSColor *backgroundColor;

@property (nonatomic, copy) NSString *titleDisplayString;
@property (nonatomic, strong) NSColor *titleLabelTextColor;
@property (nonatomic, strong) NSFont *titleLabelFont;
- (NSAttributedString *)titleLabelAttributeString;

@end
