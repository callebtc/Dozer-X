#import "NativeVisibilityBridge.h"
#import <dlfcn.h>
#import <objc/message.h>

static NSError *VisibilityError(NSString *description) {
    return [NSError errorWithDomain:@"DozerNativeVisibility" code:1
                          userInfo:@{NSLocalizedDescriptionKey: description}];
}

BOOL DozerNativeVisibilityIsAvailable(void) {
    static void *framework;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        framework = dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore",
                           RTLD_NOW | RTLD_LOCAL);
    });
    Class configuration = NSClassFromString(@"MBAssessmentModeConfiguration");
    Class assertion = NSClassFromString(@"MBAssessmentModeAssertion");
    return framework && configuration && assertion
        && [configuration instancesRespondToSelector:NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:")]
        && [configuration instancesRespondToSelector:NSSelectorFromString(@"initWithUnrestrictedMenuBarItems")]
        && [assertion instancesRespondToSelector:NSSelectorFromString(@"activateWithConfiguration:completionHandler:")]
        && [assertion instancesRespondToSelector:@selector(invalidate)];
}

void DozerNativeVisibilityActivate(NSArray<NSString *> *allowedBundles,
                                   void (^completion)(id, NSError *)) {
    void (^finish)(id, NSError *) = ^(id assertion, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(assertion, error); });
    };
    if (!DozerNativeVisibilityIsAvailable()) {
        finish(nil, VisibilityError(@"This version of macOS does not provide the menu bar visibility service."));
        return;
    }
    @try {
        id assertion = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
        if (!assertion) {
            finish(nil, VisibilityError(@"Could not create the menu bar visibility configuration."));
            return;
        }
        DozerNativeVisibilityUpdate(assertion, allowedBundles, ^(NSError *error) {
            if (error) { DozerNativeVisibilityInvalidate(assertion); }
            completion(error ? nil : assertion, error);
        });
    } @catch (NSException *exception) {
        finish(nil, VisibilityError(exception.reason ?: @"The menu bar visibility service failed."));
    }
}

void DozerNativeVisibilityUpdate(id assertion, NSArray<NSString *> *allowedBundles,
                                void (^completion)(NSError *)) {
    void (^finish)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    };
    if (!DozerNativeVisibilityIsAvailable()) {
        finish(VisibilityError(@"This version of macOS does not provide the menu bar visibility service."));
        return;
    }
    @try {
        id configuration;
        if (allowedBundles) {
            NSMutableArray<NSNumber *> *systemItems = [NSMutableArray array];
            for (NSInteger index = 0; index < 64; index++) {
                [systemItems addObject:@(index)];
            }
            configuration = ((id (*)(id, SEL, NSArray *, NSArray *))objc_msgSend)(
                [NSClassFromString(@"MBAssessmentModeConfiguration") alloc],
                NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:"), systemItems, [allowedBundles copy]);
        } else {
            configuration = ((id (*)(id, SEL))objc_msgSend)(
                [NSClassFromString(@"MBAssessmentModeConfiguration") alloc],
                NSSelectorFromString(@"initWithUnrestrictedMenuBarItems"));
        }
        if (!configuration) {
            finish(VisibilityError(@"Could not create the menu bar visibility configuration."));
            return;
        }
        ((void (*)(id, SEL, id, void (^)(NSError *)))objc_msgSend)(
            assertion, NSSelectorFromString(@"activateWithConfiguration:completionHandler:"), configuration, finish);
    } @catch (NSException *exception) {
        finish(VisibilityError(exception.reason ?: @"The menu bar visibility service failed."));
    }
}

void DozerNativeVisibilityInvalidate(id assertion) {
    @try {
        if ([assertion respondsToSelector:@selector(invalidate)]) {
            ((void (*)(id, SEL))objc_msgSend)(assertion, @selector(invalidate));
        }
    } @catch (NSException *exception) {
        NSLog(@"Dozer could not release menu bar visibility: %@", exception.reason);
    }
}
