/*
    Grayscale - AppDelegate.m
 
    History:
 
    v. 1.0.0 (01/17/2019) - Initial version
    v. 1.1.0 (07/22/2019) - Add nightshift and darkmode support
    v. 1.1.1 (07/27/2019) - Add brightness support, fixes for MacOSX 10.14
 
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

#import <ApplicationServices/ApplicationServices.h>
#import <ServiceManagement/ServiceManagement.h>
#import "AppDelegate.h"
#import "Prefs.h"
#import "DisplayBrightness.h"

/* external functions */

CG_EXTERN void CGDisplayForceToGray(BOOL forceToGray);

/*
    Private APIs for setting dark mode:
    https://gist.github.com/avaidyam/6d0e3605cf85b10f4d0f9d654518e984
    https://saagarjha.com/blog/2018/12/01/scheduling-dark-mode/
 */

extern BOOL SLSGetAppearanceThemeLegacy(void);
extern BOOL SLSSetAppearanceThemeNotifying(BOOL mode, BOOL notifyListeners);

/* Constants */

/* Menu title */

NSString *gMenuTitle = @"GS";

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    NSArray *apps = nil;
    NSRunningApplication *app = nil;
    BOOL startedAtLogin = FALSE;
    
    /*
        Create the status item:
        http://preserve.mactech.com/articles/mactech/Vol.22/22.02/Menulet/index.html
        http://www.sonsothunder.com/devres/livecode/tutorials/StatusMenu.html
     */
    
    self.statusItem = [[NSStatusBar systemStatusBar]
                       statusItemWithLength: NSVariableStatusItemLength];
    [self.statusItem setMenu: GSMenu];
    self.statusItem.button.title = gMenuTitle;
    
    /*
        Get the current interface setting mode - light / dark. Based on:
        https://saagarjha.com/blog/2018/12/01/scheduling-dark-mode/
        https://github.com/mafredri/macos-darkmode/blob/master/cmd/darkmode/main.go
     */
    
    darkMode = SLSGetAppearanceThemeLegacy();
    
    /*
          Set the current status of night shift. See:
          https://github.com/jenghis/nshift/blob/master/nshift/main.m
          https://github.com/elanini/NightShifter/blob/master/CBBlueLightClient.h
     */
    
    nightShift = FALSE;
    nightShiftStrength = 0.0;
    
    GSBlueLightClient = [[CBBlueLightClient alloc] init];
    if (GSBlueLightClient != nil)
    {
        [GSBlueLightClient getStrength: &nightShiftStrength];
        
        /* The night shift strength should be between 0-1 */
        
        if (nightShiftStrength > 1.0)
        {
            nightShiftStrength = 1.0;
        }
    }
    
    /* get the current value of the main display's brightness setting */
    
    brightness = getMainDisplayBrightness();
    
    /*
        Create a preference group to share preferences with the login
        helper app:
        https://stackoverflow.com/questions/14014417/reading-nsuserdefaults-from-helper-app-in-the-sandbox
     */

    GSDefaults = [[NSUserDefaults alloc] initWithSuiteName: gAppGroup];

    /* Get the user's preferences */
    
    grayScale = [GSDefaults boolForKey: gPrefGrayScale];
    
    /* Set the actions for the menu items */

    [GSMenuItemToggleGrayScale setAction: @selector(actionToggleGrayScale:)];
    [GSMenuItemToggleNightShift setAction: @selector(actionToggleNightShift:)];
    [GSMenuItemNightShiftSlider setAction:
        @selector(actionNightShiftSliderValueChanged:)];
    [GSMenuItemBrightnessSlider setAction:
        @selector(actionBrightnessSliderValueChanged:)];
    [GSMenuItemToggleDarkMode setAction: @selector(actionToggleDarkMode:)];
    
    /*
        Set the state of (checkmark) of the menu items based on the user's
        preferences:
     
        1. Gray Scale, Night Shift and Dark Mode are based on the current
           user preferences
        2. The Night Shift slider should be enabled only when Night Shift
           is enabled.
        3. The value of the Night Shift and the Brightness sliders should
           be scaled up to between 1 and 100
     */

    [GSMenuItemToggleGrayScale setState: (grayScale ?
                                          NSControlStateValueOn :
                                          NSControlStateValueOff)];
    [GSMenuItemToggleNightShift setState: (nightShift ?
                                           NSControlStateValueOn :
                                           NSControlStateValueOff)];
    [GSMenuItemNightShiftSlider setEnabled: nightShift];
    [GSMenuItemNightShiftSlider setFloatValue: nightShiftStrength*100];
    [GSMenuItemBrightnessSlider setFloatValue: brightness*100];
    [GSMenuItemToggleDarkMode setState: (darkMode ?
                                         NSControlStateValueOn :
                                         NSControlStateValueOff)];
    
    /*
        Set the display mode based on the user's preferences:
        https://apple.stackexchange.com/questions/240446/how-to-enable-disable-grayscale-mode-in-accessibility-via-terminal-app#240449
     */
    
    CGDisplayForceToGray(grayScale);
    
    /*
        Terminate the helper if it is running:
        https://blog.timschroeder.net/2014/01/25/detecting-launch-at-login-revisited/
     */
    
    apps = [[NSWorkspace sharedWorkspace] runningApplications];
    if (apps != nil)
    {
        for (app in apps)
        {
            if ([app.bundleIdentifier isEqualToString: gHelperAppBundle])
            {
                startedAtLogin = TRUE;
                break;
            }
        }
    }
    
    if (startedAtLogin)
    {
        [[NSDistributedNotificationCenter defaultCenter]
         postNotificationName: gMsgTerminate
         object: [[NSBundle mainBundle] bundleIdentifier]];
    }
    
    SMLoginItemSetEnabled((__bridge CFStringRef)gHelperAppBundle,
                          TRUE);
}

- (void)awakeFromNib: (NSNotification *)aNotification
{
    
}

- (void)applicationWillTerminate: (NSNotification *)aNotification
{
    
}

/*
    actionToggleGrayScale - actions to take when the grayscale menu item
                            is clicked
 */

- (void) actionToggleGrayScale: (id)sender
{
    /* Toggle the setting for whether grayscale is enabled */

    grayScale = !grayScale;
    
    /* Update the user's preferences */
    
    [GSDefaults setBool: grayScale forKey: gPrefGrayScale];
    
    /*
        Show a checkmark before this menu item if the display should be
        in grayscale:
        https://stackoverflow.com/questions/2176639/how-to-add-a-check-mark-to-an-nsmenuitem
     */
    
    [GSMenuItemToggleGrayScale setState: (grayScale ?
                                          NSControlStateValueOn :
                                          NSControlStateValueOff)];
    
    /*
        Toggle the display mode:
        https://apple.stackexchange.com/questions/240446/how-to-enable-disable-grayscale-mode-in-accessibility-via-terminal-app#240449
     */
    
    CGDisplayForceToGray(grayScale);
}

/*
    actionToggleDarkMode - actions to take when the darkmode menu item
                           is clicked
 */

- (void) actionToggleDarkMode: (id)sender
{
    /* Toggle the setting for whether dark mode is enabled */
    
    darkMode = !darkMode;
    
    /*
        Show a checkmark before this menu item if the display should be
        in grayscale:
        https://stackoverflow.com/questions/2176639/how-to-add-a-check-mark-to-an-nsmenuitem
     */
    
    [GSMenuItemToggleDarkMode setState: (darkMode ?
                                         NSControlStateValueOn :
                                         NSControlStateValueOff)];
    
    /*
        Toggle darkmode:
        https://github.com/mafredri/macos-darkmode/blob/master/cmd/darkmode/main.go
        https://saagarjha.com/blog/2018/12/01/scheduling-dark-mode/
     */
    
    SLSSetAppearanceThemeNotifying(darkMode, true);
}

/*
    actionToggleNightShift - actions to take when the nightshift menu item
                             is clicked
 */

- (void) actionToggleNightShift: (id)sender
{
    /* Toggle the setting for whether nightsift is enabled */
    
    nightShift = !nightShift;
    
    /*
        Show a checkmark before this menu item if the display should be
        in grayscale:
        https://stackoverflow.com/questions/2176639/how-to-add-a-check-mark-to-an-nsmenuitem
     */
    
    [GSMenuItemToggleNightShift setState: (nightShift ?
                                           NSControlStateValueOn :
                                           NSControlStateValueOff)];

    /* Toogle whether the slider is enabled */
    
    [GSMenuItemNightShiftSlider setEnabled: nightShift];

    [self updateNightShift];
}

/*
    actionNightShiftSliderValueChanged - actions to take when the nightshift slider's
                                         value changes
 */

- (void) actionNightShiftSliderValueChanged: (id)sender
{
    NSEvent *event = nil;
    
    event = [[NSApplication sharedApplication] currentEvent];

    /*
        Update the night shift strength only when the user has finished
        selecting the new value.  See:
    https://stackoverflow.com/questions/9416903/determine-when-nsslider-knob-is-let-go-in-continuous-mode#
     */
    
    switch (event.type)
    {
        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseUp:

            /*
                Get the requested night shift strength and scale it down to
                between 0 and 1
             */
            
            nightShiftStrength = [GSMenuItemNightShiftSlider floatValue] / 100;
            [self updateNightShift];
            
            break;
        default:
            break;
    }
}

/* updateNightShift - update the current night shift strength */

- (void) updateNightShift
{
    /*
        Toggle night shift.  See:
        https://github.com/jenghis/nshift/blob/master/nshift/main.m
     */
    
    if (nightShift && nightShiftStrength != 0.0)
    {
        /* ensure that the max night shift strength is 1.0 (the max) */
        
        if (nightShiftStrength > 1.0)
        {
            nightShiftStrength = 1.0;
        }
        
        [GSBlueLightClient setStrength: nightShiftStrength commit: TRUE];
    }
    
    [GSBlueLightClient setEnabled: nightShift];
    
    /*
        Reset the screen's brightness in a background thread:
    https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/CreatingThreads/CreatingThreads.html#//apple_ref/doc/uid/10000057i-CH15-SW19
     */
    
    [NSThread detachNewThreadSelector: @selector(updateBrightness:)
                             toTarget: self
                           withObject: [NSNumber numberWithFloat: brightness]];
}

/*
    actionBrightnessSliderValueChanged - actions to take when the brightness slider's
                                         value changes
 */

- (void) actionBrightnessSliderValueChanged: (id)sender
{
    NSEvent *event = nil;
    
    event = [[NSApplication sharedApplication] currentEvent];

    /*
        Update the brightness strength only when the user has finished
        selecting the new value.  See:
    https://stackoverflow.com/questions/9416903/determine-when-nsslider-knob-is-let-go-in-continuous-mode#
     */
    
    switch (event.type)
    {
        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseUp:

            /*
                Set the brightness strength to the slider's value scaled
                down to between 0.1 and 1
             */
            
            brightness = [GSMenuItemBrightnessSlider floatValue] / 100;
            if (brightness <= 0.0)
            {
                brightness = 0.1;
            } else if (brightness > 1.0)
            {
                brightness = 1.0;
            }
            
            setMainDisplayBrightness(brightness);
            
            break;
        default:
            break;
    }
}

/*
    updateBrightness - background method to reset the brightness after
                       the night shift setting has been changed
 */

- (void) updateBrightness: (NSNumber *)brightnessStrength
{
    float reqBrightness = 1.0;
    
    if (brightnessStrength != nil)
    {
        reqBrightness = [brightnessStrength floatValue];
    }
    
    /* make sure brightness is between 0.1 and 1 */
    
    if (reqBrightness <= 0.0)
    {
        reqBrightness = 0.1;
    } else if (reqBrightness > 1.0)
    {
        reqBrightness = 1.0;
    }

    /*
        wait for 2 seconds before updating the brightness to give time
        for the night shift setting to be commited
     */
    
    sleep(2);
    setMainDisplayBrightness(reqBrightness);
}

@end
