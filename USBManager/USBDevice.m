//
//  USBDevice.m
//  USBManager
//
//  Created by Kevin A. Hoogheem on 4/11/15.
//  Copyright (c) 2015 Kevin A. Hoogheem. All rights reserved.
//

#import "USBDevice.h"
#import "USBDevice_Private.h"
#import "NSError+USBManager.h"
#import <IOKit/serial/IOSerialKeys.h>

const int MAX_RECORD_LEN = 512;

// Forward declarations
static void Handle_HIDDeviceReportCallback(void *context,
										   IOReturn result,
										   void *sender,
										   IOHIDReportType type,
										   uint32_t reportID,
										   uint8_t *report,
										   CFIndex reportLength);


@interface USBDevice () {
	//Input Buffer
	uint8 _buffer[MAX_RECORD_LEN];
	
}

@end

@implementation USBDevice

- (instancetype)initWithDevice:(IOHIDDeviceRef)device {
	
	self = [super init];
	
	if (self != nil) {
		_deviceRef = device;
		
		if (![self setupDevice:device]) {
			return nil;
		}
	}
	
	return self;
}

- (BOOL)setupDevice:(IOHIDDeviceRef)device {
	
	IOReturn result = IOHIDDeviceOpen(_deviceRef, kIOHIDOptionsTypeSeizeDevice);
	
	if (result == kIOReturnSuccess) {
		// Add a method to be called when there is data from the device
		IOHIDDeviceRegisterInputReportCallback(_deviceRef, _buffer, MAX_RECORD_LEN, Handle_HIDDeviceReportCallback, (__bridge void*)self);
		CFRetain(_deviceRef);
		
		// Schedule in this run loop
		IOHIDDeviceScheduleWithRunLoop(_deviceRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
				
		return TRUE;
	}
	
	return FALSE;
}

- (void)dealloc {
	
	IOHIDDeviceUnscheduleFromRunLoop(_deviceRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(_deviceRef);
}

#pragma mark - Properties

- (NSString *)productName {
	return [self stringForUSBPropertyKey:CFSTR(kIOHIDProductKey)];
}

- (NSString *)serialNumber {
	return [self stringForUSBPropertyKey:CFSTR(kIOHIDSerialNumberKey)];
}

- (NSString *)manufacturerName {
	return [self stringForUSBPropertyKey:CFSTR(kIOHIDManufacturerKey)];
}

#pragma mark - Send Messages

- (void)sendControlInMessage:(NSData *)msg error:(NSError __autoreleasing * __nullable *)_error{
	[self sendControlInMessage:msg withReportPage:0x0 error:_error];
}

- (void)sendControlInMessage:(NSData * __nonnull)msg withReportPage:(long)report error:(NSError *__autoreleasing  __nullable *)_error {
	[self sendMessageToHostWithData:msg reportPage:report reportType:kIOHIDReportTypeInput error:_error];
}


- (void)sendControlOutMessage:(NSData *)msg error:(NSError __autoreleasing * __nullable *)_error{
	[self sendControlOutMessage:msg withReportPage:0x0 error:_error];
}

- (void)sendControlOutMessage:(NSData * __nonnull)msg withReportPage:(long)report error:(NSError *__autoreleasing  __nullable *)_error {
	[self sendMessageToHostWithData:msg reportPage:report reportType:kIOHIDReportTypeOutput error:_error];
}



- (void)sendMessageToHostWithData:(NSData *)data reportPage:(signed long)page reportType:(IOHIDReportType)controltype error:(NSError __autoreleasing * __nullable *)_error{
	
	UInt8 *byteData = (UInt8 *)[data bytes];
	
#if DEBUG_PRINT
	printf("Output device %p MSG: ", _deviceRef);
	for (int i = 0; i < 8; i++) {
		printf("%02X", byteData[i]);
	}
	printf("\n");
#endif
	
	IOReturn tIOReturn;
	
	tIOReturn = IOHIDDeviceSetReport(_deviceRef,
									 controltype,
									 page, /* Report ID*/
									 byteData, data.length);
	
	
	if (tIOReturn == kIOReturnSuccess) {
		
	} else {
		NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:tIOReturn userInfo:nil];		
		NSString *errMsg = [NSString stringWithFormat:@"%s: IOHIDDeviceSetReport error: 0x%08u (%@).",
							__PRETTY_FUNCTION__,
							tIOReturn,
							error.localizedDescription];
		
		if (_error != nil) {
			*_error = [NSError createErrorMessage:errMsg withCode:400];
		}

	}
	
}

#pragma mark - Callback

// Callback
static void Handle_HIDDeviceReportCallback(void *context, IOReturn result, void *sender, IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex reportLength) {

#if DEBUG_PRINT
	printf("\n[");
	for (int i = 0; i < reportLength; i++) {
		printf("%02X ", report[i]);
	}
	printf("]");
#endif
	
	USBDevice *device = (__bridge USBDevice *)context;
	
	if (type == kIOHIDReportTypeInput) {
		[device processInput:report withLength:reportLength];
	} else if (type == kIOHIDReportTypeOutput) {
		[device processOutput:report withLength:reportLength];
	}
}

- (void)processInput:(uint8 *)byteData withLength:(signed long)length {
	
	NSData *data = [NSData dataWithBytes:byteData length:(NSUInteger)length];
	
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didReceiveNewInputData:)]) {
		[self.delegate didReceiveNewInputData:data];
	}
	
}

- (void)processOutput:(uint8 *)byteData withLength:(signed long)length {
	
	NSData *data = [NSData dataWithBytes:byteData length:(NSUInteger)length];
	
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didReceiveNewOutputData:)]) {
		[self.delegate didReceiveNewOutputData:data];
	}
}


#pragma mark - Private

- (NSString *)stringForUSBPropertyKey:(CFStringRef)key {
	return (__bridge NSString *)(IOHIDDeviceGetProperty(_deviceRef, key));
}

- (id)propertyForKey:(NSString *)key {
	return ((__bridge id)IOHIDDeviceGetProperty(_deviceRef, (__bridge CFStringRef)key));
}


@end
