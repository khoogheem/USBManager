//
//  USBConnector.m
//  USBManager
//
//  Created by Kevin A. Hoogheem on 4/11/15.
//  Copyright (c) 2015 Kevin A. Hoogheem. All rights reserved.
//

#import "USBConnector.h"
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/serial/IOSerialKeys.h>

#import "NSError+USBManager.h"
#import "USBDevice.h"
#import "USBDevice_Private.h"

// Forward declaration of callbacks
static void Handle_DeviceRemovalCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device);
static void Handle_DeviceMatchingCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device);


@interface USBConnector ()

@property (nonatomic, assign) IOHIDManagerRef       iOManager;
@property (nonatomic, strong) NSMutableOrderedSet   *setOfDevices;
@end

@implementation USBConnector

+ (instancetype)sharedManager {
	static dispatch_once_t onceToken;
	static USBConnector *instance;
	
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] initManager];
	});
	
	return instance;
}

- (instancetype)init {
	NSLog(@"Init should not be called directly.  Use one of the designated Shared instance methods");
	[super doesNotRecognizeSelector:_cmd];
	return nil;
}

- (instancetype)initManager {
	
	self = [super init];
	
	if (self != nil) {
		_setOfDevices = [[NSMutableOrderedSet alloc] init];
		
		_iOManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
		
		if (_iOManager == nil){
			NSLog(@"%s: Could not create IOHIDManager.\n", __PRETTY_FUNCTION__);
			return nil;
		}
	}
	
	return self;
}

- (void)dealloc {
	
	[_setOfDevices removeAllObjects];
	
	if (_iOManager != nil) {
		IOHIDManagerClose(_iOManager, kIOHIDOptionsTypeNone);
		CFRelease(_iOManager);
	}
}

#pragma mark - Monitor

- (void)startMonitoringForVendorID:(NSInteger)vendor andProductID:(NSInteger)product error:(NSError __autoreleasing * __nullable *)_error{

	
	// Create a dictionary for USB matching criteria
	CFMutableDictionaryRef matchingCFDictRef = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	if (matchingCFDictRef == nil) {
		if (_error != nil) {
			*_error = [NSError createErrorMessage:@"Unable to create Matching Dictionary" withCode:400];
		}
		return;
	}

	// Set the matching criteria
	CFDictionarySetValue(matchingCFDictRef, CFSTR(kIOHIDVendorIDKey), (__bridge const void *)(@(vendor)));
	CFDictionarySetValue(matchingCFDictRef, CFSTR(kIOHIDProductIDKey), (__bridge const void *)@(product));

	//Register the Callbacks
	IOHIDManagerRegisterDeviceRemovalCallback(_iOManager, Handle_DeviceRemovalCallback, (__bridge void*)self);
	IOHIDManagerRegisterDeviceMatchingCallback(_iOManager, Handle_DeviceMatchingCallback, (__bridge void*)self);
	
	//Create the Run Loop
	IOHIDManagerScheduleWithRunLoop(_iOManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	// Set the HID device matching dictionary
	IOHIDManagerSetDeviceMatching(_iOManager, matchingCFDictRef);

	// Now open the IO HID Manager reference
	IOReturn tIOReturn = IOHIDManagerOpen(_iOManager, kIOHIDOptionsTypeNone);
	
	if (tIOReturn != kIOReturnSuccess) {
		NSError *localerr = [NSError errorWithDomain:NSOSStatusErrorDomain code:tIOReturn userInfo:nil];
		
		if (_error != nil) {
			*_error = [NSError createErrorMessage:[NSString stringWithFormat:@"IOHIDManagerOpen error: 0x%08u %@",tIOReturn, localerr.localizedDescription] withCode:localerr.code];
		}
		return;
	}
	
	if (_error != nil) {
		*_error = [NSError createErrorMessage:[NSString stringWithFormat:@"IOHIDManager (%@) created and opened!", self] withCode:200];
	}
	
//	NSLog(@"USBConnector Monitoring started: %d, %d", (int)vendor, (int)product);

}

- (NSArray *)devices {
	return _setOfDevices.array;
}


#pragma mark - Device Mngt

- (void)addUSBDevice:(IOHIDDeviceRef)device {
	
	//Create the USB Device
//	NSString *serial = (__bridge NSString *)(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDSerialNumberKey)));
	USBDevice *usbDev = [[USBDevice alloc] initWithDevice:device];
	
	if (usbDev) {
		[self willChangeValueForKey:@"devices"];
		[_setOfDevices addObject:usbDev];
		[self didChangeValueForKey:@"devices"];
		
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(usbConnector:didAttachDevice:)]) {
			[self.delegate usbConnector:self didAttachDevice:usbDev];
		}
	}

}

- (void)removeUSBDevice:(IOHIDDeviceRef)device {
	
	NSOrderedSet *set = [_setOfDevices copy];
	
	[set enumerateObjectsUsingBlock:^(USBDevice *obj, NSUInteger idx, BOOL *stop) {
		if (obj.deviceRef == device) {
			
			[self willChangeValueForKey:@"devices"];
			[_setOfDevices removeObject:obj];
			[self didChangeValueForKey:@"devices"];
			
			
			//Notify Delegate
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(usbConnector:didRemoveDevice:)]) {
				[self.delegate usbConnector:self didRemoveDevice:obj];
			}
			*stop = TRUE;
		}
		
	}];

}


@end


#pragma mark - Callbacks

@implementation USBConnector (Callbacks)


static void Handle_DeviceRemovalCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
	NSLog(@"%s Mngr: %@, Device Removed: %@", __PRETTY_FUNCTION__, context, device);
	
	//Create an instance of self
	USBConnector *mng = (__bridge USBConnector *)context;
	[mng removeUSBDevice:device];
	
}

static void Handle_DeviceMatchingCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
	NSLog(@"%s Mngr: %@, Device Found: %@", __PRETTY_FUNCTION__, context, device);
	
	//Create an instance of self
	USBConnector *mng = (__bridge USBConnector *)context;
	[mng addUSBDevice:device];
	
}



@end