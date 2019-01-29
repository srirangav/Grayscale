/*
    Grayscale - AppDelegate.m
 
    History:
 
    v. 1.0.0 (01/17/2019) - Initial version
 
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

/* external functions */

CG_EXTERN bool CGDisplayUsesForceToGray(void);
CG_EXTERN void CGDisplayForceToGray(bool forceToGray);

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
    BOOL isDisplayInGrayScale = FALSE;

    /*
        Create the status item and set its icon:
        http://preserve.mactech.com/articles/mactech/Vol.22/22.02/Menulet/index.html
     
        See also:
        http://www.sonsothunder.com/devres/livecode/tutorials/StatusMenu.html
     */
    
    self.statusItem = [[NSStatusBar systemStatusBar]
                       statusItemWithLength: NSVariableStatusItemLength];
    [self.statusItem setHighlightMode: YES];
    [self.statusItem setMenu: GSMenu];
    [self.statusItem setTitle: gMenuTitle];
  
    /*
        Create a preference group to share preferences with the login
        helper app:
        https://stackoverflow.com/questions/14014417/reading-nsuserdefaults-from-helper-app-in-the-sandbox
     */

    GSDefaults = [[NSUserDefaults alloc] initWithSuiteName: gAppGroup];

    /* Get the user's preferences for displaying the date, day, and time */
    
    grayScale = [GSDefaults boolForKey: gPrefGrayScale];
    launchAtLogin = [GSDefaults boolForKey: gPrefLaunchAtLogin];

    /* Set the actions for the menu items */

    [GSMenuItemToggleGrayScale setAction: @selector(actionToggleGrayScale:)];
    [GSMenuItemLaunchAtLogin setAction: @selector(actionLaunchAtLogin:)];

    /*
        Set the state of (checkmark) of the menu items based on the user's
        preferences
     */

    [GSMenuItemToggleGrayScale setState: (grayScale ? NSOnState : NSOffState)];
    [GSMenuItemLaunchAtLogin setState: (launchAtLogin ? NSOnState : NSOffState)];
    
    /* Determine whether the display is currently in grayscale mode */
    
    isDisplayInGrayScale = CGDisplayUsesForceToGray();
    
    /*
        If the user's requested display mode does not match the display's
        current mode, switch the display mode to the user's requested mode.
     
        See:
        https://apple.stackexchange.com/questions/240446/how-to-enable-disable-grayscale-mode-in-accessibility-via-terminal-app#240449
     */
    
    if (grayScale != isDisplayInGrayScale)
    {
        CGDisplayForceToGray(grayScale);
    }
    
    /*
        Terminate the helper if it is running:
        https://blog.timschroeder.net/2014/01/25/detecting-launch-at-login-revisited/
     */
    
    apps = [[NSWorkspace sharedWorkspace] runningApplications];
    if (apps != nil) {
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
    
    [GSMenuItemToggleGrayScale setState: (grayScale ? NSOnState : NSOffState)];
    
    /*
        Toggle the display mode:
        https://apple.stackexchange.com/questions/240446/how-to-enable-disable-grayscale-mode-in-accessibility-via-terminal-app#240449
     */
    
    CGDisplayForceToGray(grayScale);
}

/*
    actionLaunchAtLogin - actions to take when the launch at login menu item
                          is clicked
 */

- (void) actionLaunchAtLogin: (id)sender
{
    /* Toggle the setting for whether we should launch at login */
    
    launchAtLogin = !launchAtLogin;
    
    /* Update the user's preferences */
    
    [GSDefaults setBool: launchAtLogin forKey: gPrefLaunchAtLogin];
    
    /*
        Show a checkmark before this menu item if we should launch at login:
        https://stackoverflow.com/questions/2176639/how-to-add-a-check-mark-to-an-nsmenuitem
     */
    
    [GSMenuItemLaunchAtLogin setState: (launchAtLogin ? NSOnState : NSOffState)];
    
    if (!SMLoginItemSetEnabled ((__bridge CFStringRef)gHelperAppBundle,
                                launchAtLogin))
    {
        NSAlert *alert =
        [NSAlert alertWithMessageText: @"An error ocurred"
                        defaultButton: @"OK"
                      alternateButton: nil
                          otherButton: nil
            informativeTextWithFormat: (launchAtLogin ?
                                        @"Can't add helper to login items." :
                                        @"Can't remove helper from login items." )];
        [alert runModal];
    }
}

@end
