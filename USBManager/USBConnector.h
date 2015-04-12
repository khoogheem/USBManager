//
//  USBConnector.h
//  USBManager
//
//  Created by Kevin A. Hoogheem on 4/11/15.
//  Copyright (c) 2015 Kevin A. Hoogheem. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import <Foundation/Foundation.h>

@class USBDevice;
@protocol USBConnectorDelegate;

/**
 USBConnector is responsible for listening to the USB Hub and reporting on Attachment and Removal of USB Devices.
 
 */
NS_CLASS_AVAILABLE_MAC(10_5)
@interface USBConnector : NSObject


/**
 The Shared Manager for the USB Hardware Connector
 */
+ (nullable instancetype)sharedManager;

/**
 An Array of connected USB Devices
 
 @note May be nil
 */
@property (nonatomic, readonly, nullable) NSArray *devices;


///---------------------------------------------------------------------------------------
/// @name Setup
///---------------------------------------------------------------------------------------

/**
 Starts monitoring for USB Devices that match the <i>vendor</i> and <i>product</i>
 
 Will throw back errors on failure of setup or success (200)
 
 @param vendor The USB Vendor ID
 @param product The USB Product ID
 @param error Any Errors that occur during the Monitor setup phase.  Will return <b>200</b> on success
 */
- (void)startMonitoringForVendorID:(NSInteger)vendor andProductID:(NSInteger)product error:(NSError *__autoreleasing  __nullable * __nullable)error;

/**
 Delegate for monitoring Device Attachment and Removal
 */
@property (nonatomic, weak, nullable) id<USBConnectorDelegate> delegate;


@end



@protocol USBConnectorDelegate <NSObject>

@optional

/**
 Called when a new USB Device has been attached to the USB Bus
 
 @param usbmngr An instance of the USBConnector
 @param device The USBDevice that has been connected
 */
- (void)usbConnector:(USBConnector * __nonnull)usbmngr didAttachDevice:(USBDevice * __nonnull)device;

/**
 Called when a new USB Device has been removed from  the USB Bus
 
 @param usbmngr An instance of the USBConnector
 @param device The USBDevice that has been removed
 */
- (void)usbConnector:(USBConnector * __nonnull)usbmngr didRemoveDevice:(USBDevice * __nonnull)device;

@end
