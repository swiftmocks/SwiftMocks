// This file was extracted from Quick/Nimble open source project, licensed under Apache License 2.0.
// https://github.com/quick/nimble

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

@interface _NMBExceptionCapture : NSObject

- (nonnull instancetype)initWithHandler:(void(^ _Nullable)(NSException * _Nonnull))handler finally:(void(^ _Nullable)(void))finally;
- (void)tryBlock:(__attribute__((noescape)) void(^ _Nonnull)(void))unsafeBlock NS_SWIFT_NAME(tryBlock(_:));

@end

typedef void(^NMBSourceCallbackBlock)(BOOL successful);
