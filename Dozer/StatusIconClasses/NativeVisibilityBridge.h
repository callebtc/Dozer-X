#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
BOOL DozerNativeVisibilityIsAvailable(void);
void DozerNativeVisibilityActivate(NSArray<NSString *> * _Nullable allowedBundles,
                                   void (^completion)(id _Nullable assertion, NSError * _Nullable error));
void DozerNativeVisibilityUpdate(id assertion, NSArray<NSString *> * _Nullable allowedBundles,
                                void (^completion)(NSError * _Nullable error));
void DozerNativeVisibilityInvalidate(id assertion);
NS_ASSUME_NONNULL_END
