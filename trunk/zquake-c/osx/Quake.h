/* Quake */

#import <Cocoa/Cocoa.h>

@interface Quake : NSObject
{
    NSTimer				*mFrameTimer;
    NSDate				*mDistantPast;
}

- (void) installFrameTimer;
- (NSDate *) distantPast;

@end
