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
	uint8 _usbBuffer[MAX_RECORD_LEN];
	
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
		IOHIDDeviceRegisterInputReportCallback(_deviceRef, _usbBuffer, MAX_RECORD_LEN, Handle_HIDDeviceReportCallback, (__bridge void*)self);
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

- (NSInteger)maxInputReportSize {
    return [self numberForUSBPropertyKey:CFSTR(kIOHIDMaxInputReportSizeKey)];
}

- (NSInteger)maxOutputReportSize {
    return [self numberForUSBPropertyKey:CFSTR(kIOHIDMaxOutputReportSizeKey)];
}


#pragma mark - Get Report

- (uint8_t *)getReportPage:(signed long)page reportType:(reportType)controltype {

    NSParameterAssert((controltype == reportTypeFeature) || (controltype == reportTypeInput));

    IOReturn tIOReturn;
    IOHIDReportType type;

    if (controltype == reportTypeFeature) {
        type = kIOHIDReportTypeFeature;
    } else {
        type = kIOHIDReportTypeInput;
    }

    uint8_t *report = (uint8_t *)calloc(64, sizeof(uint8_t));
    CFIndex len = 64;

    tIOReturn = IOHIDDeviceGetReport(_deviceRef, type, page, report, &len);

    return report;
}

#pragma mark - Send Messages


- (void)sendOutputReport:(NSData *)msg error:(NSError __autoreleasing * __nullable *)_error{

    UInt8 *byteData = (UInt8 *)msg.bytes;
    uint8_t *data_to_send;
    size_t length_to_send;

    if (byteData[0] == 0x0) {
        /* Not using numbered Reports.
         Don't send the report number. */
        data_to_send = byteData + 1;
        length_to_send = msg.length - 1;
    } else {
        /* Using numbered Reports.
         Send the Report Number */
        data_to_send = byteData;
        length_to_send = msg.length;
    }

    [self sendMessageToHostWithData:msg reportPage:byteData[0] reportType:kIOHIDReportTypeOutput length:length_to_send error:_error];
}

- (void)sendFeatureReport:(NSData *)msg error:(NSError __autoreleasing * __nullable *)_error{

    UInt8 *byteData = (UInt8 *)msg.bytes;
    uint8_t *data_to_send;
    size_t length_to_send;

    if (byteData[0] == 0x0) {
        /* Not using numbered Reports.
         Don't send the report number. */
        data_to_send = byteData + 1;
        length_to_send = msg.length - 1;
    } else {
        /* Using numbered Reports.
         Send the Report Number */
        data_to_send = byteData;
        length_to_send = msg.length;
    }

    [self sendMessageToHostWithData:msg reportPage:byteData[0] reportType:kIOHIDReportTypeFeature length:length_to_send error:_error];
}


- (void)sendMessageToHostWithData:(NSData *)data reportPage:(signed long)page reportType:(IOHIDReportType)controltype length:(CFIndex)length error:(NSError __autoreleasing * __nullable *)_error{
	
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
									 byteData,
                                     length);
	
	
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
	}
}

- (void)processInput:(uint8 *)byteData withLength:(signed long)length {
	
	NSData *data = [NSData dataWithBytes:byteData length:(NSUInteger)length];
	
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didReceiveNewInputData:)]) {
		[self.delegate didReceiveNewInputData:data];
	}
	
}

#pragma mark - Private

- (NSString *)stringForUSBPropertyKey:(CFStringRef)key {
	return (__bridge NSString *)(IOHIDDeviceGetProperty(_deviceRef, key));
}

- (NSInteger)numberForUSBPropertyKey:(CFStringRef)key {
    NSNumber *product = (__bridge NSNumber *)(IOHIDDeviceGetProperty(_deviceRef, key));
    return [product integerValue];
}


- (id)propertyForKey:(NSString *)key {
	return ((__bridge id)IOHIDDeviceGetProperty(_deviceRef, (__bridge CFStringRef)key));
}


@end
