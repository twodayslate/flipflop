#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "CydiaSubstrate.h"
#import "LAListener.h"

@interface SBApplicationController
+(id)sharedInstance;
-(id)applicationWithDisplayIdentifier:(id)arg1 ;
@end

@interface SBUIController
-(void)activateApplicationAnimated:(id)arg1 ;
@end

@interface LAActivator
-(id)hasSeenListenerWithName:(id)arg1;
-(id)assignEvent:(id)arg1 toListenerWithName:(id)arg2;
-(id)registerListener:(id)arg1 forName:(id)arg2;
@end

@interface LAEvent
+(id)eventWithName:(id)arg1; 
-(id)setHandled:(BOOL)arg1;
@end


static id lastApp = nil;

static void SlideToApp(id identifier) {
    //id app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:[identifier displayIdentifier]];
    [[%c(SBUIController) sharedInstance] activateApplicationAnimated:identifier];
}

%hook SBAppToAppWorkspaceTransaction
-(id)_setupAnimationFrom:(id)afrom to:(id)ato {
	if(afrom != NULL) {
		lastApp = afrom;
	}
	return %orig;
}
%end

@interface SlideBackActivator : NSObject <LAListener>
@end

@implementation SlideBackActivator
- (void)activator:(id)activator receiveEvent:(id)event {
	if(lastApp != NULL) {
		SlideToApp(lastApp);
		[event setHandled:YES];
	}
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"flipflop";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Alt+Tab for your iDevice";
}

- (id)activator:(LAActivator *)activator requiresInfoDictionaryValueOfKey:(NSString *)key forListenerWithName:(NSString *)listenerName {
	return [NSNumber numberWithBool:YES]; // HAX so it can send raw events. <3 rpetrich
}

@end

%ctor {
	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);

    static SlideBackActivator *listener = [[SlideBackActivator alloc] init];

    id la = [%c(LAActivator) sharedInstance];
    if ([la respondsToSelector:@selector(hasSeenListenerWithName:)] && [la respondsToSelector:@selector(assignEvent:toListenerWithName:)]) {
        if (![la hasSeenListenerWithName:@"com.twodayslate.flipflop"]) {
            [la assignEvent:[%c(LAEvent) eventWithName:@"libactivator.menu.press.single"] toListenerWithName:@"com.twodayslate.slideback"];
        }
    }

    // register our listener. do this after the above so it still hasn't "seen" us if this is first launch
    [[%c(LAActivator) sharedInstance] registerListener:listener forName:@"com.twodayslate.flipflop"]; // can also be done in +load https://github.com/nickfrey/NowNow/blob/master/Tweak.xm#L31
}
