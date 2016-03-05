//
//  USBDevice.h
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

typedef NS_ENUM(uint8_t, reportType) {
    reportTypeFeature  = 0,
    reportTypeInput    = 1,

};

@protocol USBDeviceDelegate;

@interface USBDevice : NSObject


@property (nonatomic, nullable) id<USBDeviceDelegate> delegate;

///---------------------------------------------------------------------------------------
/// @name Device Information
///---------------------------------------------------------------------------------------

/**
The USB Product Name for the USBDevice.
*/
@property (nonatomic, readonly, nullable) NSString *productName;

/**
 The Serial Number for the USBDevice
 */
@property (nonatomic, readonly, nullable) NSString *serialNumber;

/**
 The USB Manufacturer Key
 */
@property (nonatomic, readonly, nullable) NSString *manufacturerName;

///---------------------------------------------------------------------------------------
/// @name Messaging
///---------------------------------------------------------------------------------------


/**
 Gets a Report Page of either OUTPUT or FEATURE
 
 @params page The Report Page
 @param controlType The USB Report type
 @returns Report Data
 */
- (uint8_t * __nullable)getReportPage:(signed long)page reportType:(reportType)controltype;

/**
 Sends a Message to the Output report of the USB.
 
 @param msg The byte array to send to the USB Device
 @param error Any errors in sending will be sent back
 */
- (void)sendOutputReport:(NSData * __nonnull)msg error:(NSError __autoreleasing * __nullable * __nullable)error;

/**
 Sends a Message to the Feature report of the USB.

 @param msg The byte array to send to the USB Device
 @param error Any errors in sending will be sent back
 */
- (void)sendFeatureReport:(NSData * __nonnull)msg error:(NSError __autoreleasing * __nullable * __nullable)error;

@end


@protocol USBDeviceDelegate <NSObject>

@optional

/**
 Called when there is new Data From Input report
 */
- (void)didReceiveNewInputData:(NSData * __nullable)data;

@end