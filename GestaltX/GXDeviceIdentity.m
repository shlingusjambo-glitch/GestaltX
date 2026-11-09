// SPDX-License-Identifier: GPL-3.0-only
#import "GXDeviceIdentity.h"
#import <dlfcn.h>
#import <TargetConditionals.h>

NSDictionary<NSString *, id> *GXCopySiriCapabilityDiagnostics(void) {
    typedef CFPropertyListRef (*CopyAnswer)(CFStringRef);
    void *library = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY | RTLD_LOCAL);
    CopyAnswer copy = library ? (CopyAnswer)dlsym(library, "MGCopyAnswer") : NULL;
    NSMutableDictionary *answers = [NSMutableDictionary dictionary];
    if (copy) {
        for (NSString *key in @[@"ProductType", @"TargetSubType", @"HardwarePlatform",
                               @"HWModelStr", @"DeviceMemorySize", @"SiriMode",
                               @"generative-model-systems", @"DeviceSupportsGenerativeModelSystems",
                               @"DeviceSupportsInstructionFollowingPruningModels",
                               @"DeviceSupportsAudioIntelligence", @"ProductTypeDescForAudio",
                               @"HWModelDescriptionForAudio", @"HWModelDescriptionForPowerPerf"]) {
            CFPropertyListRef answer = copy((__bridge CFStringRef)key);
            if (answer) {
                id value = CFBridgingRelease(answer);
                if ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSNumber.class]) answers[key] = value;
                else answers[key] = @"non-scalar answer (not exported)";
            } else answers[key] = @"unavailable";
        }
    }
    if (library) dlclose(library);
    return answers;
}

NSDictionary<NSString *, id> *GXCopyCurrentDeviceIdentity(void) {
#if TARGET_OS_SIMULATOR
    return @{};
#else
    typedef CFPropertyListRef (*CopyAnswer)(CFStringRef);
    void *library = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY | RTLD_LOCAL);
    CopyAnswer copy = library ? (CopyAnswer)dlsym(library, "MGCopyAnswer") : NULL;
    NSMutableDictionary *identity = [NSMutableDictionary dictionary];
    if (copy) {
        for (NSString *key in @[@"UniqueDeviceID", @"SerialNumber", @"UniqueChipID"]) {
            CFPropertyListRef answer = copy((__bridge CFStringRef)key);
            if (answer) {
                id value = CFBridgingRelease(answer);
                if ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSNumber.class]) identity[key] = value;
            }
        }
    }
    if (library) dlclose(library);
    return identity;
#endif
}
