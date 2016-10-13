//
//  LPAddressPath.h
//  Producer
//
//  Created by Paul Shapiro on 10/29/14.
//  Copyright (c) 2014 Lunarpad Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPAddressPath : NSObject

@property (nonatomic) NSUInteger section;
@property (nonatomic) NSUInteger row;

- (BOOL)isEqualToPath:(LPAddressPath *)addressPath;

@end
