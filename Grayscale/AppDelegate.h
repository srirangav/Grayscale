/*
    Grayscale - AppDelegate.h
 
    History:
 
    v. 1.0.0 (01/17/2019) - Initial version
    v. 1.1.0 (07/22/2019) - Add night shift and dark mode support
 
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

#import <Cocoa/Cocoa.h>
#import "CBBlueLightClient.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu *GSMenu;
    IBOutlet NSMenuItem *GSMenuItemToggleGrayScale;
    IBOutlet NSMenuItem *GSMenuItemToggleNightShift;
    IBOutlet NSSlider *GSMenuItemNightShiftSlider;
    IBOutlet NSMenuItem *GSMenuItemToggleDarkMode;
    IBOutlet NSMenuItem *GSMenuItemQuit;
    NSUserDefaults *GSDefaults;
    CBBlueLightClient *GSBlueLightClient;
    float nightShiftStrength;
    BOOL grayScale;
    BOOL nightShift;
    BOOL darkMode;
}

- (void) actionToggleGrayScale: (id)sender;
- (void) actionToggleNightShift: (id)sender;
- (void) actionNightShiftSliderValueChanged: (id)sender;
- (void) updateNightShift;
- (void) actionToggleDarkMode: (id)sender;

@end
