//
//  LPAddressPath.m
//  DrawnTableView_MacOS_ObjC
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import "LPAddressPath.h"

@implementation LPAddressPath

- (NSString *)description
{
    NSString *superDescription = [super description];
    
    return [NSString stringWithFormat:@"%@ at (Section %lu, Row: %lu)", superDescription, self.section, self.row];
}

- (BOOL)isEqual:(id)object
{
    return [self isEqualTo:object];
}

- (BOOL)isEqualTo:(id)object
{
    if (![object isKindOfClass:[LPAddressPath class]]) {
        return NO;
    }
    
    return [self isEqualToPath:(LPAddressPath *)object];
}

- (BOOL)isEqualToPath:(LPAddressPath *)addressPath
{
    return self.section == addressPath.section && self.row == addressPath.row;
}

@end
