//
//  LPDrawnTableHeaderCellDrawingObject.m
//  Producer
//
//  Created by Paul Shapiro on 10/30/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPDrawnTableHeaderCellDrawingObject.h"



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Macros



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants



////////////////////////////////////////////////////////////////////////////////
#pragma mark - C



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface LPDrawnTableHeaderCellDrawingObject ()

@property (nonatomic, strong) NSDictionary *__titleLabelStringAttributes;
@property (nonatomic, strong) NSAttributedString *__titleLabelAttributeString;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation LPDrawnTableHeaderCellDrawingObject

- (NSDictionary *)titleLabelStringAttributes
{
    if (!self.__titleLabelStringAttributes) {
        self.__titleLabelStringAttributes = @
        {
            NSForegroundColorAttributeName : self.titleLabelTextColor,
            NSFontAttributeName : self.titleLabelFont
        };
    }
    
    return self.__titleLabelStringAttributes;
}

- (NSAttributedString *)titleLabelAttributeString
{
    if (!self.__titleLabelAttributeString) {
        self.__titleLabelAttributeString = [[NSAttributedString alloc] initWithString:self.titleDisplayString attributes:[self titleLabelStringAttributes]];
    }
    
    return self.__titleLabelAttributeString;
}

- (void)invalidateTitleLabelAttributedString
{
    self.__titleLabelAttributeString = nil;
}

@end
