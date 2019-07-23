/*
    CBBlueLightClient.h - partial header for private blue light client framework
 
    Based on:
 
    $ strings /System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/CoreBrightness

    See also:
 
    https://github.com/jenghis/nshift/blob/master/nshift/CBBlueLightClient.h
    https://github.com/elanini/NightShifter/blob/master/CBBlueLightClient.h
*/

#ifndef CBBlueLightClient_h
#define CBBlueLightClient_h

#import <Foundation/Foundation.h>

@interface CBBlueLightClient : NSObject
- (BOOL)setStrength: (float)strength
             commit: (BOOL)commit;
- (BOOL)getStrength: (float *)strength;
- (BOOL)setEnabled: (BOOL)enabled;
@end

#endif /* CBBlueLightClient_h */
