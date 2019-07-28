/*
    Grayscale - DisplayBrightness.h
 
    Based on display-brightness.c:
    https://github.com/pirate/mac-keyboard-brightness/blob/master/display-brightness.c
 
    History:
 
    v. 1.0.0 (07/27/2019) - Initial version
 
    Copyright (c) 2019 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
 
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>
#include "DisplayBrightness.h"

const static char *gIOServiceDisplayConnect = "IODisplayConnect";

/*
    IOServicePortFromCGDisplayID - returns the io_service_t corresponding
                                   to the specified display ID.  The
                                   io_service_t should be released with
                                   IOObjectRelease when not needed.
*/

static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_iterator_t iter;
    kern_return_t kern_err;
    io_service_t serv = 0, servicePort = 0;
    CFMutableDictionaryRef display = nil;
    CFDictionaryRef displayInfo = nil;
    CFNumberRef vendorIDRef = nil;
    CFNumberRef productIDRef = nil;
    CFNumberRef serialNumberRef = nil;
    Boolean success = FALSE;
    SInt32 vendorID = 0, productID = 0, serialNumber = 0;
    
    display = IOServiceMatching(gIOServiceDisplayConnect);
    if (display == 0)
    {
        return serv;
    }

    kern_err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                            display,
                                            &iter);
    if (kern_err)
    {
        return serv;
    }
    
    while ((serv = IOIteratorNext(iter)) != 0)
    {

        displayInfo = IODisplayCreateInfoDictionary(serv,
                                                    kIODisplayOnlyPreferredName);
        if (displayInfo == nil)
        {
            continue;
        }
        
        success =
            CFDictionaryGetValueIfPresent(displayInfo,
                                          CFSTR(kDisplayVendorID),
                                          (const void**) &vendorIDRef);
        success &=
            CFDictionaryGetValueIfPresent(displayInfo,
                                          CFSTR(kDisplayProductID),
                                          (const void**) &productIDRef);
        if (!success)
        {
            CFRelease(displayInfo);
            continue;
        }

        vendorID = 0;
        productID = 0;
        serialNumber = 0;
        
        CFNumberGetValue(vendorIDRef, kCFNumberSInt32Type, &vendorID);
        CFNumberGetValue(productIDRef, kCFNumberSInt32Type, &productID);

        // If a serial number is found, use it.
        // Otherwise serial number will be nil (= 0) which will match with
        // the output of 'CGDisplaySerialNumber'
        
        if (CFDictionaryGetValueIfPresent(displayInfo,
                                          CFSTR(kDisplaySerialNumber),
                                          (const void**) &serialNumberRef))
        {
            CFNumberGetValue(serialNumberRef, kCFNumberSInt32Type, &serialNumber);
        }

        // If the vendor and product id along with the serial don't match
        // then we are not looking at the correct monitor.
        // NOTE: The serial number is important in cases where two monitors
        //       are the exact same.
        
        if (CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID)  != productID ||
            CGDisplaySerialNumber(displayID) != serialNumber )
        {
            CFRelease(displayInfo);
            continue;
        }

        servicePort = serv;
        CFRelease(displayInfo);
        break;
    }

    IOObjectRelease(iter);
    return servicePort;
}

/* getMainDisplayBrightness - get the main display's brightness setting */

float getMainDisplayBrightness(void)
{
    CGDisplayErr dErr;
    io_service_t service;
    float brightness = 1.0;
    
    service = IOServicePortFromCGDisplayID(CGMainDisplayID());
    if (service == 0)
    {
        return brightness;
    }
    
    dErr = IODisplayGetFloatParameter(service,
                                      kNilOptions,
                                      CFSTR(kIODisplayBrightnessKey),
                                      &brightness);
    if (dErr)
    {
        brightness = 1.0;
    }
    
    IOObjectRelease(service);
    return brightness;
}

/* setMainDisplayBrightness - set the main display brightness */

void setMainDisplayBrightness(float brightness)
{
    io_service_t      service;

    service = IOServicePortFromCGDisplayID(CGMainDisplayID());
    if (service == 0)
    {
        return;
    }
    
    IODisplaySetFloatParameter(service,
                               kNilOptions,
                               CFSTR(kIODisplayBrightnessKey),
                               brightness);
    IOObjectRelease(service);
}
