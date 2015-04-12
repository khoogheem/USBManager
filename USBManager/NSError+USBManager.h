//
//  NSError+USBManager.h
//  USBManager
//
//  Created by Kevin A. Hoogheem on 4/11/15.
//  Copyright (c) 2015 Kevin A. Hoogheem. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const kUSBManagerErrorDomain;



@interface NSError (USBManager)


+ (NSError *)createErrorMessage:(NSString *)message withCode:(NSInteger)code;

@end
