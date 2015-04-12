//
//  NSError+USBManager.m
//  USBManager
//
//  Created by Kevin A. Hoogheem on 4/11/15.
//  Copyright (c) 2015 Kevin A. Hoogheem. All rights reserved.
//

#import "NSError+USBManager.h"

NSString * const kUSBManagerErrorDomain = @"net.hoogheem.USBManager";


@implementation NSError (USBManager)


+ (NSError *)createErrorMessage:(NSString *)message withCode:(NSInteger)_code {
	
	if (message.length) {
		return [NSError errorWithDomain:kUSBManagerErrorDomain code:_code userInfo:@{NSLocalizedDescriptionKey: message}];
	}else {
		return [NSError errorWithDomain:kUSBManagerErrorDomain code:_code userInfo:nil];
	}
	
}

@end
